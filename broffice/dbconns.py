import os
import pymysql
import time
import logging
import threading
from contextlib import contextmanager
from dotenv import load_dotenv
from flask import current_app

load_dotenv()

# 환경별 DB 설정 선택
DB_ENV = os.environ.get('DB_ENV', 'remote')  # local, remote, production

def get_db_config():
    """환경에 따른 DB 설정 반환"""
    if DB_ENV == 'remote':
        # 원격 테스트 환경 (SSH 터널 사용)
        # 사전에 SSH 터널을 열어야 함:
        # ssh -L 3307:Broffice.mysql.pythonanywhere-services.com:3306 Broffice@ssh.pythonanywhere.com -N
        return {
            'host': os.environ.get('REMOTE_DB_HOST', '127.0.0.1'),
            'port': int(os.environ.get('REMOTE_DB_PORT', 3307)),
            'user': os.environ.get('REMOTE_DB_USER'),
            'password': os.environ.get('REMOTE_DB_PASSWORD'),
            'database': os.environ.get('REMOTE_DB_NAME'),
            'charset': 'utf8mb4',
            'cursorclass': pymysql.cursors.DictCursor,
            'autocommit': False,
            'auth_plugin_map': {'auth_gssapi_client': 'mysql_native_password'}
        }
    elif DB_ENV == 'production':
        # 프로덕션 환경 (PythonAnywhere 내부)
        return {
            'host': os.environ.get('PROD_DB_HOST'),
            'port': int(os.environ.get('PROD_DB_PORT', 3306)),
            'user': os.environ.get('PROD_DB_USER'),
            'password': os.environ.get('PROD_DB_PASSWORD'),
            'database': os.environ.get('PROD_DB_NAME'),
            'charset': 'utf8mb4',
            'cursorclass': pymysql.cursors.DictCursor,
            'autocommit': False,
            'auth_plugin_map': {'auth_gssapi_client': 'mysql_native_password'}
        }
    else:
        # 로컬 개발 환경 (기본값)
        return {
            'host': os.environ.get('LOCAL_DB_HOST', 'localhost'),
            'port': int(os.environ.get('LOCAL_DB_PORT', 3306)),
            'user': os.environ.get('LOCAL_DB_USER', 'root'),
            'password': os.environ.get('LOCAL_DB_PASSWORD'),
            'database': os.environ.get('LOCAL_DB_NAME', 'broffice'),
            'charset': 'utf8mb4',
            'cursorclass': pymysql.cursors.DictCursor,
            'autocommit': False
        }

# MySQL 연결 설정
db_config = get_db_config()

# 로거 설정
logger = logging.getLogger(__name__)

class ConnectionPool:
    """데이터베이스 연결 풀 클래스"""
    
    def __init__(self, db_config, min_connections=2, max_connections=10):
        self.db_config = db_config
        self.min_connections = min_connections
        self.max_connections = max_connections
        self.pool = []
        self.in_use = {}
        self.lock = threading.RLock()
    
    def initialize_pool(self):
        """초기 연결 풀 생성"""
        with self.lock:
            for _ in range(self.min_connections):
                try:
                    conn = self._create_connection()
                    self.pool.append(conn)
                except Exception as e:
                    logger.error(f"연결 풀 초기화 중 오류: {str(e)}")
    
    def _create_connection(self):
        """새 데이터베이스 연결 생성"""
        try:
            conn = pymysql.connect(**self.db_config)
            
            # 한국시간 타임존 설정
            with conn.cursor() as cursor:
                cursor.execute("SET time_zone = '+09:00'")
                cursor.execute("SET SESSION time_zone = '+09:00'")
            
            return conn
        except Exception as e:
            logger.error(f"데이터베이스 연결 생성 중 오류: {str(e)}")
            raise
    
    def get_connection(self, timeout=5):
        """풀에서 연결 가져오기"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            with self.lock:
                if self.pool:
                    conn = self.pool.pop(0)
                    
                    # 연결 유효성 검사
                    try:
                        conn.ping(reconnect=True)
                    except:
                        # 연결이 끊어진 경우 새 연결 생성
                        try:
                            conn = self._create_connection()
                        except Exception as e:
                            logger.error(f"손상된 연결 재생성 중 오류: {str(e)}")
                            if len(self.pool) + len(self.in_use) < self.min_connections:
                                continue  # 최소 연결 수 유지를 위해 재시도
                            raise
                    
                    # 사용 중인 연결 추적
                    self.in_use[id(conn)] = conn
                    return conn
                
                # 최대 연결 수에 도달하지 않았다면 새 연결 생성
                if len(self.in_use) < self.max_connections:
                    try:
                        conn = self._create_connection()
                        self.in_use[id(conn)] = conn
                        return conn
                    except Exception as e:
                        logger.error(f"새 연결 생성 중 오류: {str(e)}")
                        raise
            
            # 연결을 얻지 못했다면 잠시 대기 후 재시도
            time.sleep(0.1)
        
        # 타임아웃 발생
        raise TimeoutError("데이터베이스 연결을 얻는 데 시간이 초과되었습니다.")
    
    def release_connection(self, conn):
        """연결을 풀로 반환"""
        with self.lock:
            conn_id = id(conn)
            if conn_id in self.in_use:
                del self.in_use[conn_id]
                
                # 연결 유효성 검사
                try:
                    conn.ping(reconnect=False)
                    
                    # 풀 크기가 최소 연결 수보다 작으면 연결 유지
                    if len(self.pool) < self.min_connections:
                        self.pool.append(conn)
                    else:
                        conn.close()
                except:
                    # 연결이 손상된 경우 닫기
                    try:
                        conn.close()
                    except:
                        pass
                    
                    # 최소 연결 수 유지
                    if len(self.pool) + len(self.in_use) < self.min_connections:
                        try:
                            new_conn = self._create_connection()
                            self.pool.append(new_conn)
                        except Exception as e:
                            logger.error(f"연결 풀 재생성 중 오류: {str(e)}")
    
    def close_all(self):
        """모든 연결 닫기"""
        with self.lock:
            # 풀에 있는 연결 닫기
            for conn in self.pool:
                try:
                    conn.close()
                except:
                    pass
            self.pool.clear()
            
            # 사용 중인 연결 닫기
            for conn_id, conn in list(self.in_use.items()):
                try:
                    conn.close()
                except:
                    pass
            self.in_use.clear()

# 전역 연결 풀 생성
connection_pool = ConnectionPool(db_config)

@contextmanager
def get_db_connection():
    """데이터베이스 연결을 안전하게 획득하고 반환하는 컨텍스트 매니저"""
    conn = None
    try:
        conn = connection_pool.get_connection()
        yield conn
    except Exception as e:
        if conn:
            try:
                conn.rollback()
            except:
                pass
        logger.error(f"데이터베이스 연결 사용 중 오류: {str(e)}")
        raise
    finally:
        if conn:
            try:
                connection_pool.release_connection(conn)
            except Exception as e:
                logger.error(f"연결 반환 중 오류: {str(e)}")

def _build_call_statement(proc_name, params):
    """
    MySQL CALL 문 생성
    
    Args:
        proc_name: 프로시저 이름 (예: 'uspGetUser')
        params: 파라미터 리스트
    
    Returns:
        CALL 문 (예: 'CALL uspGetUser(%s, %s)')
    """
    if params:
        param_count = len(params) if isinstance(params, (list, tuple)) else 1
        placeholders = ', '.join(['%s'] * param_count)
        return f"CALL {proc_name}({placeholders})"
    else:
        return f"CALL {proc_name}()"

def execute_without_return(proc_name, params=None):
    """
    저장 프로시저 실행 (반환값 없음)
    
    Args:
        proc_name: 프로시저 이름 (예: 'uspSetUser')
        params: 파라미터 리스트 (예: [user_id, user_name])
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                call_sql = _build_call_statement(proc_name, params)
                cursor.execute(call_sql, params if params else [])
                conn.commit()
    except Exception as e:
        logger.error(f"프로시저 실행 중 오류: {proc_name}, {str(e)}")
        raise

def execute_return(proc_name, params=None):
    """
    저장 프로시저 실행 (단일 결과 반환)
    
    Args:
        proc_name: 프로시저 이름 (예: 'uspGetUser')
        params: 파라미터 리스트 (예: [user_id])
    
    Returns:
        결과 딕셔너리
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                call_sql = _build_call_statement(proc_name, params)
                cursor.execute(call_sql, params if params else [])
                result = cursor.fetchone()
                return result
    except Exception as e:
        logger.error(f"프로시저 실행 중 오류 (단일 결과): {proc_name}, {str(e)}")
        raise

def return_list(proc_name, params=None):
    """
    저장 프로시저 실행 (결과 목록 반환)
    
    Args:
        proc_name: 프로시저 이름 (예: 'uspGetUserList')
        params: 파라미터 리스트 (예: [channel_id])
    
    Returns:
        결과 딕셔너리 리스트
    """
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                call_sql = _build_call_statement(proc_name, params)
                cursor.execute(call_sql, params if params else [])
                result = cursor.fetchall()
                return result if result else []
    except Exception as e:
        logger.error(f"프로시저 실행 중 오류: {proc_name}, {str(e)}")
        raise

# 애플리케이션 종료 시 모든 연결 정리
import atexit
atexit.register(connection_pool.close_all)
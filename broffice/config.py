import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    """기본 설정 클래스"""
    # 필수 환경 변수 검증
    SECRET_KEY = os.environ.get('SECRET_KEY')
    if not SECRET_KEY:
        raise ValueError("환경 변수 'SECRET_KEY'가 설정되지 않았습니다.")
    
    # 애플리케이션 정보
    APP_NAME = 'broffice'
    BRAND_NAME = os.environ.get('BRAND_NAME', '브로피스')
    BASE_URL = os.environ.get('BASE_URL', 'http://localhost:5000')
    
    # 로그 설정
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'INFO')
    
    # 데이터베이스 설정
    DB_HOST = os.environ.get('DB_HOST', 'localhost')
    DB_PORT = int(os.environ.get('DB_PORT', 3306))
    DB_NAME = os.environ.get('DB_NAME', 'Broffice')
    DB_USER = os.environ.get('db_user')
    DB_PASSWORD = os.environ.get('db_password')
    
    # 업로드 관련 설정 (소문자로 통일)
    UPLOAD_EXTENSIONS = [
        'jpg', 'jpeg', 'png', 'gif', 'webp',  # 이미지
        'txt', 'pdf',  # 문서
        'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',  # MS Office
        'mp3', 'mp4', 'avi', 'mov'  # 미디어
    ]
    UPLOAD_IMAGES = ['jpg', 'jpeg', 'png', 'gif', 'webp']
    MAX_CONTENT_LENGTH = 100 * 1024 * 1024  # 100MB

    # Twilio SMS 설정
    TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID', '')
    TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN', '')
    TWILIO_FROM_NUMBER = os.environ.get('TWILIO_FROM_NUMBER', '')
    TWILIO_MESSAGING_SERVICE_SID = os.environ.get('TWILIO_MESSAGING_SERVICE_SID', '')

    # SendGrid 메일 설정
    SENDGRID_API_KEY = os.environ.get('SENDGRID_API_KEY', '')
    MAIL_DEFAULT_SENDER_EMAIL = os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@broffice.kr')
    MAIL_DEFAULT_SENDER_NAME = os.environ.get('MAIL_DEFAULT_SENDER_NAME', BRAND_NAME)

    # 세션 설정
    SESSION_TYPE = 'filesystem'
    SESSION_COOKIE_NAME = 'broffice_session'
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    SESSION_COOKIE_SECURE = False  # 개발 환경 기본값
    PERMANENT_SESSION_LIFETIME = timedelta(hours=24)


class DevelopmentConfig(Config):
    """개발 환경 설정"""
    DEBUG = True
    ENV = 'development'
    LOG_LEVEL = 'DEBUG'
    
    # 업로드 폴더 (OS 독립적)
    UPLOAD_FOLDER = os.environ.get(
        'UPLOAD_FOLDER',
        os.path.join(os.path.expanduser('~'), 'uploads', 'broffice_dev')
    )
    
    # 개발 환경 URL
    BASE_URL = os.environ.get('BASE_URL', 'http://localhost:5000')
    
    # 세션 쿠키 (HTTP 허용)
    SESSION_COOKIE_SECURE = False


class ProductionConfig(Config):
    """프로덕션 환경 설정"""
    DEBUG = False
    ENV = 'production'
    LOG_LEVEL = os.environ.get('LOG_LEVEL', 'WARNING')
    
    # 업로드 폴더
    UPLOAD_FOLDER = os.environ.get(
        'UPLOAD_FOLDER',
        os.path.join(os.path.expanduser('~'), 'uploads', 'broffice')
    )
    
    # 프로덕션 URL
    BASE_URL = os.environ.get('BASE_URL', 'https://broffice.kr')
    
    # 보안 강화
    SESSION_COOKIE_SECURE = True  # HTTPS 전용
    SESSION_COOKIE_SAMESITE = 'Strict'
    
    # 정적 파일 캐싱
    SEND_FILE_MAX_AGE_DEFAULT = 31536000  # 1년


class TestingConfig(Config):
    """테스트 환경 설정"""
    TESTING = True
    DEBUG = True
    ENV = 'testing'
    LOG_LEVEL = 'DEBUG'
    
    # 테스트용 임시 폴더
    UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'test_uploads')
    
    # 테스트 DB (별도 DB 사용 권장)
    DB_NAME = os.environ.get('TEST_DB_NAME', 'Broffice_test')
    
    # 세션 설정
    SESSION_COOKIE_SECURE = False


# 환경에 따른 설정 선택
config = {
    'default': DevelopmentConfig,
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
}


def get_config():
    """
    환경 변수에 따라 적절한 설정 반환
    
    Returns:
        Config: 환경에 맞는 설정 클래스
    """
    env = os.environ.get('FLASK_ENV', 'development')
    selected_config = config.get(env, config['default'])
    
    # 설정 로드 확인
    print(f"환경: {env}, 설정: {selected_config.__name__}")
    
    return selected_config

    
import os
import logging
from logging.handlers import TimedRotatingFileHandler
from flask import Flask


def setup_logger(app: Flask):
    """
    애플리케이션 로거 설정
    - 일 단위(자정 기준) 로그 파일 로테이션
    - 파일 + 콘솔 동시 출력
    - 환경별 로그 레벨 지원
    """
    # 로그 디렉토리 설정
    log_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'logs')
    try:
        os.makedirs(log_dir, exist_ok=True)
    except OSError as e:
        print(f"로그 디렉토리 생성 실패: {e}")
        return app

    # 애플리케이션 이름
    app_name = app.config.get('APP_NAME', 'broffice')
    
    # 로그 레벨 설정 (환경별)
    log_level_str = app.config.get('LOG_LEVEL', 'INFO').upper()
    log_level = getattr(logging, log_level_str, logging.INFO)
    
    # 로그 포맷 설정
    formatter = logging.Formatter(
        '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    
    # 기존 핸들러 제거 (중복 방지)
    app.logger.handlers.clear()
    
    # 1. 파일 핸들러 (일 단위 로테이션)
    try:
        log_file = os.path.join(log_dir, f'{app_name}.log')
        file_handler = TimedRotatingFileHandler(
            log_file,
            when='midnight',
            interval=1,
            backupCount=31,
            encoding='utf-8',
            delay=False
        )
        file_handler.suffix = '%Y%m%d'
        file_handler.setFormatter(formatter)
        file_handler.setLevel(log_level)
        app.logger.addHandler(file_handler)
    except Exception as e:
        print(f"파일 핸들러 설정 실패: {e}")
    
    # 2. 콘솔 핸들러 (개발 환경용)
    if app.config.get('DEBUG', False) or app.config.get('ENV') == 'development':
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        console_handler.setLevel(log_level)
        app.logger.addHandler(console_handler)
    
    # 로거 레벨 설정
    app.logger.setLevel(log_level)
    
    # 로거 설정 완료 로그
    app.logger.info(f"로거 초기화 완료 - 레벨: {log_level_str}, 파일: {log_file}")
    
    return app
import os
from flask import Flask, url_for, render_template
from werkzeug.exceptions import HTTPException
from broffice.utils.file_handler import file_download
from broffice.utils.log_handler import setup_logger
from broffice.config import get_config


def create_app(config_class=None):
    """
    애플리케이션 팩토리 함수
    
    Args:
        config_class: 설정 클래스 (None이면 환경에 맞는 설정 자동 선택)
    
    Returns:
        Flask: 설정된 Flask 애플리케이션 인스턴스
    """
    app = Flask(__name__)
    
    # 설정 로드
    if config_class is None:
        config_class = get_config()
    app.config.from_object(config_class)
    
    # 로거 설정
    setup_logger(app)
    
    # Flask 확장 초기화
    init_extensions(app)
    
    # 컨텍스트 프로세서 등록
    register_context_processors(app)
    
    # 필터 등록
    register_filters(app)
    
    # 블루프린트 등록
    register_blueprints(app)
    
    # 에러 핸들러 등록
    register_error_handlers(app)
    
    # 추가 URL 규칙
    app.add_url_rule('/file_download', 'file_download', file_download, methods=['GET'])
    
    app.logger.info("애플리케이션 초기화 완료")
    
    return app


def init_extensions(app):
    """Flask 확장 초기화"""
    # SendGrid 설정 확인
    if app.config.get('SENDGRID_API_KEY'):
        app.logger.info("SendGrid API 키 설정 확인 완료")
    else:
        app.logger.warning("SendGrid API 키가 설정되지 않았습니다. (.env에 SENDGRID_API_KEY 설정 필요)")


def register_context_processors(app):
    """컨텍스트 프로세서 등록"""
    from datetime import datetime
    
    @app.context_processor
    def inject_now():
        """현재 시간을 템플릿에서 사용할 수 있도록 제공"""
        return dict(now=datetime.now)
    
    @app.context_processor
    def override_url_for():
        """정적 파일 캐시 버스팅을 위한 url_for 오버라이드"""
        return dict(url_for=dated_url_for)
    
    def dated_url_for(endpoint, **values):
        """파일 수정 시간을 쿼리 파라미터로 추가하여 캐시 무효화"""
        if endpoint == 'static':
            filename = values.get('filename')
            if filename:
                try:
                    file_path = os.path.join(app.root_path, endpoint, filename)
                    if os.path.exists(file_path):
                        values['q'] = int(os.stat(file_path).st_mtime)
                except (OSError, ValueError) as e:
                    # 파일 접근 실패 시 로깅만 하고 계속 진행
                    app.logger.debug(f"정적 파일 캐시 버스팅 실패: {filename} - {e}")
        return url_for(endpoint, **values)


def register_filters(app):
    """Jinja2 필터 등록"""
    with app.app_context():
        try:
            import broffice.filters
            broffice.filters.init_app(app)
            app.logger.info("필터 등록 완료")
        except Exception as e:
            app.logger.error(f"필터 등록 실패: {e}")


def register_error_handlers(app):
    """에러 핸들러 등록"""
    
    @app.errorhandler(404)
    def not_found_error(error):
        """404 에러 핸들러"""
        from flask import request as req
        if '.well-known' in req.path:
            return '', 404
        app.logger.warning(f"404 에러: {req.url} - {error}")
        if app.config.get('DEBUG'):
            return str(error), 404
        return render_template('errors/404.html'), 404
    
    @app.errorhandler(403)
    def forbidden_error(error):
        """403 에러 핸들러"""
        app.logger.warning(f"403 에러: {error}")
        if app.config.get('DEBUG'):
            return str(error), 403
        return render_template('errors/403.html'), 403
    
    @app.errorhandler(500)
    def internal_error(error):
        """500 에러 핸들러"""
        app.logger.error("500 에러 발생", exc_info=True)
        if app.config.get('DEBUG'):
            return str(error), 500
        return render_template('errors/500.html'), 500
    
    @app.errorhandler(Exception)
    def handle_exception(e):
        """전역 예외 핸들러"""
        # HTTP 예외는 해당 핸들러로 전달
        if isinstance(e, HTTPException):
            return e
        
        # 예외 로깅 (exc_info=True로 스택 트레이스 자동 포함)
        app.logger.error(
            f"처리되지 않은 예외: {type(e).__name__} - {str(e)}",
            exc_info=True
        )
        
        # 개발 환경에서는 상세 에러 표시
        if app.config.get('DEBUG'):
            raise e
        
        # 프로덕션 환경에서는 일반 에러 페이지
        return render_template('errors/500.html'), 500

def register_blueprints(app):
    """모든 블루프린트를 앱에 등록"""
    from broffice.router import homes, accounts, samples, tasks, reports
    
    # 각 모듈의 블루프린트 등록
    app.register_blueprint(homes.bp)
    app.register_blueprint(accounts.bp, url_prefix='/accounts')
    app.register_blueprint(samples.bp, url_prefix='/samples')
    app.register_blueprint(tasks.bp, url_prefix='/tasks')
    app.register_blueprint(reports.bp, url_prefix='/reports')

import re
from flask import render_template, current_app
from flask_mail import Message

# 메일 객체는 앱 초기화 시 생성되므로 여기서는 가져오기만 함
def _get_mail():
    """Flask-Mail 확장 객체 가져오기"""
    return current_app.extensions.get('mail')


def _validate_email(email):
    """이메일 주소 형식 검증"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def send_mail(user_mail, member_name, auth_code, format_type):
    """
    인증 메일 발송
    
    Args:
        user_mail: 수신자 이메일
        member_name: 사용자 이름
        auth_code: 인증 코드
        format_type: 메일 타입 (register, re_auth, update_email, reset_passwd)
    
    Returns:
        bool: 발송 성공 여부
    """
    # 입력 검증
    if not _validate_email(user_mail):
        current_app.logger.error(f"잘못된 이메일 형식: {user_mail}")
        return False
    
    # 지원하는 format_type 확인
    valid_types = ['register', 're_auth', 'update_email', 'reset_passwd']
    if format_type not in valid_types:
        current_app.logger.error(f"지원하지 않는 메일 타입: {format_type}")
        return False
    
    try:
        mail = _get_mail()
        if not mail:
            current_app.logger.error("Flask-Mail이 초기화되지 않았습니다.")
            return False
        
        # config에서 URL 가져오기
        brand_name = current_app.config.get('BRAND_NAME', '브로피스')
        base_url = current_app.config.get('BASE_URL', 'https://broffice.kr')
        
        # 인증 URL 생성
        if format_type == 'reset_passwd':
            auth_url = f"{base_url}/accounts/auth_pass_update?user_email={user_mail}&auth_code={auth_code}"
        else:
            auth_url = f"{base_url}/accounts/auth?user_email={user_mail}&auth_code={auth_code}"
        
        # 제목 설정
        subject_mapping = {
            'register': f"{brand_name} 가입을 환영합니다.",
            're_auth': f"{brand_name} 이메일 재인증 안내입니다.",
            'update_email': f"{brand_name} 이메일 계정 변경 안내입니다.",
            'reset_passwd': f"{brand_name} 비밀번호 초기화 안내입니다."
        }
        
        # 메시지 생성
        msg = Message(
            subject=subject_mapping[format_type],
            recipients=[user_mail],
            charset='utf-8'
        )
        
        # HTML 콘텐츠 렌더링
        msg.html = render_template(
            'emails/auth_format.html',
            format_type=format_type,
            member_name=member_name,
            auth_url=auth_url
        )
        
        # 메일 발송
        mail.send(msg)
        current_app.logger.info(f"메일 발송 성공: {user_mail} (타입: {format_type})")
        return True
        
    except Exception as e:
        current_app.logger.error(f"메일 발송 실패: {user_mail} - {str(e)}", exc_info=True)
        return False


def send_report_mail(recipient_email, subject, html_content):
    """
    리포트 메일 발송
    
    Args:
        recipient_email: 수신자 이메일
        subject: 메일 제목
        html_content: HTML 콘텐츠
    
    Returns:
        bool: 발송 성공 여부
    """
    # 입력 검증
    if not _validate_email(recipient_email):
        current_app.logger.error(f"잘못된 이메일 형식: {recipient_email}")
        return False
    
    if not subject or not html_content:
        current_app.logger.error("제목 또는 내용이 비어있습니다.")
        return False
    
    try:
        mail = _get_mail()
        if not mail:
            current_app.logger.error("Flask-Mail이 초기화되지 않았습니다.")
            return False
        
        msg = Message(
            subject=subject,
            recipients=[recipient_email],
            html=html_content,
            charset='utf-8'
        )
        
        mail.send(msg)
        current_app.logger.info(f"리포트 메일 발송 성공: {recipient_email}")
        return True
        
    except Exception as e:
        current_app.logger.error(f"리포트 메일 발송 실패: {recipient_email} - {str(e)}", exc_info=True)
        return False


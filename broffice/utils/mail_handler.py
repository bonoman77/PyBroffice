"""
SendGrid 기반 이메일 발송 핸들러
"""
import re
import logging
from flask import render_template, current_app

logger = logging.getLogger(__name__)


def _validate_email(email):
    """이메일 주소 형식 검증"""
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def _send_via_sendgrid(to_email, subject, html_content, from_email=None, from_name=None):
    """
    SendGrid API를 통한 이메일 발송

    Returns:
        dict: {'success': bool, 'status_code': int, 'message': str}
    """
    api_key = current_app.config.get('SENDGRID_API_KEY', '')
    if not api_key:
        return {'success': False, 'status_code': 0, 'message': 'SENDGRID_API_KEY 미설정'}

    if not from_email:
        from_email = current_app.config.get('MAIL_DEFAULT_SENDER_EMAIL', 'noreply@broffice.kr')
    if not from_name:
        from_name = current_app.config.get('MAIL_DEFAULT_SENDER_NAME', '브로피스')

    try:
        from sendgrid import SendGridAPIClient
        from sendgrid.helpers.mail import Mail, Email, To, Content

        message = Mail(
            from_email=Email(from_email, from_name),
            to_emails=To(to_email),
            subject=subject,
            html_content=Content('text/html', html_content)
        )

        sg = SendGridAPIClient(api_key)
        response = sg.send(message)

        if response.status_code in (200, 201, 202):
            logger.info(f"메일 발송 성공: {to_email} (status={response.status_code})")
            return {'success': True, 'status_code': response.status_code, 'message': '발송 성공'}
        else:
            logger.warning(f"메일 발송 응답 이상: {to_email} (status={response.status_code})")
            return {'success': False, 'status_code': response.status_code, 'message': f'응답 코드: {response.status_code}'}

    except ImportError:
        logger.error("sendgrid 패키지가 설치되지 않았습니다. pip install sendgrid")
        return {'success': False, 'status_code': 0, 'message': 'sendgrid 패키지 미설치'}
    except Exception as e:
        logger.error(f"메일 발송 실패: {to_email} - {e}", exc_info=True)
        return {'success': False, 'status_code': 0, 'message': str(e)[:200]}


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
    if not _validate_email(user_mail):
        current_app.logger.error(f"잘못된 이메일 형식: {user_mail}")
        return False

    valid_types = ['register', 're_auth', 'update_email', 'reset_passwd']
    if format_type not in valid_types:
        current_app.logger.error(f"지원하지 않는 메일 타입: {format_type}")
        return False

    try:
        brand_name = current_app.config.get('BRAND_NAME', '브로피스')
        base_url = current_app.config.get('BASE_URL', 'https://broffice.kr')

        if format_type == 'reset_passwd':
            auth_url = f"{base_url}/accounts/auth_pass_update?user_email={user_mail}&auth_code={auth_code}"
        else:
            auth_url = f"{base_url}/accounts/auth?user_email={user_mail}&auth_code={auth_code}"

        subject_mapping = {
            'register': f"{brand_name} 가입을 환영합니다.",
            're_auth': f"{brand_name} 이메일 재인증 안내입니다.",
            'update_email': f"{brand_name} 이메일 계정 변경 안내입니다.",
            'reset_passwd': f"{brand_name} 비밀번호 초기화 안내입니다."
        }

        html_content = render_template(
            'emails/auth_format.html',
            format_type=format_type,
            member_name=member_name,
            auth_url=auth_url
        )

        result = _send_via_sendgrid(user_mail, subject_mapping[format_type], html_content)
        return result['success']

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
    if not _validate_email(recipient_email):
        current_app.logger.error(f"잘못된 이메일 형식: {recipient_email}")
        return False

    if not subject or not html_content:
        current_app.logger.error("제목 또는 내용이 비어있습니다.")
        return False

    try:
        result = _send_via_sendgrid(recipient_email, subject, html_content)
        return result['success']
    except Exception as e:
        current_app.logger.error(f"리포트 메일 발송 실패: {recipient_email} - {str(e)}", exc_info=True)
        return False


def send_test_mail(to_email, subject='[브로피스] 이메일 발송 테스트', content='테스트 이메일입니다.'):
    """테스트용 이메일 발송"""
    html = f'<div style="font-family:sans-serif;padding:20px;"><h2>{subject}</h2><p>{content}</p></div>'
    return _send_via_sendgrid(to_email, subject, html)


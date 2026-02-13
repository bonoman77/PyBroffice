"""
Twilio SMS 발송 핸들러
- 업무 완료 시 관리팀장/업체담당자에게 SMS 예약 발송
- 예약 시간: 보고 시점 이후 다음 오전 8시
"""
import os
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

# Twilio 설정 (환경변수에서 로드)
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID', '')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN', '')
TWILIO_FROM_NUMBER = os.environ.get('TWILIO_FROM_NUMBER', '')


def get_next_8am():
    """보고 시점 이후 다음 오전 8시 계산"""
    now = datetime.now()
    next_8am = now.replace(hour=8, minute=0, second=0, microsecond=0)
    if now.hour >= 8:
        next_8am += timedelta(days=1)
    return next_8am


def build_sms_content(recipient):
    """SMS 메시지 내용 생성"""
    kind_name = recipient.get('task_kind_name', '')
    client_name = recipient.get('client_name', '')
    work_date = recipient.get('work_date', '')
    worker_name = recipient.get('worker_name', '')
    
    content = (
        f"[브로피스] {kind_name} 작업 완료 알림\n"
        f"업체: {client_name}\n"
        f"작업일: {work_date}\n"
        f"담당자: {worker_name}\n"
        f"작업이 완료되었습니다."
    )
    return content


def send_sms_twilio(to_mobile, content, scheduled_send_at=None):
    """
    Twilio를 통한 SMS 발송
    - scheduled_send_at이 있으면 예약 발송 (Twilio Message Scheduling)
    - 없으면 즉시 발송
    
    Returns:
        dict: {'success': bool, 'sid': str, 'status': str, 'error_code': str, 'error_message': str}
    """
    if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN or not TWILIO_FROM_NUMBER:
        logger.warning("Twilio 설정이 없습니다. SMS 발송을 건너뜁니다.")
        return {
            'success': False,
            'sid': '',
            'status': 'config_missing',
            'error_code': 'NO_CONFIG',
            'error_message': 'Twilio 환경변수 미설정'
        }
    
    try:
        from twilio.rest import Client
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        
        params = {
            'body': content,
            'from_': TWILIO_FROM_NUMBER,
            'to': to_mobile,
        }
        
        # Twilio 예약 발송 (MessagingService 필요)
        if scheduled_send_at:
            messaging_service_sid = os.environ.get('TWILIO_MESSAGING_SERVICE_SID', '')
            if messaging_service_sid:
                params['messaging_service_sid'] = messaging_service_sid
                params['send_at'] = scheduled_send_at.strftime('%Y-%m-%dT%H:%M:%SZ')
                params['schedule_type'] = 'fixed'
                del params['from_']
        
        message = client.messages.create(**params)
        
        return {
            'success': True,
            'sid': message.sid,
            'status': message.status,
            'error_code': '',
            'error_message': ''
        }
    except ImportError:
        logger.error("twilio 패키지가 설치되지 않았습니다. pip install twilio")
        return {
            'success': False,
            'sid': '',
            'status': 'no_package',
            'error_code': 'NO_PACKAGE',
            'error_message': 'twilio 패키지 미설치'
        }
    except Exception as e:
        logger.error(f"SMS 발송 실패: {e}")
        return {
            'success': False,
            'sid': '',
            'status': 'error',
            'error_code': str(getattr(e, 'code', '')),
            'error_message': str(e)[:100]
        }


def schedule_completion_sms(task_schedule_id, db_conn):
    """
    업무 완료 시 SMS 예약 발송 처리
    1. 수신자 목록 조회 (관리팀장 + 업체담당자)
    2. 다음 오전 8시로 예약 시간 계산
    3. task_sns_logs에 저장
    4. Twilio로 예약 발송 (설정이 있는 경우)
    """
    recipients = db_conn.return_list('get_sns_recipients', [task_schedule_id]) or []
    
    if not recipients:
        logger.info(f"SMS 수신자 없음: task_schedule_id={task_schedule_id}")
        return []
    
    scheduled_at = get_next_8am()
    from_mobile = TWILIO_FROM_NUMBER or 'system'
    results = []
    
    for r in recipients:
        to_mobile = r.get('user_mobile', '')
        if not to_mobile:
            continue
        
        content = build_sms_content(r)
        user_id = r.get('user_id', 0)
        
        # Twilio 발송 시도
        sms_result = send_sms_twilio(to_mobile, content, scheduled_at)
        
        send_status = 'scheduled' if sms_result['success'] else 'pending'
        
        # DB 로그 저장
        log_result = db_conn.execute_return('insert_task_sns_log', [
            user_id,
            task_schedule_id,
            from_mobile,
            to_mobile,
            content,
            scheduled_at.strftime('%Y-%m-%d %H:%M:%S'),
            send_status,
            sms_result.get('sid', ''),
            sms_result.get('status', '')
        ])
        
        results.append({
            'to_mobile': to_mobile,
            'send_status': send_status,
            'log_id': log_result.get('task_sns_log_id') if log_result else None
        })
    
    logger.info(f"SMS 예약 완료: task_schedule_id={task_schedule_id}, 건수={len(results)}")
    return results


def send_test_sms(to_mobile, content='[브로피스] 문자 발송 테스트입니다.'):
    """테스트용 즉시 발송"""
    return send_sms_twilio(to_mobile, content)

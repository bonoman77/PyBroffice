import broffice.dbconns as conn
from datetime import datetime
from broffice.utils.auth_handler import login_required, admin_required
from broffice.utils.sms_handler import send_test_sms
from broffice.utils.mail_handler import send_test_mail
from flask import Blueprint, request, session, render_template, redirect, url_for, flash, jsonify

bp = Blueprint('homes', __name__)

@bp.route("/", methods=['GET'])
@bp.route("/<int:user_kind_id>", methods=['GET'])
@login_required
def index(user_kind_id=None):
    if user_kind_id is None:
        user_kind_id = session.get('login_user', {}).get('user_kind_id')
    
    # 사용자 유형별 대시보드 템플릿 분기
    if user_kind_id == 1:
        # 관리자용 대시보드
        kpi = conn.execute_return('get_dashboard_kpi', []) or {}
        year_month = datetime.now().strftime('%Y-%m')
        schedule_count = conn.execute_return('get_dashboard_schedule_count', [year_month]) or {}
        client_requests = conn.return_list('get_client_request_recent', [0, 10]) or []
        today_cleaning = conn.return_list('get_dashboard_admin_today', [4]) or []
        today_snack = conn.return_list('get_dashboard_admin_today', [5]) or []
        today_supplies = conn.return_list('get_dashboard_admin_today', [6]) or []
        return render_template('homes/index.html',
            kpi=kpi,
            schedule_count=schedule_count,
            client_requests=client_requests,
            year_month=year_month,
            today_cleaning=today_cleaning,
            today_snack=today_snack,
            today_supplies=today_supplies
        )
    elif user_kind_id == 2:
        # 직원용 대시보드
        user_id = session.get('login_user', {}).get('user_id')
        today = datetime.now().strftime('%Y-%m-%d')
        year_month = datetime.now().strftime('%Y-%m')
        
        notices = conn.return_list('get_notice_list_by_target', [2, 3]) or []
        today_tasks = conn.return_list('get_dashboard_staff_today', [user_id]) or []
        schedule_progress = conn.return_list('get_staff_schedule_progress', [user_id, year_month]) or []
        
        return render_template('homes/index_staff.html',
            notices=notices,
            today_tasks=today_tasks,
            schedule_progress=schedule_progress,
            year_month=year_month
        )
    elif user_kind_id == 3:
        # 업체담당자용 대시보드
        client_id = session.get('login_user', {}).get('client_id')
        client_info = conn.execute_return('get_client_detail', [client_id]) if client_id else {}
        notices = conn.return_list('get_notice_list_by_target', [3, 5]) or []
        task_reports = conn.return_list('get_task_client_recent', [client_id, 5]) if client_id else []
        today_results = conn.return_list('get_dashboard_client_today', [client_id]) if client_id else []
        return render_template('homes/index_client.html',
            client_info=client_info,
            notices=notices,
            task_reports=task_reports or [],
            today_results=today_results
        )
    else:
        # 기본 대시보드 (예외 처리)
        return render_template('homes/index.html')


@bp.route("/privacy")
def privacy():
    return render_template('homes/privacy.html')


@bp.route("/terms")
def terms():
    return render_template('homes/terms.html')


@bp.route("/about")
def about():
    return render_template('homes/about.html')


# 개발타임라인 (관리자용)
@bp.route("/timeline")
@admin_required
def timeline():
    return render_template('homes/timeline.html')


@bp.route("/notice_list", methods=['GET', 'POST'])
@login_required
def notice_list():
    user_kind_id = session.get('login_user', {}).get('user_kind_id', 0)
    user_id = session.get('login_user', {}).get('user_id', 0)
    
    if request.method == 'POST':
        target_user_kind_id = request.form.get('target_user_kind_id', '0')
        title = request.form.get('title', '')
        content = request.form.get('content', '')
        top_expose_yn = 1 if request.form.get('top_expose_yn') else 0
        display_yn = 1 if request.form.get('display_yn') else 0
        
        if not title:
            flash('제목을 입력해주세요.', category='danger')
            return redirect(url_for('homes.notice_list'))
        
        try:
            result = conn.execute_return('set_notice_insert', [
                user_id, int(target_user_kind_id), title, content, top_expose_yn, display_yn
            ])
            if result:
                flash('등록되었습니다.', category='success')
            else:
                flash('등록에 실패했습니다.', category='danger')
        except Exception as e:
            flash(f'등록 중 오류가 발생했습니다: {str(e)}', category='danger')
        
        return redirect(url_for('homes.notice_list'))
    
    # GET 요청 처리
    page = request.args.get('page', 1, type=int)
    page_size = 15
    
    count_result = conn.execute_return('get_notice_list_count', [user_kind_id, 1, 0])
    total_count = count_result.get('total_count', 0) if count_result else 0
    total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 1
    if page < 1: page = 1
    if page > total_pages: page = total_pages
    
    res_list = conn.return_list('get_notice_list', [user_kind_id, 1, 0, page, page_size])
    
    return render_template('homes/notice_list.html',
        res_list=res_list,
        page=page,
        total_pages=total_pages,
        total_count=total_count
    )


@bp.route("/client_request_list", methods=['GET', 'POST'])
@login_required
def client_request_list():
    user_kind_id = session.get('login_user', {}).get('user_kind_id', 0)
    user_id = session.get('login_user', {}).get('user_id', 0)

    # 직원은 접근하는 페이지가 아님 
    if user_kind_id == 2:
        return redirect(url_for('homes.index'))

    if request.method == 'POST':
        title = request.form.get('title', '')
        content = request.form.get('content', '')
        
        if not title:
            flash('제목을 입력해주세요.', category='danger')
            return redirect(url_for('homes.client_request_list'))
        
        try:
            result = conn.execute_return('set_client_request_insert', [user_id, title, content])
            if result:
                flash('등록되었습니다.', category='success')
            else:
                flash('등록에 실패했습니다.', category='danger')
        except Exception as e:
            flash(f'등록 중 오류가 발생했습니다: {str(e)}', category='danger')
        
        return redirect(url_for('homes.client_request_list'))
    
    # GET 요청 처리
    page = request.args.get('page', 1, type=int)
    page_size = 15
    
    # 업체 담당자는 본인 글만, 관리자는 전체
    filter_user_id = user_id if user_kind_id == 3 else 0
    
    count_result = conn.execute_return('get_client_request_list_count', [user_kind_id, filter_user_id])
    total_count = count_result.get('total_count', 0) if count_result else 0
    total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 1
    if page < 1: page = 1
    if page > total_pages: page = total_pages
    
    res_list = conn.return_list('get_client_request_list', [user_kind_id, filter_user_id, page, page_size])
    
    return render_template('homes/client_request_list.html',
        res_list=res_list,
        page=page,
        total_pages=total_pages,
        total_count=total_count
    )


@bp.route("/get_notice_content", methods=['GET'])
@login_required
def get_notice_content():
    notice_id = request.args.get('notice_id', type=int)
    if not notice_id:
        return jsonify({'success': False, 'message': 'notice_id is required'}), 400
    
    notice = conn.execute_return('get_notice_content', [notice_id])
    if notice:
        return jsonify({'success': True, 'data': notice})
    return jsonify({'success': False, 'message': '공지사항을 찾을 수 없습니다.'})


@bp.route("/notice_update", methods=['POST'])
@admin_required
def notice_update():
    notice_id = request.form.get('noticeId', type=int)
    target_user_kind_id = request.form.get('target_user_kind_id', 0, type=int)
    title = request.form.get('title', '')
    content = request.form.get('content', '')
    top_expose_yn = 1 if request.form.get('top_expose_yn') else 0
    display_yn = 1 if request.form.get('display_yn') else 0
    
    if not notice_id or not title:
        return jsonify({'success': False, 'message': '필수값이 누락되었습니다.'})
    
    result = conn.execute_return('set_notice_update', [notice_id, target_user_kind_id, title, content, top_expose_yn, display_yn])
    return jsonify({'success': True, 'message': '수정되었습니다.'})


@bp.route("/notice_delete", methods=['POST'])
@admin_required
def notice_delete():
    notice_id = request.form.get('noticeId', type=int)
    if not notice_id:
        return jsonify({'success': False, 'message': 'notice_id is required'})
    
    result = conn.execute_return('set_notice_delete', [notice_id])
    return jsonify({'success': True, 'message': '삭제되었습니다.'})


@bp.route("/get_client_request_content", methods=['GET'])
@login_required
def get_client_request_content():
    request_id = request.args.get('request_id', type=int)
    if not request_id:
        return jsonify({'success': False, 'message': 'request_id is required'}), 400
    
    data = conn.execute_return('get_client_request_content', [request_id])
    if data:
        return jsonify({'success': True, 'data': data})
    return jsonify({'success': False, 'message': '요청사항을 찾을 수 없습니다.'})


@bp.route("/client_request_update", methods=['POST'])
@login_required
def client_request_update():
    request_id = request.form.get('requestId', type=int)
    title = request.form.get('title', '')
    content = request.form.get('content', '')
    
    if not request_id or not title:
        return jsonify({'success': False, 'message': '필수값이 누락되었습니다.'})
    
    result = conn.execute_return('set_client_request_update', [request_id, title, content])
    return jsonify({'success': True, 'message': '수정되었습니다.'})


@bp.route("/client_request_delete", methods=['POST'])
@login_required
def client_request_delete():
    request_id = request.form.get('requestId', type=int)
    if not request_id:
        return jsonify({'success': False, 'message': 'request_id is required'})
    
    result = conn.execute_return('set_client_request_delete', [request_id])
    return jsonify({'success': True, 'message': '삭제되었습니다.'})


@bp.route("/client_request_check", methods=['POST'])
@login_required
def client_request_check():
    request_id = request.form.get('requestId', type=int)
    if not request_id:
        return jsonify({'success': False, 'message': 'request_id is required'})
    
    result = conn.execute_return('set_client_request_check', [request_id])
    return jsonify({'success': True, 'message': '확인 처리되었습니다.'})


@bp.route("/manual")
@admin_required
def manual():
    """사이트 매뉴얼 (user_id=1 전용)"""
    if session.get('login_user', {}).get('user_id') != 1:
        return redirect(url_for('homes.index'))
    return render_template('homes/manual.html')


@bp.route("/test_camera")
@admin_required
def test_camera():
    """사진찍기 테스트 페이지"""
    return render_template('homes/test_camera.html')


@bp.route("/test_sms")
@admin_required
def test_sms():
    """문자발송 테스트 페이지 (user_id=1 전용)"""
    if session.get('login_user', {}).get('user_id') != 1:
        return redirect(url_for('homes.index'))
    import os
    twilio_config = {
        'TWILIO_ACCOUNT_SID': bool(os.environ.get('TWILIO_ACCOUNT_SID', '')),
        'TWILIO_AUTH_TOKEN': bool(os.environ.get('TWILIO_AUTH_TOKEN', '')),
        'TWILIO_FROM_NUMBER': os.environ.get('TWILIO_FROM_NUMBER', ''),
    }
    return render_template('homes/test_sms.html', config=twilio_config)


@bp.route("/test_sms_send", methods=['POST'])
@admin_required
def test_sms_send():
    """문자발송 테스트 실행 (user_id=1 전용)"""
    if session.get('login_user', {}).get('user_id') != 1:
        return jsonify({'success': False, 'message': '권한이 없습니다.'})
    to_mobile = request.form.get('to_mobile', '')
    content = request.form.get('content', '[브로피스] 문자 발송 테스트입니다.')
    
    if not to_mobile:
        return jsonify({'success': False, 'message': '수신번호를 입력해주세요.'})
    
    result = send_test_sms(to_mobile, content)
    
    if result['success']:
        return jsonify({'success': True, 'message': f'발송 성공 (SID: {result["sid"]})', 'data': result})
    else:
        return jsonify({'success': False, 'message': f'발송 실패: {result["error_message"]}', 'data': result})


@bp.route("/test_email")
@admin_required
def test_email():
    """이메일 발송 테스트 페이지 (user_id=1 전용)"""
    if session.get('login_user', {}).get('user_id') != 1:
        return redirect(url_for('homes.index'))
    import os
    sendgrid_config = {
        'SENDGRID_API_KEY': bool(os.environ.get('SENDGRID_API_KEY', '')),
        'MAIL_DEFAULT_SENDER_EMAIL': os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@broffice.kr'),
        'MAIL_DEFAULT_SENDER_NAME': os.environ.get('MAIL_DEFAULT_SENDER_NAME', '브로피스'),
    }
    return render_template('homes/test_email.html', config=sendgrid_config)


@bp.route("/test_email_send", methods=['POST'])
@admin_required
def test_email_send():
    """이메일 발송 테스트 실행 (user_id=1 전용)"""
    if session.get('login_user', {}).get('user_id') != 1:
        return jsonify({'success': False, 'message': '권한이 없습니다.'})
    to_email = request.form.get('to_email', '')
    subject = request.form.get('subject', '[브로피스] 이메일 발송 테스트')
    content = request.form.get('content', '테스트 이메일입니다.')

    if not to_email:
        return jsonify({'success': False, 'message': '수신 이메일을 입력해주세요.'})

    result = send_test_mail(to_email, subject, content)

    if result['success']:
        return jsonify({'success': True, 'message': f'발송 성공 (status: {result["status_code"]})', 'data': result})
    else:
        return jsonify({'success': False, 'message': f'발송 실패: {result["message"]}', 'data': result})




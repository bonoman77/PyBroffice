from flask import request, session, redirect, url_for, jsonify
from functools import wraps
import broffice.dbconns as conn

LOGIN_ENDPOINT = 'accounts.login'
FAILED_ENDPOINT = 'homes.message'
ADMIN_CHECK_PROC = 'uspGetChannelAdminYn'


def login_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if not session.get('login_user'):
            # API 요청인 경우 JSON 응답
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '로그인이 필요합니다.'}), 401
            
            session['next'] = request.url
            return redirect(url_for(LOGIN_ENDPOINT))

        return func(*args, **kwargs)
    return decorated_function


def admin_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        # 로그인 체크 (login_required 로직 재사용)
        login_user = session.get('login_user')
        if not login_user:
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '로그인이 필요합니다.'}), 401
            
            session['next'] = request.url
            return redirect(url_for(LOGIN_ENDPOINT))

        # 관리자 권한 체크
        user_id = login_user['user_id']
        if not is_admin(user_id):
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '관리자 권한이 필요합니다.'}), 403
            
            return redirect(url_for(FAILED_ENDPOINT, msg_kind="route_error"))

        return func(*args, **kwargs)

    return decorated_function


def is_admin(user_id):
    # 세션에서 user_kind_id로 관리자 체크 (1 = 관리자)
    login_user = session.get('login_user')
    if login_user:
        return login_user.get('user_kind_id') == 1
    return False


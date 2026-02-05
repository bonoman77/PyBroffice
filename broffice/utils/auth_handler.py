from flask import request, session, redirect, url_for, jsonify, flash
from functools import wraps

def login_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        if not session.get('login_user'):
            # API 요청인 경우 JSON 응답
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '로그인이 필요합니다.'}), 401
            
            # 홈(/)에서 로그인 페이지로 이동 시에는 flash 메시지 표시 안 함
            if request.path != '/':
                flash('로그인이 필요합니다.', 'warning')
            session['next'] = request.url
            return redirect(url_for('accounts.login'))

        return func(*args, **kwargs)
    return decorated_function


def admin_required(func):
    @wraps(func)
    def decorated_function(*args, **kwargs):
        # 로그인 체크
        login_user = session.get('login_user')
        if not login_user:
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '로그인이 필요합니다.'}), 401

            # flash('로그인이 필요합니다.', 'warning')
            session['next'] = request.url
            return redirect(url_for('accounts.login'))

        # 관리자 권한 체크
        if not is_admin():
            if request.is_json or request.headers.get('X-Requested-With') == 'XMLHttpRequest':
                return jsonify({'error': '관리자 권한이 필요합니다.'}), 403

            flash('관리자 권한이 필요합니다.', 'warning')
            # 이전 페이지로 리다이렉트
            referer = request.headers.get('Referer')
            if referer:
                return redirect(referer)
            return redirect(url_for('homes.index'))

        return func(*args, **kwargs)

    return decorated_function


def is_admin():
    """세션에서 관리자 여부 체크 (user_kind_id == 1)"""
    login_user = session.get('login_user')
    return login_user and login_user.get('user_kind_id') == 1


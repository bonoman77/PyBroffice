from flask import Blueprint, request, session, render_template, url_for, redirect, flash, jsonify
import broffice.dbconns as conn
from broffice.utils.auth_handler import login_required, admin_required
from broffice.utils.mail_handler import send_mail
from datetime import date, datetime, timedelta
import random

bp = Blueprint('accounts', __name__)

@bp.route('/login', methods=['GET'])
def login():
    if session.get('login_user'):
        return redirect(url_for('homes.index'))

    return render_template('accounts/login.html')


@bp.route('/login', methods=['POST'])
def login_post():

    user_email = request.form.get('user_email')
    user_passwd = request.form.get('user_passwd')

    res = conn.execute_return('get_user_login', [user_email, user_passwd])

    if res:
        if bool(res['admin_auth_yn']):

            session['login_user'] = {
                'user_id': int(res['user_id']),
                'user_name': res['user_name'],
                'user_email': res['user_email'],
                'user_mobile': res['user_mobile'] if res['user_mobile'] else None,
                'user_kind_id': int(res['user_kind_id']),
                'client_id': int(res['client_id']) if res['client_id'] else None,
                'client_name': res['client_name'] if res['client_name'] else None,
            }

            if session.get('next'):
                # 로그인 전 마지막 경로로 이동
                next = session.get('next')
                del session['next']
                return redirect(next)
            return redirect(url_for('homes.index', user_kind_id=session['login_user']['user_kind_id']))
        else:
            flash("먼저 본사로부터 사용자 승인을 받아야합니다.", category="danger")
            return render_template('accounts/login.html', user_email=user_email)    
    else:
        flash("입력한 계정이 존재하지 않습니다.", category="danger")
        return render_template('accounts/login.html', user_email=user_email)


@bp.route('/admin_user_login', methods=['POST'])
@admin_required
def admin_user_login_post():

    user_id = request.form.get('user_id')
    res = conn.execute_return('get_user_admin_login', [user_id])

    session['login_user'] = {
        'user_id': int(res['user_id']),
        'user_name': res['user_name'],
        'user_email': res['user_email'],
        'user_mobile': res['user_mobile'] if res['user_mobile'] else None,
        'user_kind_id': int(res['user_kind_id']),
        'client_id': int(res['client_id']) if res['client_id'] else None,
        'client_name': res['client_name'] if res['client_name'] else None,
    }

    if session.get('next'):
        # 로그인 전 마지막 경로로 이동
        next = session.get('next')
        del session['next']
        return redirect(next)
    return redirect(url_for('homes.index', user_kind_id=session['login_user']['user_kind_id']))


@bp.route('/user_insert', methods=['GET'])
def user_insert():
    return render_template('accounts/user_insert.html')


@bp.route('/user_insert', methods=['POST'])
def user_insert_post():
    alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    auth_code = "".join(random.choice(alphabet) for _ in range(4))

    user_name = request.form.get('user_name')
    user_email = request.form.get('user_email')
    user_passwd = request.form.get('user_passwd')
    user_account = request.form.get('user_account')
    user_mobile = request.form.get('user_mobile')
    user_kind_id = request.form.get('user_kind_id')
    client_id = request.form.get('client_id')

    res = int(conn.execute_return('set_user_regist', 
                                   [user_name, user_email, user_passwd, user_account, user_mobile, user_kind_id, client_id, auth_code])[0])

    if res == 1:
        # send_mail(user_email, user_name, auth_code, 'register')
        return redirect(url_for('accounts.welcome', user_email=user_email))
    else:
        error_messages = {
            0: "등록에 실패하였습니다. 관리자에게 문의해주세요.",
            3: "이미 사용중인 계정입니다.",
            2: "이미 사용중인 이메일입니다.", 
        }
        flash(error_messages.get(res, "알 수 없는 오류가 발생했습니다."), category="warning")   
        return render_template('accounts/user_insert.html', user_name=user_name, user_email=user_email)


@bp.route("/welcome", methods=['GET'])
def welcome():
    return render_template('accounts/welcome.html')


@bp.route("/user_profile", methods=['GET'])
@login_required
def user_profile():
    user_id = session['login_user']['user_id']
    
    # 사용자 프로필 정보 조회
    user_profile = conn.execute_return('get_user_profile', [user_id])
    
    return render_template('accounts/user_profile.html', user_profile=user_profile)


@bp.route("/user_update", methods=['GET'])
@login_required
def user_update():
    user_id = session['login_user']['user_id']
    res_list = conn.return_list('uspGetChannelUserChannelKindList', [user_id])
    return render_template('accounts/user_update.html', res_list=res_list)


@bp.route('/user_profile_update', methods=['POST'])
@login_required
def user_profile_update_post():
    user_id = session['login_user']['user_id']
    user_name = request.form.get('user_name')
    user_email = request.form.get('user_email')
    user_mobile = request.form.get('user_mobile')
    user_passwd = request.form.get('user_passwd')  # 비어있으면 None
    
    # 현재 user_kind_id 유지
    user_kind_id = session['login_user']['user_kind_id']
    
    # 프로시저 호출
    res = conn.execute_return('set_user_update', [
        user_id,
        user_name,
        user_email,
        user_mobile,
        user_kind_id,
        user_passwd if user_passwd else None
    ])
    
    if res['return_value'] == 1:
        # 세션 정보 업데이트
        session['login_user']['user_name'] = user_name
        session['login_user']['user_email'] = user_email
        flash('개인 정보가 성공적으로 수정되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('이미 사용 중인 이메일입니다.', category='warning')
    else:
        flash('개인 정보 수정에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.user_profile'))


@bp.route('/user_pass_update', methods=['POST'])
@login_required
def user_pass_update_post():
    user_id = session['login_user']['user_id']
    old_passwd = request.form.get('old_passwd')
    new_passwd = request.form.get('new_passwd')
    confirm_passwd = request.form.get('confirm_passwd')

    if new_passwd != confirm_passwd:
        flash("입력한 암호가 서로 일치하지 않습니다.", category="danger")
        return redirect(url_for('accounts.user_profile'))

    # 기존 비밀번호 확인
    user_yn = conn.execute_return('get_user_pass_confirm', [user_id, old_passwd])['UserYn']

    if not user_yn:
        flash("기존 암호가 잘못되었습니다.", category="danger")
        return redirect(url_for('accounts.user_profile'))

    # 새 비밀번호로 변경
    conn.execute_return('set_user_pass_update', [user_id, new_passwd])

    flash("암호가 정상적으로 수정되었습니다.", category="success")
    return redirect(url_for('accounts.user_profile'))


@bp.route('/auth_mail_resend', methods=['GET'])
def auth_mail_resend():
    if session.get('login_user'):
        return redirect(url_for('homes.index'))

    return render_template('accounts/auth_mail_resend.html')


@bp.route('/auth_mail_resend', methods=['POST'])
def auth_mail_resend_post():
    alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    auth_code = "".join(random.choice(alphabet) for _ in range(4))

    user_email = request.form.get('user_email')
    user_name = request.form.get('user_name')
    user_passwd = request.form.get('user_passwd')

    res = conn.execute_return('uspSetChannelUserEmailReAuthRequest', 
                              [user_email, user_passwd, user_name, auth_code])[0]

    if not res:
        flash("등록된 계정이 아닙니다. 다시 확인해 해주세요.", category="danger")
        return render_template('accounts/auth_mail_resend.html', user_email=user_email, user_name=user_name)

    send_mail(user_email, user_name, auth_code, 're_auth')
    flash("인증 메일이 재발송 완료되었습니다. 개인 메일을 확인해주세요.", category="success")
    return redirect(url_for('homes.index'))


@bp.route('/user_pass_reset', methods=['GET'])
def user_pass_reset():
    if session.get('login_user'):
        return redirect(url_for('homes.index'))

    return render_template('accounts/user_pass_reset.html')


@bp.route('/user_pass_reset', methods=['POST'])
def user_pass_reset_post():
    alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'
    auth_code = "".join(random.choice(alphabet) for _ in range(4))

    user_email = request.form.get('user_email')
    user_name = request.form.get('user_name')

    res = conn.execute_return('uspSetChannelUserPassReset', [user_email, user_name, auth_code])[0]

    if not res:
        flash("등록된 계정이 아닙니다. 다시 확인해 해주세요.", category="danger")
        return render_template('accounts/user_pass_reset.html', user_email=user_email, user_name=user_name)

    send_mail(user_email, user_name, auth_code, 'reset_passwd')
    flash("비밀번호 초기화 신청이 완료되었습니다. 개인 메일을 확인해 해주세요.", category="success")
    return redirect(url_for('homes.index'))


# 발송된 메일에서 확인하는 경로
@bp.route('/auth', methods=['GET'])
def auth():
    user_email = request.args.get('user_email')
    auth_code = request.args.get('auth_code')

    res = int(conn.execute_return('uspSetChannelUserEmailAuth', [user_email, auth_code])[0])

    if res == 1:
        flash("이메일 인증이 완료되었습니다. 로그인 해주세요.", category="success")
        return redirect(url_for('accounts.login'))
    else:
        flash("인증에 실패했습니다. 다시 진행해 주세요.", category="danger")
        return redirect(url_for('accounts.login'))


# 발송된 메일에서 확인하는 경로
@bp.route('/auth_pass_update', methods=['GET'])
def auth_pass_update():
    user_email = request.args.get('user_email')
    auth_code = request.args.get('auth_code')

    res = int(conn.execute_return('uspSetChannelUserPassAuth', [user_email, auth_code])[0])

    if res == 1:
        flash("이메일 인증이 완료되었습니다. 비밀번호를 변경해 주세요.", category="success")
        return render_template('accounts/auth_pass_update.html', user_email=user_email)
    else:
        flash("인증에 실패했습니다. 다시 진행해 주세요.", category="danger")
        return redirect(url_for('accounts.login'))



@bp.route('/auth_pass_update', methods=['POST'])
def auth_pass_update_post():
    user_email = request.form.get('user_email')
    new_passwd = request.form.get('new_passwd')
    confirm_passwd = request.form.get('confirm_passwd')

    if new_passwd != confirm_passwd:
        flash("입력한 암호가 서로 일치하지 않습니다.", category="danger")
        return render_template('accounts/auth_pass_update.html', user_email=user_email)

    res = int(conn.execute_return('uspSetChannelUserPassAuthUpdate', [user_email, new_passwd])[0])

    if not res:
        flash("이메일 계정이 올바르지 않습니다. 변경 요청 절차를 다시 진행해주세요.", category="danger")
        return render_template('accounts/auth_pass_update.html', user_email=user_email)

    flash("암호가 정상적으로 수정되었습니다.", category="info")
    return redirect(url_for('accounts.login'))


@bp.route("/user_list", methods=['GET'])
def user_list():
    # 프로시저 1: 사용자 목록 조회
    users = conn.return_list('get_user_list')
    
    # 프로시저 2: 사용자 통계
    stats = conn.execute_return('get_user_stats')
    
    return render_template('accounts/user_list.html',
                         users=users,
                         total_users=stats['total_users'],
                         active_users=stats['active_users'],
                         pending_users=stats['pending_users'],
                         inactive_users=stats['inactive_users'])


@bp.route('/user_admin_update', methods=['POST'])
def user_admin_update_post():
    user_id = request.form.get('userId')
    user_name = request.form.get('editUserName')
    user_email = request.form.get('editUserEmail')
    user_phone = request.form.get('editUserPhone')
    user_role = request.form.get('editUserRole')
    user_password = request.form.get('editUserPassword')  # 비어있으면 None
    
    # 프로시저 호출
    res = conn.execute_return('set_user_update', [
        user_id,
        user_name,
        user_email,
        user_phone,
        user_role,
        user_password if user_password else None
    ])
    
    if res['return_value'] == 1:
        flash('회원 정보가 성공적으로 수정되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('이미 사용 중인 이메일입니다.', category='warning')
    elif res['return_value'] == 4:
        flash('회원을 찾을 수 없습니다.', category='danger')
    else:
        flash('회원 정보 수정에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.user_list'))


@bp.route("/client_list", methods=['GET'])
def client_list():
    # 프로시저 1: 업체 목록 조회
    clients = conn.return_list('get_client_list')
    
    # 프로시저 2: 업무 종류별 통계
    stats = conn.execute_return('get_client_stats_by_task_kind')
    
    return render_template('accounts/client_list.html',
                         clients=clients,
                         total_clients=stats['total_clients'],
                         cleaning_clients=stats['cleaning_clients'],
                         snack_clients=stats['snack_clients'],
                         supplies_clients=stats['supplies_clients'])


@bp.route('/client_insert', methods=['POST'])
def client_insert_post():
    client_name = request.form.get('clientName')
    manager_name = request.form.get('clientManager')
    manager_mobile = request.form.get('managerPhone')
    management_level = request.form.get('managerPosition')
    client_address = request.form.get('clientAddress')
    contracted_at = request.form.get('contractDate')
    memo = request.form.get('memo')
    
    # 업무 종류 (taskKind[]) - 체크박스에서 선택된 값들
    task_kinds = request.form.getlist('taskKind[]')
    task_kinds_str = ','.join(task_kinds) if task_kinds else ''
    
    # 프로시저 호출
    res = conn.execute_return('set_client_insert', [
        client_name,
        manager_name,
        manager_mobile,
        management_level,
        client_address,
        contracted_at,
        memo,
        task_kinds_str
    ])
    
    if res['return_value'] == 1:
        flash('업체가 성공적으로 등록되었습니다.', category='success')
    else:
        flash('업체 등록에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.client_list'))


@bp.route('/client_update', methods=['POST'])
def client_update_post():
    client_id = request.form.get('clientId')
    client_name = request.form.get('editClientName')
    manager_name = request.form.get('editClientManager')
    manager_mobile = request.form.get('editManagerPhone')
    management_level = request.form.get('editManagerPosition')
    client_address = request.form.get('editClientAddress')
    contracted_at = request.form.get('editContractDate')
    memo = request.form.get('editMemo')
    
    # 업무 종류
    task_kinds = request.form.getlist('editTaskKind[]')
    task_kinds_str = ','.join(task_kinds) if task_kinds else ''
    
    # 프로시저 호출
    res = conn.execute_return('set_client_update', [
        client_id,
        client_name,
        manager_name,
        manager_mobile,
        management_level,
        client_address,
        contracted_at,
        memo,
        task_kinds_str
    ])
    
    if res['return_value'] == 1:
        flash('업체 정보가 성공적으로 수정되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('업체를 찾을 수 없습니다.', category='danger')
    else:
        flash('업체 정보 수정에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.client_list'))


@bp.route('/logout', methods=['GET'])
@login_required
def logout():
    del session['login_user']
    return redirect(url_for('accounts.login'))
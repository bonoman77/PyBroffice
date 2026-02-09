from flask import Blueprint, request, session, render_template, url_for, redirect, flash, jsonify
import broffice.dbconns as conn
from broffice.utils.auth_handler import login_required, admin_required
from broffice.utils.mail_handler import send_mail
from datetime import date, datetime, timedelta
import random

bp = Blueprint('accounts', __name__)

# -------------------
# 로그인/로그아웃    
# -------------------

@bp.route('/login', methods=['GET'])
def login():
    if session.get('login_user'):
        return redirect(url_for('homes.index'))

    return render_template('accounts/login.html')


@bp.route('/login', methods=['POST'])
def login_post():

    user_email = request.form.get('user_email')
    user_passwd = request.form.get('user_passwd')
    remember = request.form.get('remember')  # 로그인 상태 유지 체크박스

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

            # 로그인 상태 유지 설정
            session.permanent = bool(remember)

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


@bp.route('/logout', methods=['GET'])
@login_required
def logout():
    del session['login_user']
    return redirect(url_for('accounts.login'))

# -------------------
# 회원 가입  
# -------------------

@bp.route('/user_regist', methods=['GET'])
def user_regist():
    return render_template('accounts/user_regist.html')


@bp.route('/user_regist', methods=['POST'])
def user_regist_post():
    user_name = request.form.get('userName')
    user_email = request.form.get('userEmail')
    user_passwd = request.form.get('userPasswd')
    user_mobile = request.form.get('userMobile')
    user_kind_id = request.form.get('userKindId')
    client_id = request.form.get('clientId')
    # client_id가 빈값이거나 없으면 NULL로 처리
    if not client_id or client_id.strip() == '':
        client_id = None
    user_status = request.form.get('userStatus', 'inactive')  # 기본값 비활성

    res = conn.execute_return('set_user_insert', 
                              [user_name, user_email, user_mobile, user_kind_id, user_passwd, user_status, client_id])

    if res['return_value'] == 1:
        return redirect(url_for('accounts.welcome'))
    elif res['return_value'] == 2:
        flash('이미 사용중인 이메일입니다.', category='warning')
        return redirect(url_for('accounts.user_regist'))
    else:
        flash('회원 등록에 실패했습니다.', category='danger')
        return redirect(url_for('accounts.user_regist'))


@bp.route("/welcome", methods=['GET'])
def welcome():
    return render_template('accounts/welcome.html')


# -------------------
# 회원 프로필 
# -------------------

@bp.route("/user_profile", methods=['GET'])
@login_required
def user_profile():
    user_id = session['login_user']['user_id']
    
    # 사용자 프로필 정보 조회
    user_profile = conn.execute_return('get_user_profile', [user_id])
    
    return render_template('accounts/user_profile.html', user_profile=user_profile)


@bp.route('/user_profile_update', methods=['POST'])
@login_required
def user_profile_update_post():
    user_id = session['login_user']['user_id']
    user_mobile = request.form.get('user_mobile')
    user_passwd = request.form.get('user_passwd')  # 비어있으면 None
    
    # 프로시저 호출
    res = conn.execute_return('set_user_profile_update', [
        user_id,
        user_mobile
    ])
    
    if res['return_value'] == 1:
        # 세션 정보 업데이트
        flash('개인 정보가 성공적으로 수정되었습니다.', category='success')
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


# ================
# 관리자 전용 페이지
# ================

@bp.route("/user_list", methods=['GET'])
@admin_required
def user_list():
    # 프로시저 1: 사용자 목록 조회
    users = conn.return_list('get_user_list')

    print(users)
    # 프로시저 2: 사용자 통계
    stats = conn.execute_return('get_user_stats')
    
    return render_template('accounts/user_list.html',
                         users=users,
                         total_users=stats.get('total_users', 0) if stats else 0,
                         active_users=stats.get('active_users', 0) if stats else 0,
                         pending_users=stats.get('pending_users', 0) if stats else 0,
                         inactive_users=stats.get('inactive_users', 0) if stats else 0)


@bp.route('/user_admin_login', methods=['POST'])
@admin_required
def user_admin_login_post():

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
    

@bp.route('/user_admin_insert', methods=['POST'])
@admin_required
def user_admin_insert_post():
    user_name = request.form.get('userName')
    user_email = request.form.get('userEmail')
    user_passwd = request.form.get('userPasswd')
    user_mobile = request.form.get('userMobile')
    user_kind_id = request.form.get('userKindId')
    client_id = request.form.get('clientId')
    # client_id가 빈값이거나 없으면 NULL로 처리
    if not client_id or client_id.strip() == '':
        client_id = None
    user_status = request.form.get('userStatus', 'active')  # 기본값 활성

    res = conn.execute_return('set_user_insert', 
                              [user_name, user_email, user_mobile, user_kind_id, user_passwd, user_status, client_id])

    if res['return_value'] == 1:
        flash('회원이 성공적으로 등록되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('이미 사용중인 이메일입니다.', category='warning')
    else:
        flash('회원 등록에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.user_list'))


@bp.route('/user_admin_update', methods=['POST'])
@admin_required
def user_admin_update_post():
    user_id = request.form.get('userId')
    user_name = request.form.get('editUserName')
    user_mobile = request.form.get('editUserMobile')
    user_kind_id = request.form.get('editUserKindId')
    user_passwd = request.form.get('editUserPasswd')  # 비어있으면 None
    user_status = request.form.get('editUserStatus', 'active')  # 상태 값
    client_id = request.form.get('editClientId')
    
    # client_id가 빈값이거나 없으면 NULL로 처리
    if not client_id or client_id.strip() == '':
        client_id = None
    
    # 프로시저 호출
    res = conn.execute_return('set_user_update', [
        user_id,
        user_name,
        user_mobile,
        user_kind_id,
        user_passwd if user_passwd else None,
        user_status,
        client_id
    ])
    
    if res['return_value'] == 1:
        flash('회원 정보가 성공적으로 수정되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('회원을 찾을 수 없습니다.', category='danger')
    else:
        flash('회원 정보 수정에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.user_list'))


@bp.route('/user_admin_delete', methods=['POST'])
@admin_required
def user_admin_delete_post():
    """회원 삭제 API"""
    user_id = request.form.get('user_id') or request.json.get('user_id')
    
    if not user_id:
        if request.is_json:
            return jsonify({'error': 'user_id is required'}), 400
        flash('회원 ID가 필요합니다.', category='danger')
        return redirect(url_for('accounts.user_list'))
    
    # MySQL 프로시저 호출하여 회원 삭제
    try:
        res = conn.execute_return('set_user_delete', [user_id])
        
        if res and res.get('return_value') == 1:
            if request.is_json:
                return jsonify({'success': True, 'message': '회원이 삭제되었습니다.'}), 200
            flash('회원이 삭제되었습니다.', category='success')
        else:
            if request.is_json:
                return jsonify({'error': '회원 삭제에 실패했습니다.'}), 500
            flash('회원 삭제에 실패했습니다.', category='danger')
    except Exception as e:
        if request.is_json:
            return jsonify({'error': str(e)}), 500
        flash('회원 삭제 중 오류가 발생했습니다.', category='danger')
    
    return redirect(url_for('accounts.user_list'))


@bp.route('/user_detail/<int:user_id>', methods=['GET'])
@admin_required
def user_detail(user_id):
    """회원 상세정보 조회"""
    # 개별 사용자 정보 조회
    user_profile = conn.execute_return('get_user_profile', [user_id])
    
    if not user_profile:
        flash('회원을 찾을 수 없습니다.', category='danger')
        return redirect(url_for('accounts.user_list'))
    
    return render_template('accounts/user_detail.html', user_profile=user_profile)


# ================
# 업체 관리
# ================

@bp.route("/client_list", methods=['GET'])
@admin_required
def client_list():
    # 프로시저 1: 업체 목록 조회
    clients = conn.return_list('get_client_list')
    print(clients)

    # 프로시저 2: 업무 종류별 통계
    stats = conn.execute_return('get_client_stats_by_task_kind')
    
    return render_template('accounts/client_list.html',
                         clients=clients,
                         total_clients=stats['total_clients'],
                         cleaning_clients=stats['cleaning_clients'],
                         snack_clients=stats['snack_clients'],
                         supplies_clients=stats['supplies_clients'])


@bp.route('/client_insert', methods=['POST'])
@admin_required
def client_insert_post():
    client_name = request.form.get('clientName')
    client_phone = request.form.get('clientPhone')
    client_address = request.form.get('clientAddress')
    client_business_number = request.form.get('clientBusinessNumber')
    manager_name = request.form.get('managerName')
    manager_mobile = request.form.get('managerMobile')
    manager_position = request.form.get('managerPosition')
    contracted_at = request.form.get('contractDate')
    memo = request.form.get('memo')
    
    # 업무 종류 - 각 체크박스를 직접 확인하여 1/0 숫자로 변환
    cleaning_yn = 1 if request.form.get('cleaningYn') else 0
    snack_yn = 1 if request.form.get('snackYn') else 0
    office_supplies_yn = 1 if request.form.get('officeSuppliesYn') else 0

    # 상태 값
    status = request.form.get('status', 'inactive')

    # 프로시저 호출
    res = conn.execute_return('set_client_insert', [
        client_name,
        client_phone,
        client_address,
        client_business_number,
        manager_name,
        manager_mobile,
        manager_position,
        contracted_at,
        memo,
        cleaning_yn,
        snack_yn,
        office_supplies_yn,
        status
    ])
    
    if res['return_value'] == 1:
        flash('업체가 성공적으로 등록되었습니다.', category='success')
    else:
        flash('업체 등록에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.client_list'))


@bp.route('/client_update', methods=['POST'])
@admin_required
def client_update_post():
    client_id = request.form.get('clientId')
    client_name = request.form.get('editClientName')
    client_phone = request.form.get('editClientPhone')
    client_address = request.form.get('editClientAddress')
    client_business_number = request.form.get('editClientBusinessNumber')
    manager_name = request.form.get('editManagerName')
    manager_mobile = request.form.get('editManagerMobile')
    manager_position = request.form.get('editManagerPosition')
    contracted_at = request.form.get('editContractDate')
    memo = request.form.get('editMemo') 
    
    # 업무 종류 - 각 체크박스를 직접 확인하여 1/0 숫자로 변환
    cleaning_yn = 1 if request.form.get('editCleaningYn') else 0
    snack_yn = 1 if request.form.get('editSnackYn') else 0
    office_supplies_yn = 1 if request.form.get('editOfficeSuppliesYn') else 0
    
    # 상태 값
    status = request.form.get('editStatus', 'active')
    
    # 프로시저 호출
    res = conn.execute_return('set_client_update', [
        client_id,
        client_name,
        client_phone,
        client_address,
        client_business_number,
        manager_name,
        manager_mobile,
        manager_position,
        contracted_at,
        memo,
        cleaning_yn,
        snack_yn,
        office_supplies_yn,
        status
    ])
    
    if res['return_value'] == 1:
        flash('업체 정보가 성공적으로 수정되었습니다.', category='success')
    elif res['return_value'] == 2:
        flash('업체를 찾을 수 없습니다.', category='danger')
    else:
        flash('업체 정보 수정에 실패했습니다.', category='danger')
    
    return redirect(url_for('accounts.client_list'))


@bp.route('/api/clients', methods=['GET'])
@admin_required
def api_clients():
    """업체 목록 API (회원 등록/수정용 - 활성 업체만)"""
    try:
        res = conn.return_list('get_active_client_list')
        
        if res:
            return jsonify(res)
        else:
            return jsonify([])
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/client_admin_delete', methods=['POST'])
@admin_required
def client_admin_delete_post():
    """업체 삭제 API"""
    client_id = request.form.get('client_id') or request.json.get('client_id')
    
    if not client_id:
        if request.is_json:
            return jsonify({'error': 'client_id is required'}), 400
        flash('업체 ID가 필요합니다.', category='danger')
        return redirect(url_for('accounts.client_list'))
    
    # MySQL 프로시저 호출하여 업체 삭제
    try:
        res = conn.execute_return('set_client_delete', [client_id])
        
        if res and res.get('return_value') == 1:
            if request.is_json:
                return jsonify({'success': True, 'message': '업체가 삭제되었습니다.'}), 200
            flash('업체가 삭제되었습니다.', category='success')
        else:
            if request.is_json:
                return jsonify({'error': '업체 삭제에 실패했습니다.'}), 500
            flash('업체 삭제에 실패했습니다.', category='danger')
    except Exception as e:
        if request.is_json:
            return jsonify({'error': str(e)}), 500
        flash('업체 삭제 중 오류가 발생했습니다.', category='danger')
    
    return redirect(url_for('accounts.client_list'))

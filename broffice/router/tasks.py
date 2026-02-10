from flask import Blueprint, render_template, request, jsonify
from broffice.utils.auth_handler import login_required, admin_required
import broffice.dbconns as conn

bp = Blueprint('tasks', __name__)


@bp.route("/task_list", methods=['GET'])
@admin_required
def task_list():
    """스케줄 목록 (task_kind_id로 구분)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    
    # 스케줄 목록 조회 (tasks 테이블 기반)
    if task_kind_id in [4, 5, 6]:  # 청소, 간식, 비품
        schedules = conn.return_list('get_task_list', [task_kind_id])
        # 모달용 업체 목록 조회
        clients = conn.return_list('get_client_list_by_task_kind', [task_kind_id])
        # 작업자 목록 조회 (user_kind_id=2)
        workers = conn.return_list('get_workers_list', [])
    else:
        schedules = []
        clients = []
        workers = []
    
    return render_template('tasks/task_list.html', schedules=schedules, clients=clients, workers=workers, task_kind_id=task_kind_id)


@bp.route("/task_schedule_list", methods=['GET'])
@admin_required
def task_schedule_list():
    """업체 업무 목록 (task_kind_id로 구분)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    # TODO: DB에서 task_kind_id별 업체 목록 조회
    # res_list = conn.return_list('uspGetClientTaskList', task_kind_id=task_kind_id)
    return render_template('tasks/task_schedule_list.html', task_kind_id=task_kind_id)


@bp.route("/schedule_update", methods=['POST'])
@admin_required
def schedule_update():
    """스케줄 수정"""
    task_id = request.form.get('taskId', type=int)
    task_kind_id = request.form.get('taskKindId', type=int)
    client_id = request.form.get('clientId', type=int)
    user_id = request.form.get('userId', type=int)
    
    # 여러 요일 값 처리
    days_of_week_list = request.form.getlist('daysOfWeek')
    
    # fix_dates가 있으면 월별 스케줄
    fix_dates = request.form.get('fixDates') or None  # 비어있으면 None
    
    if fix_dates:
        days_of_week = '0'  # 월별 스케줄
    elif len(days_of_week_list) == 7:
        days_of_week = '1,2,3,4,5,6,7'  # 매일
    else:
        days_of_week = ','.join(days_of_week_list) if days_of_week_list else ''
    
    service_started_at = request.form.get('editServiceStartedAt')
    service_ended_at = request.form.get('editServiceEndedAt')
    use_yn = 1 if request.form.get('useYn') else 0
    
    # 프로시저 호출
    res = conn.execute_return('set_task_update', [
        task_id,
        client_id,
        user_id,
        days_of_week,
        fix_dates,
        service_started_at,
        service_ended_at,
        use_yn
    ])
    
    return jsonify({
        'success': True,
        'message': '스케줄이 수정되었습니다.',
        'data': res
    })


@bp.route("/schedule_insert", methods=['POST'])
@admin_required
def schedule_insert():
    """스케줄 등록"""
    task_kind_id = request.form.get('taskKindId', type=int)
    client_id = request.form.get('clientId', type=int)
    user_id = request.form.get('userId', type=int)
    # 여러 요일 값 처리
    days_of_week_list = request.form.getlist('daysOfWeek')
    
    # fix_dates가 있으면 월별 스케줄
    fix_dates = request.form.get('fixDates') or None  # 비어있으면 None
    
    if fix_dates:
        days_of_week = '0'  # 월별 스케줄
    elif len(days_of_week_list) == 7:
        days_of_week = '1,2,3,4,5,6,7'  # 매일
    else:
        days_of_week = ','.join(days_of_week_list) if days_of_week_list else ''
    
    service_started_at = request.form.get('serviceStartedAt')
    service_ended_at = request.form.get('serviceEndedAt')
    use_yn = 1 if request.form.get('useYn') else 0
    
    # 프로시저 호출
    res = conn.execute_return('set_task_insert', [
        task_kind_id,
        client_id,
        user_id,
        days_of_week,
        fix_dates,
        service_started_at,
        service_ended_at,
        use_yn
    ])
    
    return jsonify({
        'success': True,
        'message': '스케줄이 등록되었습니다.',
        'data': res
    })


@bp.route("/insert", methods=['GET', 'POST'])

@admin_required
def insert():
    """업무 등록"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/insert.html', task_kind_id=task_kind_id)


@bp.route("/assign", methods=['GET'])
@admin_required
def assign():
    """직원 연결"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/assign.html', task_kind_id=task_kind_id)


@bp.route("/result", methods=['GET'])
@login_required
def result():
    """업무 결과 확인"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/result.html', task_kind_id=task_kind_id)


@bp.route("/notify", methods=['GET', 'POST'])
@login_required
def notify():
    """업무완료 통보 (업체에 알림)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/notify.html', task_kind_id=task_kind_id)

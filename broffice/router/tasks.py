from flask import Blueprint, render_template, request, jsonify
from broffice.utils.auth_handler import login_required, admin_required
import broffice.dbconns as conn

bp = Blueprint('tasks', __name__)


@bp.route("/client_list", methods=['GET'])
@admin_required
def client_list():
    """등록 업체 목록 (task_kind_id로 구분)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    
    # 업무 종류별 업체 목록 조회 (프로시저에서 필터링)
    if task_kind_id in [4, 5, 6]:  # 청소, 간식, 비품
        clients = conn.return_list('get_client_list_by_task_kind', [task_kind_id])
    else:
        clients = []
    
    return render_template('tasks/client_list.html', clients=clients, task_kind_id=task_kind_id)


@bp.route("/client_task_list", methods=['GET'])
@admin_required
def client_task_list():
    """업체 업무 목록 (task_kind_id로 구분)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    # TODO: DB에서 task_kind_id별 업체 목록 조회
    # res_list = conn.return_list('uspGetClientTaskList', task_kind_id=task_kind_id)
    return render_template('tasks/client_task_list.html', task_kind_id=task_kind_id)


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

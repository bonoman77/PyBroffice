from datetime import datetime
from flask import Blueprint, render_template, request, session, jsonify
from broffice.utils.auth_handler import admin_required
import broffice.dbconns as conn

bp = Blueprint('reports', __name__)

TASK_KIND_MAP = {
    0: {'name': '전체', 'icon': 'bi-graph-up', 'color': 'primary'},
    4: {'name': '청소', 'icon': 'ph-duotone ph-broom', 'color': 'success'},
    5: {'name': '간식', 'icon': 'ph-duotone ph-hamburger', 'color': 'warning'},
    6: {'name': '비품', 'icon': 'ph-duotone ph-package', 'color': 'danger'},
}


@bp.route("/dashboard", methods=['GET'])
@bp.route("/dashboard/<int:task_kind_id>", methods=['GET'])
@admin_required
def dashboard(task_kind_id=0):
    """리포트 대시보드 - 월별 종합 통계"""
    year_month = request.args.get('year_month', datetime.now().strftime('%Y-%m'))
    manage_user_id = request.args.get('manage_user_id', 0, type=int)
    
    kind_info = TASK_KIND_MAP.get(task_kind_id, TASK_KIND_MAP[0])
    
    # 관리직원 목록 (드롭다운용)
    managers = conn.return_list('get_report_managers', []) or []
    
    # 월별 작업 종합 통계
    monthly_summary = conn.return_list('get_report_monthly_summary', [year_month, manage_user_id]) or []
    
    # 업체별 작업 현황
    client_stats = conn.return_list('get_report_by_client', [year_month, task_kind_id, manage_user_id]) or []
    
    # 직원별 작업 현황
    worker_stats = conn.return_list('get_report_by_worker', [year_month, task_kind_id, manage_user_id]) or []
    
    # 일별 작업 추이
    daily_trend = conn.return_list('get_report_daily_trend', [year_month, task_kind_id, manage_user_id]) or []
    
    # 종합 집계
    if task_kind_id == 0:
        totals = {
            'total': sum(r.get('total_count', 0) for r in monthly_summary),
            'completed': sum(r.get('completed_count', 0) for r in monthly_summary),
            'pending': sum(r.get('pending_count', 0) for r in monthly_summary),
            'overdue': sum(r.get('overdue_count', 0) for r in monthly_summary),
        }
    else:
        matched = [r for r in monthly_summary if r.get('task_kind_id') == task_kind_id]
        if matched:
            r = matched[0]
            totals = {
                'total': r.get('total_count', 0),
                'completed': r.get('completed_count', 0),
                'pending': r.get('pending_count', 0),
                'overdue': r.get('overdue_count', 0),
            }
        else:
            totals = {'total': 0, 'completed': 0, 'pending': 0, 'overdue': 0}
    totals['rate'] = round(totals['completed'] / totals['total'] * 100, 1) if totals['total'] > 0 else 0
    
    return render_template('reports/dashboard.html',
        year_month=year_month,
        task_kind_id=task_kind_id,
        manage_user_id=manage_user_id,
        kind_info=kind_info,
        managers=managers,
        monthly_summary=monthly_summary,
        client_stats=client_stats,
        worker_stats=worker_stats,
        daily_trend=daily_trend,
        totals=totals
    )


@bp.route("/sns_logs", methods=['GET'])
@admin_required
def sns_logs():
    """문자 발송 내역"""
    year_month = request.args.get('year_month', datetime.now().strftime('%Y-%m'))
    send_status = request.args.get('send_status', '')
    
    logs = conn.return_list('get_sns_log_list', [year_month, send_status]) or []
    
    # 상태별 건수
    total_count = len(logs)
    scheduled_count = sum(1 for l in logs if l.get('send_status') == 'scheduled')
    sent_count = sum(1 for l in logs if l.get('send_status') == 'sent')
    pending_count = sum(1 for l in logs if l.get('send_status') == 'pending')
    error_count = sum(1 for l in logs if l.get('send_status') in ('error', 'config_missing', 'no_package'))
    
    return render_template('reports/sns_logs.html',
        year_month=year_month,
        send_status=send_status,
        logs=logs,
        total_count=total_count,
        scheduled_count=scheduled_count,
        sent_count=sent_count,
        pending_count=pending_count,
        error_count=error_count
    )

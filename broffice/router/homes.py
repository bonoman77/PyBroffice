import random
import broffice.dbconns as conn
from datetime import datetime
from broffice.utils.auth_handler import login_required
from flask import Blueprint, request, session, render_template, redirect, url_for, flash, json, jsonify

bp = Blueprint('homes', __name__)

@bp.route("/", methods=['GET'])
@login_required
def index():
    user_kind_id = session.get('login_user', {}).get('user_kind_id')
    
    # 사용자 유형별 대시보드 템플릿 분기
    if user_kind_id == 1:
        # 관리자용 대시보드
        return render_template('homes/index.html')
    elif user_kind_id == 2:
        # 직원용 대시보드
        return render_template('homes/index_staff.html')
    elif user_kind_id == 3:
        # 업체담당자용 대시보드
        return render_template('homes/index_client.html')
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


@bp.route("/timeline")
@login_required
def timeline():
    return render_template('homes/timeline.html')


@bp.route("/notice_list", methods=['GET'])
def notice_list():
    # res_list = conn.return_list('uspGetChannelNoticeSubList')

    return render_template('homes/notice_list.html')


@bp.route("/get_notice_content", methods=['GET'])
def get_notice_content():
    channel_notice_id = request.args.get('channel_notice_id')
    
    if not channel_notice_id:
        return jsonify({'error': 'channel_notice_id is required'}), 400
    
    # 공지사항 내용 조회 프로시저 호출 (프로시저가 있다면)
    # notice = conn.execute_return('get_notice_content', [channel_notice_id])
    
    # 임시로 빈 내용 반환 (프로시저 생성 후 수정 필요)
    return jsonify({'content': '공지사항 내용이 여기에 표시됩니다.'})




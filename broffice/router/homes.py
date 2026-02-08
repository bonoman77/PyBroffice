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


@bp.route("/notice_list", methods=['GET', 'POST'])
@login_required
def notice_list():
    if request.method == 'POST':
        user_id = session.get('login_user', {}).get('user_id')
        target_user_kind_id = request.form.get('target_user_kind_id', '0')
        title = request.form.get('title', '')
        content = request.form.get('content', '')
        top_expose_yn = 1 if request.form.get('top_expose') else 0
        
        # 필수값 검증
        if not title or not content:
            flash('제목과 내용을 입력해주세요.', category='danger')
            return redirect(url_for('homes.notice_list'))
        
        # 공지사항 등록 프로시저 호출
        try:
            result = conn.execute_return('set_notice_insert', [
                user_id,
                int(target_user_kind_id),
                title + '\n\n' + content,  # 제목과 내용 합쳐서 저장
                top_expose_yn,
                1  # display_yn
            ])
            
            if result:
                flash('공지사항이 등록되었습니다.', category='success')
            else:
                flash('공지사항 등록에 실패했습니다.', category='danger')
        except Exception as e:
            flash(f'공지사항 등록 중 오류가 발생했습니다: {str(e)}', category='danger')
        
        return redirect(url_for('homes.notice_list'))
    
    # GET 요청 처리
    res_list = conn.return_list('get_notice_list', [session.get('login_user', {}).get('user_kind_id', 0)])
    return render_template('homes/notice_list.html', res_list=res_list)


@bp.route("/get_notice_content", methods=['GET'])
def get_notice_content():
    channel_notice_id = request.args.get('channel_notice_id')
    
    if not channel_notice_id:
        return jsonify({'error': 'channel_notice_id is required'}), 400
    
    # 공지사항 내용 조회 프로시저 호출 (프로시저가 있다면)
    # notice = conn.execute_return('get_notice_content', [channel_notice_id])
    
    # 임시로 빈 내용 반환 (프로시저 생성 후 수정 필요)
    return jsonify({'content': '공지사항 내용이 여기에 표시됩니다.'})




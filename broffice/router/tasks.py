import os
import uuid
from datetime import datetime
from flask import Blueprint, render_template, request, jsonify, redirect, url_for, session, current_app
from werkzeug.utils import secure_filename
from broffice.utils.auth_handler import login_required, admin_required
from broffice.utils.sms_handler import schedule_completion_sms
import broffice.dbconns as conn

bp = Blueprint('tasks', __name__)


@bp.route("/task_list/<int:task_kind_id>", methods=['GET'])
@admin_required
def task_list(task_kind_id):
    # 스케줄 목록 조회 (tasks 테이블 기반)
    if task_kind_id in [4, 5, 6]:  # 청소, 간식, 비품
        tasks = conn.return_list('get_task_list', [task_kind_id])
        # 모달용 업체 목록 조회
        clients = conn.return_list('get_client_list_by_task_kind', [task_kind_id])
        # 작업자 목록 조회 (user_kind_id=2)
        workers = conn.return_list('get_workers_list', [])
    else:
        tasks = []
        clients = []
        workers = []
    
    return render_template('tasks/task_list.html', tasks=tasks, clients=clients, workers=workers, task_kind_id=task_kind_id)


@bp.route("/task_schedule_list/<int:task_kind_id>", methods=['GET'])
@admin_required
def task_schedule_list(task_kind_id):
    """스케줄 일정 목록 (날짜순)"""
    from datetime import datetime
    year_month = request.args.get('year_month', '')
    
    # 년월 기본값: 당월
    if not year_month:
        year_month = datetime.now().strftime('%Y-%m')
    
    schedules = []
    if task_kind_id in [4, 5, 6]:
        schedules = conn.return_list('get_task_schedule_list', [task_kind_id, year_month])
    
    return render_template('tasks/task_schedule_list.html',
                           task_kind_id=task_kind_id,
                           schedules=schedules,
                           year_month=year_month)


@bp.route("/schedule_date_update", methods=['POST'])
@admin_required
def schedule_date_update():
    """스케줄 날짜 변경"""
    from flask import session
    task_schedule_id = request.form.get('taskScheduleId', type=int)
    new_scheduled_date = request.form.get('newScheduledDate') or None
    change_user_id = session.get('login_user', {}).get('user_id')
    
    res = conn.execute_return('set_task_schedule_update', [
        task_schedule_id, new_scheduled_date, change_user_id
    ])
    
    return jsonify({
        'success': True,
        'message': '스케줄 날짜가 변경되었습니다.',
        'data': res
    })


@bp.route("/schedule_delete", methods=['POST'])
@admin_required
def schedule_delete():
    """스케줄 삭제"""
    task_schedule_id = request.form.get('taskScheduleId', type=int)
    
    res = conn.execute_return('set_task_schedule_delete', [task_schedule_id])
    
    if res and res.get('return_value', 0) > 0:
        return jsonify({
            'success': True,
            'message': '스케줄이 삭제되었습니다.',
            'data': res
        })
    else:
        return jsonify({
            'success': False,
            'message': '완료된 스케줄은 삭제할 수 없습니다.',
            'data': res
        })


@bp.route("/task_update", methods=['POST'])
@admin_required
def task_update():
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
    
    service_started_at = request.form.get('serviceStartedAt') or None
    service_ended_at = request.form.get('serviceEndedAt') or None
    use_yn = 1 if request.form.get('useYn') else 0
    
    days_of_week = days_of_week if days_of_week else None
    
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


@bp.route("/task_schedule_generate", methods=['POST'])
@admin_required
def task_schedule_generate():
    """스케줄 일괄 생성"""
    try:
        task_ids = request.form.getlist('taskIds[]')
        year_month = request.form.get('yearMonth')
        
        results = []
        total_count = 0
        skipped_messages = []
        for task_id in task_ids:
            res = conn.execute_return('set_task_schedule_generate', [int(task_id), year_month])
            if res:
                rv = res.get('return_value', 0)
                msg = res.get('message', '')
                if rv > 0:
                    total_count += rv
                elif msg:
                    skipped_messages.append(msg)
                results.append(res)
        
        message = f'총 {total_count}건의 스케줄이 생성되었습니다.'
        if skipped_messages:
            inactive_cnt = sum(1 for m in skipped_messages if '비활성' in m)
            no_area_cnt = sum(1 for m in skipped_messages if '구역' in m)
            skip_parts = []
            if inactive_cnt:
                skip_parts.append(f'비활성 {inactive_cnt}건')
            if no_area_cnt:
                skip_parts.append(f'구역미등록 {no_area_cnt}건')
            if skip_parts:
                message += ' (건너뜀: ' + ', '.join(skip_parts) + ')'
        
        return jsonify({
            'success': True,
            'message': message,
            'data': results
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'스케줄 생성 중 오류가 발생했습니다: {str(e)}'
        }), 500


@bp.route("/task_delete", methods=['POST'])
@admin_required
def task_delete():
    """작업 소프트 삭제"""
    task_id = request.form.get('taskId', type=int)
    
    res = conn.execute_return('set_task_delete', [task_id])
    
    return jsonify({
        'success': True,
        'message': '작업이 삭제되었습니다.',
        'data': res
    })


@bp.route("/task_insert", methods=['POST'])
@admin_required
def task_insert():
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
    
    service_started_at = request.form.get('serviceStartedAt') or None
    service_ended_at = request.form.get('serviceEndedAt') or None
    use_yn = 1 if request.form.get('useYn') else 0
    
    days_of_week = days_of_week if days_of_week else None
    
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


@bp.route("/task_area_list", methods=['GET'])
@admin_required
def task_area_list():
    """구역 목록 페이지"""
    task_id = request.args.get('task_id', type=int)
    task_kind_id = request.args.get('task_kind_id', type=int)
    
    if not task_id:
        return redirect(url_for('tasks.task_list', task_kind_id=task_kind_id))
    
    # 스케줄(task) 정보 조회
    task_info_list = conn.return_list('get_task_list', [task_kind_id])
    task_info = None
    for t in task_info_list:
        if t['task_id'] == task_id:
            task_info = t
            break
    
    if not task_info:
        return redirect(url_for('tasks.task_list', task_kind_id=task_kind_id))
    
    # 구역 목록 조회
    areas = conn.return_list('get_task_area_list', [task_id])
    
    return render_template('tasks/task_area_list.html',
                           task_info=task_info,
                           areas=areas,
                           task_id=task_id,
                           task_kind_id=task_kind_id)


@bp.route("/task_area_insert", methods=['POST'])
@admin_required
def task_area_insert():
    """구역 등록 API"""
    task_id = request.form.get('taskId', type=int)
    task_kind_id = request.form.get('taskKindId', type=int)
    floor = request.form.get('floor', '')
    area = request.form.get('area', '')
    check_points = request.form.get('checkPoints', '')
    min_photo_cnt = request.form.get('minPhotoCnt', 0, type=int)
    use_yn = 1 if request.form.get('useYn') else 0
    
    res = conn.execute_return('set_task_area_insert', [
        task_id, floor, area, check_points, min_photo_cnt, use_yn
    ])
    
    return jsonify({
        'success': True,
        'message': '구역이 등록되었습니다.',
        'data': res
    })


@bp.route("/task_area_update", methods=['POST'])
@admin_required
def task_area_update():
    """구역 수정 API"""
    task_area_id = request.form.get('taskAreaId', type=int)
    task_kind_id = request.form.get('taskKindId', type=int)
    floor = request.form.get('floor', '')
    area = request.form.get('area', '')
    check_points = request.form.get('checkPoints', '')
    min_photo_cnt = request.form.get('minPhotoCnt', 0, type=int)
    use_yn = 1 if request.form.get('useYn') else 0
    
    res = conn.execute_return('set_task_area_update', [
        task_area_id, floor, area, check_points, min_photo_cnt, use_yn
    ])
    
    return jsonify({
        'success': True,
        'message': '구역이 수정되었습니다.',
        'data': res
    })
    


@bp.route("/task_my_list/<int:task_kind_id>", methods=['GET'])
@login_required
def task_my_list(task_kind_id):
    """내 업무 목록"""
    user_kind_id = session['login_user']['user_kind_id']
    user_id = session['login_user']['user_id']
    year_month = request.args.get('year_month', datetime.now().strftime('%Y-%m'))
    
    # 관리자는 직원 선택 가능
    workers = []
    if user_kind_id == 1:
        workers = conn.return_list('get_workers_list', []) or []
        selected_user_id = request.args.get('user_id', 0, type=int)
        if selected_user_id:
            user_id = selected_user_id
    else:
        selected_user_id = user_id
    
    schedules = conn.return_list('get_task_my_list', [user_id, year_month])
    
    from datetime import timedelta
    today = datetime.now().strftime('%Y-%m-%d')
    tomorrow = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d')
    total_count = len(schedules)
    completed_count = sum(1 for s in schedules if s.get('schedule_status') == 'completed')
    in_progress_count = sum(1 for s in schedules if s.get('schedule_status') != 'completed' and s.get('completed_area_count', 0) > 0)
    pending_count = sum(1 for s in schedules if s.get('schedule_status') in ('scheduled', 'today') and s.get('effective_date', '') >= today)
    
    return render_template('tasks/task_my_list.html',
        schedules=schedules,
        year_month=year_month,
        today=today,
        tomorrow=tomorrow,
        total_count=total_count,
        completed_count=completed_count,
        in_progress_count=in_progress_count,
        pending_count=pending_count,
        workers=workers,
        selected_user_id=selected_user_id, 
        task_kind_id=task_kind_id
    )


@bp.route("/task_detail/<int:task_schedule_id>/<int:task_kind_id>", methods=['GET'])
@login_required
def task_detail(task_schedule_id, task_kind_id):
    """업무 상세 (업무보고)"""
    
    schedule = conn.execute_return('get_task_detail', [task_schedule_id])
    areas = conn.return_list('get_task_detail_areas', [task_schedule_id])
    
    # 각 구역의 사진 목록 조회
    has_any_work = False
    for area in areas:
        if area.get('task_area_log_id'):
            area['photos'] = conn.return_list('get_task_area_photos', [area['task_area_log_id']])
        else:
            area['photos'] = []
        # 사진이 있거나 특이사항이 있으면 작업중
        if area.get('photo_count') or area.get('log_content'):
            has_any_work = True
    
    return render_template('tasks/task_detail.html',
        schedule=schedule,
        areas=areas,
        task_kind_id=task_kind_id,
        has_any_work=has_any_work
    )


@bp.route("/task_detail_view/<int:task_schedule_id>/<int:task_kind_id>", methods=['GET'])
@login_required
def task_detail_view(task_schedule_id, task_kind_id):
    """업무 상세 보기 (읽기 전용)"""
    
    schedule = conn.execute_return('get_task_detail', [task_schedule_id])
    areas = conn.return_list('get_task_detail_areas', [task_schedule_id])
    
    for area in areas:
        if area.get('task_area_log_id'):
            area['photos'] = conn.return_list('get_task_area_photos', [area['task_area_log_id']])
        else:
            area['photos'] = []
    
    return render_template('tasks/task_detail_view.html',
        schedule=schedule,
        areas=areas,
        task_kind_id=task_kind_id
    )


@bp.route("/task_area_log_save", methods=['POST'])
@login_required
def task_area_log_save():
    """구역별 업무 로그 저장"""
    task_area_id = request.form.get('taskAreaId', type=int)
    task_schedule_id = request.form.get('taskScheduleId', type=int)
    content = request.form.get('content', '')
    
    res = conn.execute_return('set_task_area_log', [task_area_id, task_schedule_id, content])
    log_id = res.get('return_value', 0) if res else 0
    
    return jsonify({
        'success': log_id > 0,
        'message': '저장되었습니다.' if log_id > 0 else '저장에 실패했습니다.',
        'task_area_log_id': log_id
    })


@bp.route("/task_area_photo_upload", methods=['POST'])
@login_required
def task_area_photo_upload():
    """구역 사진 업로드 (여러 장, 이미지 경량화)"""
    try:
        task_area_log_id = request.form.get('taskAreaLogId', type=int)
        files = request.files.getlist('photos')
        
        if not task_area_log_id:
            return jsonify({'success': False, 'message': '로그 ID가 없습니다.'}), 400
        
        if not files or all(f.filename == '' for f in files):
            return jsonify({'success': False, 'message': '파일이 없습니다.'}), 400
        
        upload_dir = os.path.join(current_app.static_folder, 'uploads', 'task_photos')
        os.makedirs(upload_dir, exist_ok=True)
        
        MAX_SIZE = (1280, 1280)
        QUALITY = 80
        
        try:
            from PIL import Image
            use_pil = True
        except ImportError:
            use_pil = False
            current_app.logger.warning('Pillow 미설치 - 원본 파일로 저장합니다.')
        
        uploaded = []
        for file in files:
            if file.filename == '':
                continue
            
            unique_name = f"{uuid.uuid4().hex}.jpg"
            file_path = os.path.join(upload_dir, unique_name)
            
            if use_pil:
                try:
                    img = Image.open(file.stream)
                    img = img.convert('RGB')
                    img.thumbnail(MAX_SIZE, Image.LANCZOS)
                    img.save(file_path, 'JPEG', quality=QUALITY, optimize=True)
                except Exception:
                    file.stream.seek(0)
                    file.save(file_path)
            else:
                file.save(file_path)
            
            db_path = f'/static/uploads/task_photos/{unique_name}'
            res = conn.execute_return('set_task_area_photo_insert', [task_area_log_id, db_path])
            photo_id = res.get('return_value', 0) if res else 0
            
            if photo_id > 0:
                uploaded.append({
                    'task_area_photo_id': photo_id,
                    'photo_file_path': db_path
                })
        
        return jsonify({
            'success': len(uploaded) > 0,
            'message': f'{len(uploaded)}장 업로드되었습니다.',
            'photos': uploaded
        })
    except Exception as e:
        current_app.logger.error(f'사진 업로드 오류: {e}', exc_info=True)
        return jsonify({'success': False, 'message': f'서버 오류: {str(e)}'}), 500


@bp.route("/task_area_photo_delete", methods=['POST'])
@login_required
def task_area_photo_delete():
    """구역 사진 삭제"""
    task_area_photo_id = request.form.get('taskAreaPhotoId', type=int)
    
    res = conn.execute_return('set_task_area_photo_delete', [task_area_photo_id])
    
    if res and res.get('return_value', 0) > 0:
        # 실제 파일 삭제 (파일이 없어도 오류 없이 처리)
        file_path = res.get('file_path', '')
        if file_path:
            # /static/uploads/... → static_folder/uploads/...
            relative = file_path.replace('/static/', '', 1)
            full_path = os.path.join(current_app.static_folder, relative)
            try:
                if os.path.exists(full_path):
                    os.remove(full_path)
            except Exception:
                pass
        
        return jsonify({'success': True, 'message': '삭제되었습니다.'})
    else:
        return jsonify({'success': False, 'message': '삭제에 실패했습니다.'}), 400


@bp.route("/task_schedule_complete", methods=['POST'])
@login_required
def task_schedule_complete():
    """업무 완료 처리"""
    task_schedule_id = request.form.get('taskScheduleId', type=int)
    memo = request.form.get('memo', '')
    
    res = conn.execute_return('set_task_schedule_complete', [task_schedule_id, memo])
    
    if res and res.get('return_value', 0) > 0:
        # SMS 예약 발송 (다음 오전 8시)
        try:
            schedule_completion_sms(task_schedule_id, conn)
        except Exception as e:
            current_app.logger.error(f'SMS 예약 실패: {e}')
        
        return jsonify({'success': True, 'message': '업무가 완료 처리되었습니다.'})
    else:
        return jsonify({'success': False, 'message': '이미 완료된 업무이거나 처리에 실패했습니다.'}), 400

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


@bp.route("/task_client_list/<int:task_kind_id>", methods=['GET'])
@login_required
def task_client_list(task_kind_id):
    """작업 결과 확인 (업체/관리자용)"""
    user_kind_id = session['login_user']['user_kind_id']
    
    # 업체담당자는 본인 회사만, 관리자는 전체 (업체 필터 가능)
    if user_kind_id == 3:
        client_id = session['login_user'].get('client_id', 0) or 0
    elif user_kind_id == 1:
        client_id = request.args.get('client_id', 0, type=int)
    else:
        return redirect(url_for('homes.index'))
    
    year_month = request.args.get('year_month', datetime.now().strftime('%Y-%m'))
    page = request.args.get('page', 1, type=int)
    page_size = 15
    
    count_result = conn.execute_return('get_task_client_list_count', [client_id, year_month, task_kind_id])
    total_count = count_result.get('total_count', 0) if count_result else 0
    total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 1
    if page < 1: page = 1
    if page > total_pages: page = total_pages
    
    res_list = conn.return_list('get_task_client_list', [client_id, year_month, page, page_size, task_kind_id])
    
    # 관리자용 업체 목록
    clients = []
    if user_kind_id == 1:
        clients = conn.return_list('get_client_list') or []
    
    return render_template('tasks/task_client_list.html',
        res_list=res_list,
        page=page,
        total_pages=total_pages,
        total_count=total_count,
        year_month=year_month,
        client_id=client_id,
        clients=clients,
        task_kind_id=task_kind_id
    )


@bp.route("/task_schedule_photos/<int:task_schedule_id>", methods=['GET'])
@login_required
def task_schedule_photos(task_schedule_id):
    """스케줄별 전체 사진 조회 (JSON)"""
    photos = conn.return_list('get_task_schedule_photos', [task_schedule_id]) or []
    return jsonify({'photos': photos})


@bp.route("/task_client_result", methods=['GET'])
@login_required
def task_client_result():
    """업무 결과 확인"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/task_client_result.html', task_kind_id=task_kind_id)


@bp.route("/notify", methods=['GET', 'POST'])
@login_required
def notify():
    """업무완료 통보 (업체에 알림)"""
    task_kind_id = request.args.get('task_kind_id', type=int)
    return render_template('tasks/notify.html', task_kind_id=task_kind_id)

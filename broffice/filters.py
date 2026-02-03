import random
from flask import current_app
from datetime import date, datetime, timedelta
from dateutil.relativedelta import relativedelta

# basic filter
# safe: html tag 반영
# striptags: html tag를 벗겨냄
# abs: 절대값
# filesizeformat: 파일사이즈 표기, (True) 인자값을 넣으면 바이너리 파일사이즈로 표기
# replace: 교체
# trim: 공백 제거
# int, float, round
# center(중앙위치), wordwrap(줄바꿈), truncate(...)

# template filter
# {{ today | ymd('%m-%d') }}
# {{ today | ymd('%m-%d') | safe }} html tag를 함께 반영하려면.
# {{ today | ymd('%m-%d') | safe | striptags }} html tag를 다시 해제하려면.
# {{ title | truncate(10) }} 10글자로 제한하려면.

ENDPOINT_ROUTES = {
    'homes.index': {"title": "메인 페이지", "name": "Dashboards"},
    'homes.notice_list': {"title": "공지사항", "name": "Dashboards"},
    'homes.version_history': {"title": "개발이력 안내", "name": "What's New"},
    'admins.user_list': {"title": "사용자 관리", "name": "Admins"},
    'admins.notice_list': {"title": "공지사항 관리", "name": "Admins"},
    'admins.report_list': {"title": "비즈니스 리포트", "name": "EmailReports"},
    'admins.report_modify': {"title": "비즈니스 리포트", "name": "EmailReports"},
    'admins.notice_modify': {"title": "공지사항 관리", "name": "Admins"},
    'accounts.user_update': {"title": "사용자정보 변경", "name": "Users"},
    'tasks.agency_list': {"title": "파트너", "name": "Dashboards"},
    'tasks.agency_map': {"title": "파트너 위치", "name": "Dashboards"},
    'tasks.counsel_agency_list': {"title": "파트너 목록", "name": "Tasks"},
    'tasks.agency_consult_list': {"title": "파트너 상담", "name": "Tasks"},
    'tasks.agency_support_list': {"title": "파트너 지원", "name": "Tasks"},
    'tasks.agency_violation_list': {"title": "파트너 위반", "name": "Tasks"},
    'tasks.consult_list': {"title": "상담", "name": "Tasks"},
    'tasks.consult_modify': {"title": "상담", "name": "Tasks"},
    'tasks.consult_total_list': {"title":"전체채널 상담", "name": "Tasks"},
    'tasks.support_list': {"title": "지원", "name": "Tasks"},
    'tasks.support_modify': {"title": "지원", "name": "Tasks"},
    'tasks.support_total_list': {"title": "전체채널 지원", "name": "Tasks"},
    'tasks.violation_list': {"title": "위반", "name": "Tasks"},
    'tasks.violation_modify': {"title": "위반", "name": "Tasks"},
    'tasks.violation_total_list': {"title": "전체채널 위반", "name": "Tasks"},
}

def init_app(app):
    """필터를 애플리케이션에 등록"""
    app.template_filter('datetime_str')(datetime_str)
    app.template_filter('new_image_url')(new_image_url)
    app.template_filter('virtual_path')(virtual_path)
    app.template_filter('image_file_yn')(image_file_yn)
    app.template_filter('endpoint_info')(endpoint_info)
    app.template_filter('number_format')(number_format)


def new_image_url(url):
    new_url = url.replace("/assets/img", "/static/images")
    return new_url


def virtual_path(path):
    new_path = path.replace(current_app.config['UPLOAD_FOLDER'], "/virtual_path").replace("\\", "/")
    # new_path = path.replace("/DailyTuntun", "/virtual_path")
    return new_path


def image_file_yn(file_path):
    image_file_format = ["jpg", "jpeg", "png", "JPG", "JPEG", "PNG"]

    r_idx = file_path.rindex('.')
    if r_idx == -1:
        res = False
    else:
        file_format = file_path[r_idx+1:]
        res = True if file_format in image_file_format else False
    return res


def endpoint_info(endpoint, type):
    val = "미정"
    if type == 'title':
        val = ENDPOINT_ROUTES.get(endpoint, {"title": "미정"})["title"]
    elif type == 'name':
        val = ENDPOINT_ROUTES.get(endpoint, {"name": "미정"})["name"]
    return val


def datetime_str(dt, fmt='date'):
    if isinstance(dt, date):
        if fmt=='time': 
            return "%s" % dt.strftime('%H:%M')
        elif fmt=='month':
            return dt.strftime('%Y-%m')
        else:  
            if dt.date() == date.today():
                return "%s" % dt.strftime('%H:%M')
            else:
                return "%s" % dt.strftime('%Y-%m-%d')
    else:
        return dt


def number_format(value):
    try:
        num = float(value)
        if num.is_integer():
            return "{:,}".format(int(num))
        return "{:,}".format(num)
    except (ValueError, TypeError):
        return value
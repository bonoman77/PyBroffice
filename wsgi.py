import sys
import os

# 프로젝트 경로 추가
# PythonAnywhere에서는 /home/Broffice/manage_site 경로를 사용합니다
project_home = os.path.dirname(os.path.abspath(__file__))
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# .env 파일 로드 (PythonAnywhere에서도 사용)
from dotenv import load_dotenv
load_dotenv(os.path.join(project_home, '.env'))

# Flask 앱 임포트
from broffice import create_app

# WSGI application (PythonAnywhere가 이 변수를 찾습니다)
application = create_app()

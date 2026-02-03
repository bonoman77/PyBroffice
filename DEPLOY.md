# PythonAnywhere 배포 가이드

## 1. 파일 업로드

### Git을 사용하는 경우 (권장)
```bash
# PythonAnywhere Bash 콘솔에서
cd ~
git clone https://github.com/yourusername/Broffice.git manage_site
cd manage_site
```

### 직접 업로드하는 경우
PythonAnywhere Files 탭에서 프로젝트 파일들을 `/home/Broffice/manage_site` 경로에 업로드

## 2. 가상환경 설정

PythonAnywhere Bash 콘솔에서:

```bash
cd ~/manage_site
python3.10 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

## 3. 환경 변수 설정

```bash
cd ~/manage_site
cp .env.pythonanywhere .env
nano .env
```

`.env` 파일 수정:
```bash
DB_ENV=production
PROD_DB_HOST=Broffice.mysql.pythonanywhere-services.com
PROD_DB_PORT=3306
PROD_DB_USER=Broffice
PROD_DB_PASSWORD=실제MySQL비밀번호입력
PROD_DB_NAME=Broffice$brobiz
SECRET_KEY=랜덤한긴문자열생성
```

## 4. Web 앱 설정

### 4.1 Web 탭에서 새 웹앱 생성
- **Add a new web app** 클릭
- **Manual configuration** 선택
- **Python 3.10** 선택

### 4.2 WSGI 설정 파일 수정

Web 탭의 **Code** 섹션에서 WSGI configuration file 링크 클릭 후 내용을 다음으로 **완전히 교체**:

```python
import sys
import os

# 프로젝트 경로 추가
project_home = '/home/Broffice/manage_site'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# 가상환경 활성화
activate_this = '/home/Broffice/manage_site/venv/bin/activate_this.py'
if os.path.exists(activate_this):
    with open(activate_this) as f:
        exec(f.read(), {'__file__': activate_this})

# .env 파일 로드
from dotenv import load_dotenv
load_dotenv(os.path.join(project_home, '.env'))

# Flask 앱 임포트
from broffice import create_app

# WSGI application
application = create_app()
```

### 4.3 가상환경 경로 설정

Web 탭의 **Virtualenv** 섹션에서:
```
/home/Broffice/manage_site/venv
```

### 4.4 정적 파일 설정

Web 탭의 **Static files** 섹션에서:

| URL | Directory |
|-----|-----------|
| /static/ | /home/Broffice/manage_site/broffice/static/ |

## 5. 데이터베이스 설정 확인

### 5.1 MySQL 데이터베이스 생성 확인
- **Databases** 탭에서 `Broffice$brobiz` 데이터베이스가 있는지 확인
- 없으면 생성

### 5.2 데이터베이스 비밀번호 확인
- **Databases** 탭에서 MySQL password 확인
- `.env` 파일의 `PROD_DB_PASSWORD`와 일치하는지 확인

## 6. 배포 완료

Web 탭에서:
1. **Reload** 버튼 클릭
2. 웹사이트 URL 클릭하여 접속 확인: `https://broffice.pythonanywhere.com`

## 7. 로그 확인

문제가 발생하면 Web 탭의 **Log files** 섹션에서:
- **Error log**: 에러 확인
- **Server log**: 서버 로그 확인

## 8. 업데이트 방법

코드 수정 후:

```bash
# Git 사용 시
cd ~/manage_site
git pull origin main

# 직접 업로드 시
# Files 탭에서 파일 업로드
```

그 다음 Web 탭에서 **Reload** 버튼 클릭

## 주의사항

1. **로컬 개발 vs 프로덕션**
   - 로컬: `DB_ENV=local` 또는 `DB_ENV=remote` (SSH 터널)
   - PythonAnywhere: `DB_ENV=production` (직접 연결)

2. **SECRET_KEY**
   - 프로덕션에서는 반드시 강력한 랜덤 키 사용
   - Python으로 생성: `python -c "import secrets; print(secrets.token_hex(32))"`

3. **디버그 모드**
   - 프로덕션에서는 `FLASK_ENV=production` 필수
   - 절대 `debug=True` 사용 금지

4. **정적 파일**
   - CSS/JS 변경 시 브라우저 캐시 삭제 필요
   - 또는 파일명에 버전 추가

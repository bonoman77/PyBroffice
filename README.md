# Broffice

브로피스 관리 시스템

## 로컬 개발 환경 설정

1. 가상환경 생성 및 활성화
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
```

2. 패키지 설치
```bash
pip install -r requirements.txt
```

3. 환경 변수 설정
`.env.example`을 복사하여 `.env` 파일 생성 후 설정값 입력

4. 실행
```bash
python start_broffice.py
```

## PythonAnywhere 배포

### 1. 파일 업로드
- Git을 통해 클론하거나 파일 직접 업로드
- 제외할 파일: `venv/`, `web.config`, `wfastcgi.py`, `*.bat`

### 2. 가상환경 설정
```bash
mkvirtualenv --python=/usr/bin/python3.10 broffice
pip install -r requirements.txt
```

### 3. 환경 변수 설정
PythonAnywhere 웹 탭 > Environment variables에 추가:
```
FLASK_ENV=pythonanywhere
session_secret_key=your-secret-key
DB_HOST=yourusername.mysql.pythonanywhere-services.com
DB_NAME=yourusername$broffice
db_user=yourusername
db_password=your-db-password
email_user=your-email
email_password=your-email-password
```

### 4. WSGI 설정
Web 탭 > Code > WSGI configuration file에서 `wsgi.py` 내용 복사

### 5. Static files 매핑
- URL: `/static/`
- Directory: `/home/yourusername/Broffice/broffice/static/`

### 6. 데이터베이스 설정
- MySQL 데이터베이스 생성
- `database/broffice_mysql_ddl.sql` 실행
- `database/broffice_mysql_procedures.sql` 실행

### 7. 업로드 폴더 생성
```bash
mkdir -p ~/uploads/Broffice
```

## 프로젝트 구조

```
Broffice/
├── broffice/              # 메인 애플리케이션
│   ├── router/           # 라우터 (블루프린트)
│   ├── templates/        # HTML 템플릿
│   ├── static/           # 정적 파일
│   ├── utils/            # 유틸리티
│   ├── config.py         # 설정
│   └── __init__.py       # 앱 팩토리
├── database/             # 데이터베이스 스크립트
├── logs/                 # 로그 파일
├── requirements.txt      # 의존성 패키지
├── start_broffice.py     # 로컬 실행 파일
└── wsgi.py              # PythonAnywhere WSGI 파일
```

## 환경별 설정

- **development**: 로컬 개발 환경
- **production**: Windows 서버 운영 환경
- **pythonanywhere**: PythonAnywhere 배포 환경

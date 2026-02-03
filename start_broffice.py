# import os 
# os.environ['FLASK_ENV'] = 'production'

# 원격 테스트 환경 (SSH 터널 사용)
# 사전에 SSH 터널을 열어야 함:
# ssh -L 3307:Broffice.mysql.pythonanywhere-services.com:3306 Broffice@ssh.pythonanywhere.com -N


# from절을 호출하는 순간 해당 프로젝트의 __init__은 자동실행
from broffice import create_app

app = create_app()

if __name__ == "__main__":
    app.run(host='127.0.0.1', port=5020)

import os
import random
from datetime import datetime
from flask import current_app, send_file, request, abort
from werkzeug.utils import secure_filename
from io import BytesIO
from xlsxwriter import Workbook


def file_download():
    """파일 다운로드 - 보안 강화"""
    file_path = request.args.get("file_path")
    file_name = request.args.get("file_name")
    download_yn = bool(int(request.args.get("download_yn", 0)))
    
    # 보안: 절대 경로 검증
    if not file_path or not file_name:
        abort(400, "파일 경로 또는 이름이 없습니다.")
    
    # 경로 순회 공격 방지
    safe_path = os.path.abspath(os.path.join(file_path, file_name))
    base_path = os.path.abspath(file_path)
    
    if not safe_path.startswith(base_path):
        abort(403, "잘못된 파일 경로입니다.")
    
    if not os.path.exists(safe_path):
        abort(404, "파일을 찾을 수 없습니다.")
    
    return send_file(safe_path, as_attachment=download_yn)


def file_format_check(file_name):
    """파일 확장자 검증"""
    if '.' not in file_name:
        return False

    extension = file_name.rsplit('.', 1)[-1].lower()
    return extension in current_app.config['UPLOAD_EXTENSIONS']


def excel_export_handle(excel_data):
    """엑셀 파일 생성"""
    output = BytesIO()
    workbook = Workbook(output)
    worksheet = workbook.add_worksheet()

    for row_num, row_data in enumerate(excel_data):
        for col_num, col_data in enumerate(row_data):
            worksheet.write(row_num, col_num, col_data)

    workbook.close()
    output.seek(0)

    return output


class FileHandler:
    def __init__(self, upload_path):
        self.upload_path = os.path.abspath(upload_path)

    def file_upload(self, upload_files):
        """파일 업로드 처리"""
        file_name_list = []

        try:
            if not os.path.exists(self.upload_path):
                os.makedirs(self.upload_path, exist_ok=True)
        except OSError as e:
            raise Exception(f"업로드 디렉토리 생성 실패: {e}")

        for upload_file in upload_files:
            if upload_file.filename == '':
                continue
                
            if not file_format_check(upload_file.filename):
                continue
            
            try:
                # 안전한 파일명 생성
                safe_name = self._sanitize_filename(upload_file.filename)
                unique_file_name = self.file_duplicate_handle(safe_name)
                file_path = os.path.join(self.upload_path, unique_file_name)
                
                upload_file.save(file_path)
                file_name_list.append(unique_file_name)
            except Exception as e:
                # 개별 파일 업로드 실패 시 계속 진행
                current_app.logger.error(f"파일 업로드 실패 ({upload_file.filename}): {e}")
                continue

        return "||".join(file_name_list)

    def _sanitize_filename(self, filename):
        """파일명 안전하게 정리"""
        # 위험한 문자 제거
        dangerous_chars = ['..', '/', '\\', '\0', '\n', '\r']
        safe_name = filename
        for char in dangerous_chars:
            safe_name = safe_name.replace(char, '')
        
        # 공백을 언더스코어로 변경
        safe_name = safe_name.replace(' ', '_')
        
        return safe_name

    def file_duplicate_handle(self, file_name):
        """파일명 중복 처리 - 타임스탬프 기반"""
        original_name, extension = os.path.splitext(file_name)
        unique_file_name = file_name
        
        # 파일이 존재하면 타임스탬프 추가
        if os.path.exists(os.path.join(self.upload_path, unique_file_name)):
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_file_name = f"{original_name}_{timestamp}{extension}"
            
            # 여전히 존재하면 랜덤 문자 추가
            if os.path.exists(os.path.join(self.upload_path, unique_file_name)):
                random_suffix = ''.join(random.choices('abcdefghijklmnopqrstuvwxyz0123456789', k=4))
                unique_file_name = f"{original_name}_{timestamp}_{random_suffix}{extension}"

        return unique_file_name


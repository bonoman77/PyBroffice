-- MySQL DDL (converted from SQL Server 2008 ERD)
-- Database: Broffice$brobiz
-- Generated: 2026-02-10

USE Broffice$brobiz;

-- 외래키 체크 임시 비활성화
SET FOREIGN_KEY_CHECKS = 0;

-- 기존 테이블 삭제 (역순)
DROP TABLE IF EXISTS task_sns_logs;
DROP TABLE IF EXISTS task_area_photos;
DROP TABLE IF EXISTS task_area_logs;
DROP TABLE IF EXISTS task_areas;
DROP TABLE IF EXISTS task_schedules;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS user_login_logs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS commons;
DROP TABLE IF EXISTS notices;
DROP TABLE IF EXISTS clients;

-- ============================================================
-- TABLE: clients (고객사)
-- ============================================================
CREATE TABLE clients (
    client_id             INT NOT NULL AUTO_INCREMENT COMMENT '고객사ID',
    client_name           VARCHAR(100) NOT NULL COMMENT '고객사명',
    client_phone          VARCHAR(100) NULL COMMENT '업체 연락처',
    client_address        VARCHAR(300) NOT NULL COMMENT '고객사주소',
    client_business       VARCHAR(30) NULL COMMENT '사업자등록번호',
    manager_name          VARCHAR(100) NOT NULL COMMENT '관리자명',
    manager_position      VARCHAR(30) NULL COMMENT '관리자직급',
    manager_mobile        VARCHAR(100) NOT NULL COMMENT '관리자연락처',
    cleaning_yn           TINYINT(1) DEFAULT 0 NOT NULL COMMENT '청소여부',
    snack_yn              TINYINT(1) DEFAULT 0 NOT NULL COMMENT '간식여부',
    office_supplies_yn    TINYINT(1) DEFAULT 0 NOT NULL COMMENT '비품여부',
    memo                  VARCHAR(500) NOT NULL DEFAULT '' COMMENT '한글멘트',
	use_yn				  TINYINT(1) DEFAULT 0 NOT NULL COMMENT '사용여부',
    contracted_at         DATETIME NULL COMMENT '계약일',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    deleted_at            DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (client_id),
    INDEX idx_clients_deleted_at (deleted_at),
    INDEX idx_clients_use_yn (use_yn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='clients 고객사';

-- ============================================================
-- TABLE: commons (공통코드관리)
-- ============================================================
CREATE TABLE commons (
    id                    INT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    parent_id             INT NULL COMMENT '부모ID',
    separate              VARCHAR(50) NOT NULL COMMENT '분류',
    item                  VARCHAR(50) NOT NULL COMMENT '명칭',
    use_yn                TINYINT(1) DEFAULT 0 NOT NULL COMMENT '사용여부',
    order_num             TINYINT DEFAULT 0 NOT NULL COMMENT '순서',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    PRIMARY KEY (id),
    INDEX idx_commons_parent_id (parent_id),
    INDEX idx_commons_separate (separate)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='commons 공통코드관리';

-- Self FK
ALTER TABLE commons
    ADD CONSTRAINT fk_commons_commons
    FOREIGN KEY (parent_id) REFERENCES commons(id);

-- ============================================================
-- TABLE: notices (공지사항)
-- ============================================================
CREATE TABLE notices (
    notice_id             INT NOT NULL AUTO_INCREMENT COMMENT '공지사항ID',
    user_id               INT NOT NULL COMMENT '사용자ID',
    content               TEXT NOT NULL COMMENT '내용',
    display_yn            TINYINT(1) DEFAULT 0 NOT NULL COMMENT '게시여부',
    top_expose_yn         TINYINT(1) DEFAULT 0 NOT NULL COMMENT '상단노출여부',
    target_user_kind_id   INT DEFAULT 0 NOT NULL COMMENT '대상자유형ID',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    deleted_at            DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (notice_id),
    INDEX idx_notices_user_id (user_id),
    INDEX idx_notices_display_yn (display_yn),
    INDEX idx_notices_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='notices 공지사항';

-- ============================================================
-- TABLE: task_area_logs (업무세부결과)
-- ============================================================
CREATE TABLE task_area_logs (
    task_area_log_id      INT NOT NULL AUTO_INCREMENT COMMENT '업무세부결과ID',
    task_area_id          INT NOT NULL COMMENT '업무구역ID',
    task_log_id           INT NOT NULL COMMENT '업무결과ID',
    content               VARCHAR(500) NULL COMMENT '특이사항',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    PRIMARY KEY (task_area_log_id),
    INDEX idx_task_area_logs_task_area_id (task_area_id),
    INDEX idx_task_area_logs_task_log_id (task_log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_area_logs 업무세부결과';

-- ============================================================
-- TABLE: task_area_photos (업무세부사진)
-- ============================================================
CREATE TABLE task_area_photos (
    task_area_photo_id    INT NOT NULL AUTO_INCREMENT COMMENT '업무세부사진ID',
    task_area_log_id      INT NOT NULL COMMENT '업무세부결과ID',
    photo_file_path       VARCHAR(500) NOT NULL COMMENT '사진파일경로',
    PRIMARY KEY (task_area_photo_id),
    INDEX idx_task_area_photos_task_area_log_id (task_area_log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_area_photos 업무세부사진';

-- ============================================================
-- TABLE: task_areas (업무구역)
-- ============================================================
CREATE TABLE task_areas (
    task_area_id          INT NOT NULL AUTO_INCREMENT COMMENT '업무구역ID',
    task_id               INT NOT NULL COMMENT '업무관리ID',
    floor                 VARCHAR(10) NOT NULL COMMENT '층',
    area                  VARCHAR(30) NOT NULL COMMENT '구역',
    check_points          VARCHAR(300) NOT NULL COMMENT '업무포인트',
    min_photo_cnt         INT DEFAULT 0 NOT NULL COMMENT '최소사진수량',
	use_yn				  TINYINT(1) DEFAULT 0 NOT NULL COMMENT '사용여부',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    deleted_at            DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (task_area_id),
    INDEX idx_task_areas_task_id (task_id),
    INDEX idx_task_areas_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_areas 업무구역';

-- ============================================================
-- TABLE: task_schedules (업무일정)
-- ============================================================
CREATE TABLE task_schedules (
    task_log_id           INT NOT NULL AUTO_INCREMENT COMMENT '업무결과ID',
    task_id               INT NOT NULL COMMENT '업무관리ID',
    user_id               INT NOT NULL COMMENT '작업자ID',
    memo                  VARCHAR(500) NULL COMMENT '메모',
    scheduled_at          DATETIME NOT NULL COMMENT '생성일정',
    change_scheduled_at   DATETIME NULL COMMENT '변경일정',
    completed_at          DATETIME NULL COMMENT '작업완료일',
    canceled_at           TINYINT(1) DEFAULT 0 NOT NULL COMMENT '작업취소일',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    PRIMARY KEY (task_log_id),
    INDEX idx_task_schedules_task_id (task_id),
    INDEX idx_task_schedules_user_id (user_id),
    INDEX idx_task_schedules_scheduled_at (scheduled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_schedules 업무일정';

-- ============================================================
-- TABLE: task_sns_logs (업무알림결과)
-- ============================================================
CREATE TABLE task_sns_logs (
    task_sns_log_id       INT NOT NULL AUTO_INCREMENT COMMENT '업무알림결과ID',
    user_id               INT NOT NULL COMMENT '사용자ID',
    task_log_id           INT NOT NULL COMMENT '업무결과ID',
    from_mobile           VARCHAR(100) NOT NULL COMMENT '발신전화번호',
    to_mobile             VARCHAR(100) NOT NULL COMMENT '수신전화번호',
    content               VARCHAR(500) NOT NULL COMMENT '메시지내용',
    scheduled_send_at     DATETIME NOT NULL COMMENT '발신예약시간',
    sent_at               DATETIME NULL COMMENT '실제발송시간',
    send_status           VARCHAR(100) NOT NULL COMMENT '전송상태',
    twilio_sid            VARCHAR(100) NOT NULL COMMENT 'TwilioSID',
    twilio_status         VARCHAR(100) NOT NULL COMMENT 'Twilio전송상태',
    twilio_error_code     VARCHAR(100) NULL COMMENT 'Twilio에러코드',
    twilio_error_message  VARCHAR(100) NULL COMMENT 'Twilio에러메시지',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    PRIMARY KEY (task_sns_log_id),
    INDEX idx_task_sns_logs_user_id (user_id),
    INDEX idx_task_sns_logs_task_log_id (task_log_id),
    INDEX idx_task_sns_logs_send_status (send_status),
    INDEX idx_task_sns_logs_scheduled_send_at (scheduled_send_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_sns_logs 업무알림결과';

-- ============================================================
-- TABLE: tasks (업무관리)
-- ============================================================
CREATE TABLE tasks (
    task_id               INT NOT NULL AUTO_INCREMENT COMMENT '업무관리ID',
    client_id             INT NOT NULL COMMENT '고객사ID',
    user_id               INT NOT NULL COMMENT '사용자ID',
    task_kind_id          INT DEFAULT 0 NOT NULL COMMENT '업무종류ID',
    schedule_type         VARCHAR(10) NOT NULL COMMENT '스케줄타입',
    days_of_week          INT DEFAULT 0 NOT NULL COMMENT '요일',
	use_yn				  TINYINT(1) DEFAULT 0 NOT NULL COMMENT '사용여부',
    service_started_at    DATETIME NOT NULL COMMENT '관리시작일',
    service_ended_at      DATETIME NULL COMMENT '관리종료일',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    deleted_at            DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (task_id),
    INDEX idx_tasks_client_id (client_id),
    INDEX idx_tasks_user_id (user_id),
    INDEX idx_tasks_task_kind_id (task_kind_id),
    INDEX idx_tasks_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='tasks 업무관리';

-- ============================================================
-- TABLE: user_login_logs (로그인기록)
-- ============================================================
CREATE TABLE user_login_logs (
    login_log_id          INT NOT NULL AUTO_INCREMENT COMMENT '로그인로그ID',
    user_id               INT NOT NULL COMMENT '사용자ID',
    login_at              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '로그인시간',
    PRIMARY KEY (login_log_id),
    INDEX idx_user_login_logs_user_id (user_id),
    INDEX idx_user_login_logs_login_at (login_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='user_login_logs 로그인기록';

-- ============================================================
-- TABLE: users (사용자)
-- ============================================================
CREATE TABLE users (
    user_id               INT NOT NULL AUTO_INCREMENT COMMENT '사용자ID',
    user_name             VARCHAR(100) NOT NULL COMMENT '사용자명',
    user_kind_id          INT DEFAULT 0 NOT NULL COMMENT '사용자종류ID',
    user_email            VARCHAR(100) NOT NULL COMMENT '사용자이메일',
    user_passwd           BINARY(64) NOT NULL COMMENT '사용자비밀번호',
    user_mobile           VARCHAR(100) NOT NULL COMMENT '사용자연락처',
    client_id             INT NULL COMMENT '고객사ID',
    auth_code             VARCHAR(100) NULL COMMENT '인증코드',
    admin_auth_user_id    INT DEFAULT 0 NULL COMMENT '관리자인증자',
	use_yn				  TINYINT(1) DEFAULT 0 NOT NULL COMMENT '사용여부',
    admin_authed_at       DATETIME NULL COMMENT '관리자인증일',
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at            DATETIME NULL COMMENT '수정일',
    deleted_at            DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (user_id),
    INDEX idx_users_user_email (user_email),
    INDEX idx_users_user_kind_id (user_kind_id),
    INDEX idx_users_client_id (client_id),
    INDEX idx_users_deleted_at (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='users 사용자';

-- ============================================================
-- FOREIGN KEY CONSTRAINTS
-- ============================================================

-- notices FK
ALTER TABLE notices
    ADD CONSTRAINT fk_users_notices
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- task_area_logs FKs
ALTER TABLE task_area_logs
    ADD CONSTRAINT fk_task_areas_task_area_logs
    FOREIGN KEY (task_area_id) REFERENCES task_areas(task_area_id);

ALTER TABLE task_area_logs
    ADD CONSTRAINT fk_task_schedules_task_area_logs
    FOREIGN KEY (task_log_id) REFERENCES task_schedules(task_log_id);

-- task_area_photos FK
ALTER TABLE task_area_photos
    ADD CONSTRAINT fk_task_area_logs_task_area_photos
    FOREIGN KEY (task_area_log_id) REFERENCES task_area_logs(task_area_log_id);

-- task_areas FK
ALTER TABLE task_areas
    ADD CONSTRAINT fk_tasks_task_areas
    FOREIGN KEY (task_id) REFERENCES tasks(task_id);

-- task_schedules FKs
ALTER TABLE task_schedules
    ADD CONSTRAINT fk_tasks_task_schedules
    FOREIGN KEY (task_id) REFERENCES tasks(task_id);

ALTER TABLE task_schedules
    ADD CONSTRAINT fk_users_task_schedules
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- task_sns_logs FKs
ALTER TABLE task_sns_logs
    ADD CONSTRAINT fk_task_schedules_task_sns_logs
    FOREIGN KEY (task_log_id) REFERENCES task_schedules(task_log_id);

ALTER TABLE task_sns_logs
    ADD CONSTRAINT fk_users_task_sns_logs
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- tasks FKs
ALTER TABLE tasks
    ADD CONSTRAINT fk_clients_tasks
    FOREIGN KEY (client_id) REFERENCES clients(client_id);

ALTER TABLE tasks
    ADD CONSTRAINT fk_users_tasks
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- user_login_logs FK
ALTER TABLE user_login_logs
    ADD CONSTRAINT fk_users_user_login_logs
    FOREIGN KEY (user_id) REFERENCES users(user_id);

-- users FK
ALTER TABLE users
    ADD CONSTRAINT fk_clients_users
    FOREIGN KEY (client_id) REFERENCES clients(client_id);

-- ============================================================
-- 초기 데이터: commons (공통코드)
-- ============================================================
-- UserKind
INSERT INTO commons (id, parent_id, separate, item, use_yn, order_num) VALUES
(1, NULL, 'user_kind', 'admin', 1, 1),
(2, NULL, 'user_kind', 'staff', 1, 2),
(3, NULL, 'user_kind', 'client', 1, 3);

-- TaskKind
INSERT INTO commons (id, parent_id, separate, item, use_yn, order_num) VALUES
(4, NULL, 'task_kind', 'cleaning', 1, 1),
(5, NULL, 'task_kind', 'snack', 1, 2),
(6, NULL, 'task_kind', 'office_supplies', 1, 3);

-- 외래키 체크 재활성화
SET FOREIGN_KEY_CHECKS = 1;

-- 완료 메시지
SELECT 'MySQL DDL 스크립트 실행 완료' AS message;

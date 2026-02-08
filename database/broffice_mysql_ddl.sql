-- MySQL DDL (converted from SQL Server 2008)
-- Database: broffice
-- Generated: 2026-01-26

USE brobiz;

-- 외래키 체크 임시 비활성화
SET FOREIGN_KEY_CHECKS = 0;

-- 기존 테이블 삭제 (역순)
DROP TABLE IF EXISTS task_sns_logs;
DROP TABLE IF EXISTS task_area_photos;
DROP TABLE IF EXISTS task_area_logs;
DROP TABLE IF EXISTS task_areas;
DROP TABLE IF EXISTS task_logs;
DROP TABLE IF EXISTS task_schedules;
DROP TABLE IF EXISTS task_sets;
DROP TABLE IF EXISTS user_login_logs;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS commons;
DROP TABLE IF EXISTS notices;
DROP TABLE IF EXISTS clients;

-- ============================================================
-- TABLE: clients (고객사)
-- ============================================================
CREATE TABLE clients (
  client_id         INT NOT NULL AUTO_INCREMENT COMMENT '고객사ID',
  client_name       VARCHAR(100) NOT NULL COMMENT '고객사명',
  manager_name      VARCHAR(100) NOT NULL COMMENT '관리자명',
  management_level  VARCHAR(30) NULL COMMENT '관리자직급',
  manager_mobile    VARCHAR(100) NOT NULL COMMENT '관리자연락처',
  client_address    VARCHAR(300) NOT NULL COMMENT '고객사주소',
  content_to        VARCHAR(500) NULL COMMENT '전달사항',
  memo              VARCHAR(500) NULL COMMENT '메모',
  contracted_at     DATETIME NULL COMMENT '계약일',
  use_yn            TINYINT(1) NOT NULL DEFAULT 1 COMMENT '사용여부',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at        DATETIME NULL COMMENT '수정일',
  deleted_at        DATETIME NULL COMMENT '삭제일',
  PRIMARY KEY (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='clients 고객사';

-- ============================================================
-- TABLE: commons (공통코드관리)
-- ============================================================
CREATE TABLE commons (
  id         INT NOT NULL AUTO_INCREMENT COMMENT 'ID',
  parent_id  INT NULL COMMENT '부모ID',
  separate   VARCHAR(50) NOT NULL COMMENT '분류',
  item       VARCHAR(50) NOT NULL COMMENT '명칭',
  use_yn     TINYINT(1) NOT NULL DEFAULT 0 COMMENT '사용여부',
  order_num  TINYINT NOT NULL DEFAULT 0 COMMENT '순서',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at DATETIME NULL COMMENT '수정일',
  PRIMARY KEY (id),
  KEY idx_commons_parent_id (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='commons 공통코드관리';

-- Self FK
ALTER TABLE commons
  ADD CONSTRAINT fk_commons_commons
  FOREIGN KEY (parent_id) REFERENCES commons(id);

-- ============================================================
-- TABLE: tasks (고객사업무관리)
-- ============================================================
CREATE TABLE tasks (
  task_id             INT NOT NULL AUTO_INCREMENT COMMENT '업무관리ID',
  client_id           INT NOT NULL COMMENT '고객사ID',
  task_kind_id        INT NOT NULL DEFAULT 0 COMMENT '업무종류ID',
  service_started_at  DATETIME NOT NULL COMMENT '관리시작일',
  service_ended_at    DATETIME NULL COMMENT '관리종료일',
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at          DATETIME NULL COMMENT '수정일',
  deleted_at          DATETIME NULL COMMENT '삭제일',
  PRIMARY KEY (task_id),
  KEY idx_tasks_client_id (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='tasks 고객사업무관리';

ALTER TABLE tasks
  ADD CONSTRAINT fk_clients_tasks
  FOREIGN KEY (client_id) REFERENCES clients(client_id);

-- ============================================================
-- TABLE: users (사용자)
-- ============================================================
CREATE TABLE users (
  user_id       INT NOT NULL AUTO_INCREMENT COMMENT '사용자ID',
  user_name     VARCHAR(100) NOT NULL COMMENT '사용자명',
  user_kind_id  INT NOT NULL DEFAULT 0 COMMENT '사용자종류ID',
  user_account  VARCHAR(100) NOT NULL COMMENT '사용자계정',
  user_passwd   VARBINARY(128) NOT NULL COMMENT '사용자비밀번호',
  user_email    VARCHAR(100) NOT NULL COMMENT '사용자이메일',
  user_mobile   VARCHAR(100) NOT NULL COMMENT '사용자연락처',
  client_id     INT NULL COMMENT '고객사ID',
  use_yn        TINYINT(1) NOT NULL DEFAULT 1 COMMENT '사용여부',
  auth_code     VARCHAR(100) NULL COMMENT '인증코드',
  admin_auth_user_id  INT NULL COMMENT '관리자인증자',
  admin_authed_at     DATETIME NULL COMMENT '관리자인증일',
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at    DATETIME NULL COMMENT '수정일',
  deleted_at    DATETIME NULL COMMENT '삭제일',
  PRIMARY KEY (user_id),
  KEY idx_users_client_id (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='users 사용자';

ALTER TABLE users
  ADD CONSTRAINT fk_clients_users
  FOREIGN KEY (client_id) REFERENCES clients(client_id);


-- ============================================================
-- TABLE: notices (공지사항)
-- ============================================================
CREATE TABLE notices (
    notice_id       INT NOT NULL AUTO_INCREMENT COMMENT '공지사항ID',
    user_id   INT NOT NULL COMMENT '사용자ID',
    target_user_kind_id INT NOT NULL DEFAULT 0 COMMENT '대상사용자종류ID (0:전체, 1:관리자, 2:현장직원, 3:업체담당자)',
    content         NVARCHAR(3000) NOT NULL COMMENT '공지사항내용',
    display_yn      TINYINT(1) NOT NULL DEFAULT 0 COMMENT '공지사항노출여부',
    top_expose_yn   TINYINT(1) NOT NULL DEFAULT 0 COMMENT '상단노출여부',
    created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
    updated_at      DATETIME NULL COMMENT '수정일',
    deleted_at      DATETIME NULL COMMENT '삭제일',
    PRIMARY KEY (notice_id),
    KEY idx_notices_user_id (user_id),
    KEY idx_notices_target_user_kind_id (target_user_kind_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='notices 공지사항';

ALTER TABLE notices
  ADD CONSTRAINT fk_users_notices
  FOREIGN KEY (user_id) REFERENCES users(user_id);


-- ============================================================
-- TABLE: user_login_logs (사용자로그인로그)
-- ============================================================
CREATE TABLE user_login_logs (  
  login_log_id  INT NOT NULL AUTO_INCREMENT COMMENT '로그인로그ID',
  user_id       INT NOT NULL COMMENT '사용자ID',
  login_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '로그인시간',
  PRIMARY KEY (login_log_id),
  KEY idx_user_login_logs_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='user_login_logs 사용자로그인로그';

ALTER TABLE user_login_logs
  ADD CONSTRAINT fk_users_user_login_logs
  FOREIGN KEY (user_id) REFERENCES users(user_id);

-- ============================================================
-- TABLE: task_sets (고객사별직원할당)
-- ============================================================
CREATE TABLE task_sets (
  task_set_id  INT NOT NULL AUTO_INCREMENT COMMENT '고객사별직원할당ID',
  user_id      INT NOT NULL COMMENT '사용자ID',
  task_id      INT NOT NULL COMMENT '업무관리ID',
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  PRIMARY KEY (task_set_id),
  KEY idx_task_sets_user_id (user_id),
  KEY idx_task_sets_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_sets 고객사별직원할당';

ALTER TABLE task_sets
  ADD CONSTRAINT fk_users_task_sets
  FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE task_sets
  ADD CONSTRAINT fk_tasks_task_sets
  FOREIGN KEY (task_id) REFERENCES tasks(task_id);

-- ============================================================
-- TABLE: task_schedules (의뢰업무일정)
-- ============================================================
CREATE TABLE task_schedules (
  task_schedule_id  INT NOT NULL AUTO_INCREMENT COMMENT '의뢰업무일정ID',
  task_set_id       INT NOT NULL COMMENT '고객사별직원할당ID',
  task_id           INT NOT NULL COMMENT '업무관리ID',
  day_of_week       TINYINT NOT NULL DEFAULT 0 COMMENT '요일',
  start_time        INT NOT NULL DEFAULT 0 COMMENT '시작시간',
  end_time          INT NOT NULL DEFAULT 0 COMMENT '종료시간',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at        DATETIME NULL COMMENT '수정일',
  deleted_at        DATETIME NULL COMMENT '삭제일',
  PRIMARY KEY (task_schedule_id),
  KEY idx_task_schedules_task_set_id (task_set_id),
  KEY idx_task_schedules_task_id (task_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_schedules 의뢰업무일정';

ALTER TABLE task_schedules
  ADD CONSTRAINT fk_task_sets_task_schedules
  FOREIGN KEY (task_set_id) REFERENCES task_sets(task_set_id);

ALTER TABLE task_schedules
  ADD CONSTRAINT fk_tasks_task_schedules
  FOREIGN KEY (task_id) REFERENCES tasks(task_id);

-- ============================================================
-- TABLE: task_areas (고객사업무구역)
-- ============================================================
CREATE TABLE task_areas (
  task_area_id      INT NOT NULL AUTO_INCREMENT COMMENT '업무구역ID',
  task_schedule_id  INT NOT NULL COMMENT '의뢰업무일정ID',
  floor             VARCHAR(10) NOT NULL COMMENT '층',
  area              VARCHAR(30) NOT NULL COMMENT '구역',
  check_points      VARCHAR(500) NOT NULL COMMENT '업무범위',
  min_photo_cnt     INT NOT NULL DEFAULT 0 COMMENT '최소사진수량',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at        DATETIME NULL COMMENT '수정일',
  deleted_at        DATETIME NULL COMMENT '삭제일',
  PRIMARY KEY (task_area_id),
  KEY idx_task_areas_task_schedule_id (task_schedule_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_areas 고객사업무구역';

ALTER TABLE task_areas
  ADD CONSTRAINT fk_task_schedules_task_areas
  FOREIGN KEY (task_schedule_id) REFERENCES task_schedules(task_schedule_id);

-- ============================================================
-- TABLE: task_logs (업무결과)
-- ============================================================
CREATE TABLE task_logs (
  task_log_id       INT NOT NULL AUTO_INCREMENT COMMENT '업무결과ID',
  task_set_id       INT NOT NULL COMMENT '고객사별직원할당ID',
  task_schedule_id  INT NOT NULL COMMENT '의뢰업무일정ID',
  memo              VARCHAR(500) NULL COMMENT '메모',
  completed_at      DATETIME NOT NULL COMMENT '작업일',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at        DATETIME NULL COMMENT '수정일',
  PRIMARY KEY (task_log_id),
  KEY idx_task_logs_task_set_id (task_set_id),
  KEY idx_task_logs_task_schedule_id (task_schedule_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_logs 업무결과';

ALTER TABLE task_logs
  ADD CONSTRAINT fk_task_sets_task_logs
  FOREIGN KEY (task_set_id) REFERENCES task_sets(task_set_id);

ALTER TABLE task_logs
  ADD CONSTRAINT fk_task_schedules_task_logs
  FOREIGN KEY (task_schedule_id) REFERENCES task_schedules(task_schedule_id);

-- ============================================================
-- TABLE: task_area_logs (업무세부결과)
-- ============================================================
CREATE TABLE task_area_logs (
  task_area_log_id  INT NOT NULL AUTO_INCREMENT COMMENT '업무세부결과ID',
  task_area_id      INT NOT NULL COMMENT '업무구역ID',
  task_log_id       INT NOT NULL COMMENT '업무결과ID',
  content           VARCHAR(500) NULL COMMENT '특이사항',
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  updated_at        DATETIME NULL COMMENT '수정일',
  PRIMARY KEY (task_area_log_id),
  KEY idx_task_area_logs_task_area_id (task_area_id),
  KEY idx_task_area_logs_task_log_id (task_log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_area_logs 업무세부결과';

ALTER TABLE task_area_logs
  ADD CONSTRAINT fk_task_areas_task_area_logs
  FOREIGN KEY (task_area_id) REFERENCES task_areas(task_area_id);

ALTER TABLE task_area_logs
  ADD CONSTRAINT fk_task_logs_task_area_logs
  FOREIGN KEY (task_log_id) REFERENCES task_logs(task_log_id);

-- ============================================================
-- TABLE: task_area_photos (업무세부사진)
-- ============================================================
CREATE TABLE task_area_photos (
  task_area_photo_id  INT NOT NULL AUTO_INCREMENT COMMENT '업무세부사진ID',
  task_area_log_id    INT NOT NULL COMMENT '업무세부결과ID',
  photo_file_path     VARCHAR(500) NOT NULL COMMENT '사진파일경로',
  PRIMARY KEY (task_area_photo_id),
  KEY idx_task_area_photos_task_area_log_id (task_area_log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_area_photos 업무세부사진';

ALTER TABLE task_area_photos
  ADD CONSTRAINT fk_task_area_logs_task_area_photos
  FOREIGN KEY (task_area_log_id) REFERENCES task_area_logs(task_area_log_id);

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
  KEY idx_task_sns_logs_user_id (user_id),
  KEY idx_task_sns_logs_task_log_id (task_log_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='task_sns_logs 업무알림결과';

ALTER TABLE task_sns_logs
  ADD CONSTRAINT fk_task_logs_task_sns_logs
  FOREIGN KEY (task_log_id) REFERENCES task_logs(task_log_id);

ALTER TABLE task_sns_logs
  ADD CONSTRAINT fk_users_task_sns_logs
  FOREIGN KEY (user_id) REFERENCES users(user_id);

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
(5, NULL, 'task_kind', 'snackbar', 1, 2),
(6, NULL, 'task_kind', 'officesupply', 1, 3);

-- 외래키 체크 재활성화
SET FOREIGN_KEY_CHECKS = 1;

-- 완료 메시지
SELECT 'MySQL DDL 스크립트 실행 완료' AS message;

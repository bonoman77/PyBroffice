USE Broffice$brobiz;

DELIMITER $$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 작업자 목록 조회 (user_kind_id=2)
-- =============================================

DROP PROCEDURE IF EXISTS get_workers_list$$

CREATE PROCEDURE get_workers_list()
BEGIN
    SELECT 
        user_id,
        user_name,
        user_email,
        user_mobile
    FROM users
    WHERE user_kind_id IN (1, 2)  -- 관리자, 작업자
      AND use_yn = 1        -- 사용중
      AND deleted_at IS NULL
    ORDER BY user_name;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 업무 종류별 업체 목록 조회 (use_yn, task_kind_id 고려)
-- =============================================

DROP PROCEDURE IF EXISTS get_client_list_by_task_kind$$

CREATE PROCEDURE get_client_list_by_task_kind(
    IN p_task_kind_id INT
)
BEGIN
    SELECT 
        c.client_id,
        c.client_name,
        c.client_phone,
        c.client_business_number,
        c.manager_name,
        c.manager_mobile,
        c.manager_position,
        c.memo,
        c.contracted_at,
        c.created_at,
        CASE WHEN c.use_yn = 1 THEN 'active' ELSE 'inactive' END AS status
    FROM clients c
    WHERE c.use_yn = 1  -- 사용중인 업체만
      AND c.deleted_at IS NULL
      AND (
          -- 청소 업체
          (p_task_kind_id = 4 AND c.cleaning_yn = 1) OR
          -- 간식 업체  
          (p_task_kind_id = 5 AND c.snack_yn = 1) OR
          -- 비품 업체
          (p_task_kind_id = 6 AND c.office_supplies_yn = 1)
      )
    ORDER BY c.client_name;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_task_insert$$

CREATE PROCEDURE set_task_insert(
    IN p_task_kind_id INT,
    IN p_client_id INT,
    IN p_user_id INT,
    IN p_days_of_week VARCHAR(30),
    IN p_fix_dates VARCHAR(30),
    IN p_service_started_at DATETIME,
    IN p_service_ended_at DATETIME,
    IN p_use_yn TINYINT(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_task_id INT;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 스케줄 등록
    INSERT INTO tasks (
        client_id,
        user_id,
        task_kind_id,
        days_of_week,
        fix_dates,
        service_started_at,
        service_ended_at,
        use_yn,
        created_at
    ) VALUES (
        p_client_id,
        p_user_id,
        p_task_kind_id,
        p_days_of_week,
        p_fix_dates,
        p_service_started_at,
        p_service_ended_at,
        p_use_yn,
        NOW()
    );
    
    -- 방금 삽입된 task_id 가져오기
    SET v_task_id = LAST_INSERT_ID();
    SET v_return_value = v_task_id;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS task_id;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_task_update$$

CREATE PROCEDURE set_task_update(
    IN p_task_id INT,
    IN p_client_id INT,
    IN p_user_id INT,
    IN p_days_of_week VARCHAR(30),
    IN p_fix_dates VARCHAR(30),
    IN p_service_started_at DATETIME,
    IN p_service_ended_at DATETIME,
    IN p_use_yn TINYINT(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 스케줄 수정
    UPDATE tasks
    SET client_id = p_client_id,
        user_id = p_user_id,
        days_of_week = p_days_of_week,
        fix_dates = p_fix_dates,
        service_started_at = p_service_started_at,
        service_ended_at = p_service_ended_at,
        use_yn = p_use_yn,
        updated_at = NOW()
    WHERE task_id = p_task_id
      AND deleted_at IS NULL;
    
    -- 영향받은 행 수 확인
    SET v_return_value = ROW_COUNT();
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS affected_rows;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 목록 조회 (구역수, 당월/익월 스케줄 생성수 포함)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_list$$

CREATE PROCEDURE get_task_list(
    IN p_task_kind_id INT
)
BEGIN
    SELECT 
        t.task_id,
        t.client_id,
        t.user_id,
        t.task_kind_id,
        t.days_of_week,
        t.fix_dates,
        DATE_FORMAT(t.service_started_at, '%Y-%m-%d') AS service_started_date,
        DATE_FORMAT(t.service_ended_at, '%Y-%m-%d') AS service_ended_date,
        t.use_yn,
        t.created_at,
        t.updated_at,
        c.client_name,
        u.user_name,
        u.user_mobile, 
        CASE 
            WHEN t.days_of_week = '0' THEN 
                CASE 
                    WHEN t.fix_dates IS NOT NULL AND t.fix_dates != '' THEN CONCAT('매월 ', t.fix_dates, '일')
                    ELSE '미정'
                END
            WHEN t.days_of_week = '1,2,3,4,5,6,7' THEN '매일'
            WHEN t.days_of_week = '1' THEN '월'
            WHEN t.days_of_week = '2' THEN '화'
            WHEN t.days_of_week = '3' THEN '수'
            WHEN t.days_of_week = '4' THEN '목'
            WHEN t.days_of_week = '5' THEN '금'
            WHEN t.days_of_week = '6' THEN '토'
            WHEN t.days_of_week = '7' THEN '일'
            ELSE CONCAT(
                CASE WHEN FIND_IN_SET('1', t.days_of_week) > 0 THEN '월' ELSE '' END,
                CASE WHEN FIND_IN_SET('2', t.days_of_week) > 0 THEN '화' ELSE '' END,
                CASE WHEN FIND_IN_SET('3', t.days_of_week) > 0 THEN '수' ELSE '' END,
                CASE WHEN FIND_IN_SET('4', t.days_of_week) > 0 THEN '목' ELSE '' END,
                CASE WHEN FIND_IN_SET('5', t.days_of_week) > 0 THEN '금' ELSE '' END,
                CASE WHEN FIND_IN_SET('6', t.days_of_week) > 0 THEN '토' ELSE '' END,
                CASE WHEN FIND_IN_SET('7', t.days_of_week) > 0 THEN '일' ELSE '' END
            )
        END AS day_of_week,
        CASE
            WHEN t.use_yn = 0 THEN 'inactive'
            WHEN t.use_yn = 1
                AND NOW() >= t.service_started_at
                AND (t.service_ended_at IS NULL OR NOW() <= t.service_ended_at)
            THEN 'active'
        ELSE 'pending'
        END AS task_status,
        -- 구역수 (활성 구역만)
        IFNULL((
            SELECT COUNT(*)
            FROM task_areas ta
            WHERE ta.task_id = t.task_id
              AND ta.use_yn = 1
              AND ta.deleted_at IS NULL
        ), 0) AS area_count,
        -- 당월 스케줄 생성수
        IFNULL((
            SELECT COUNT(*)
            FROM task_schedules ts
            WHERE ts.task_id = t.task_id
              AND ts.scheduled_at >= DATE_FORMAT(NOW(), '%Y-%m-01')
              AND ts.scheduled_at <= LAST_DAY(NOW())
        ), 0) AS current_month_schedule_count,
        -- 익월 스케줄 생성수
        IFNULL((
            SELECT COUNT(*)
            FROM task_schedules ts
            WHERE ts.task_id = t.task_id
              AND ts.scheduled_at >= DATE_FORMAT(DATE_ADD(NOW(), INTERVAL 1 MONTH), '%Y-%m-01')
              AND ts.scheduled_at <= LAST_DAY(DATE_ADD(NOW(), INTERVAL 1 MONTH))
        ), 0) AS next_month_schedule_count
    FROM tasks t
    INNER JOIN clients c ON t.client_id = c.client_id
    INNER JOIN users u ON t.user_id = u.user_id
    WHERE t.task_kind_id = p_task_kind_id
      AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 작업 소프트 삭제 (deleted_at 설정)
-- =============================================

DROP PROCEDURE IF EXISTS set_task_delete$$

CREATE PROCEDURE set_task_delete(
    IN p_task_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    START TRANSACTION;
    
    UPDATE tasks
    SET deleted_at = NOW()
    WHERE task_id = p_task_id
      AND deleted_at IS NULL;
    
    SET v_return_value = ROW_COUNT();
    
    COMMIT;
    
    SELECT v_return_value AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 구역 목록 조회 (task_id 기준)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_area_list$$

CREATE PROCEDURE get_task_area_list(
    IN p_task_id INT
)
BEGIN
    SELECT 
        task_area_id,
        task_id,
        floor,
        area,
        check_points,
        min_photo_cnt,
        use_yn,
        created_at,
        updated_at
    FROM task_areas
    WHERE task_id = p_task_id
      AND deleted_at IS NULL
    ORDER BY floor, area;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 구역 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_task_area_insert$$

CREATE PROCEDURE set_task_area_insert(
    IN p_task_id INT,
    IN p_floor VARCHAR(10),
    IN p_area VARCHAR(30),
    IN p_check_points VARCHAR(300),
    IN p_min_photo_cnt INT,
    IN p_use_yn TINYINT(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    START TRANSACTION;
    
    INSERT INTO task_areas (
        task_id,
        floor,
        area,
        check_points,
        min_photo_cnt,
        use_yn,
        created_at
    ) VALUES (
        p_task_id,
        p_floor,
        p_area,
        p_check_points,
        p_min_photo_cnt,
        p_use_yn,
        NOW()
    );
    
    SET v_return_value = LAST_INSERT_ID();
    
    COMMIT;
    
    SELECT v_return_value AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 구역 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_task_area_update$$

CREATE PROCEDURE set_task_area_update(
    IN p_task_area_id INT,
    IN p_floor VARCHAR(10),
    IN p_area VARCHAR(30),
    IN p_check_points VARCHAR(300),
    IN p_min_photo_cnt INT,
    IN p_use_yn TINYINT(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    START TRANSACTION;
    
    UPDATE task_areas
    SET floor = p_floor,
        area = p_area,
        check_points = p_check_points,
        min_photo_cnt = p_min_photo_cnt,
        use_yn = p_use_yn,
        updated_at = NOW()
    WHERE task_area_id = p_task_area_id
      AND deleted_at IS NULL;
    
    SET v_return_value = ROW_COUNT();
    
    COMMIT;
    
    SELECT v_return_value AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-10
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 일괄 생성 (task_id, year_month 기준)
--              days_of_week 또는 fix_dates 기반으로 해당 월 날짜 생성
-- =============================================

DROP PROCEDURE IF EXISTS set_task_schedule_generate$$

CREATE PROCEDURE set_task_schedule_generate(
    IN p_task_id INT,
    IN p_year_month VARCHAR(7)
)
BEGIN
    DECLARE v_task_user_id INT;
    DECLARE v_days_of_week VARCHAR(50);
    DECLARE v_fix_dates VARCHAR(200);
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_current_date DATE;
    DECLARE v_day_of_week INT;
    DECLARE v_day_of_month INT;
    DECLARE v_insert_count INT DEFAULT 0;
    DECLARE v_service_started_at DATE;
    DECLARE v_service_ended_at DATE;
    DECLARE v_use_yn TINYINT;
    DECLARE v_area_count INT DEFAULT 0;
    
    -- task 정보 조회
    SELECT user_id, days_of_week, fix_dates, 
           DATE(service_started_at), DATE(service_ended_at), use_yn
    INTO v_task_user_id, v_days_of_week, v_fix_dates,
         v_service_started_at, v_service_ended_at, v_use_yn
    FROM tasks
    WHERE task_id = p_task_id
      AND deleted_at IS NULL;
    
    -- task가 없으면 종료
    IF v_task_user_id IS NULL THEN
        SELECT 0 AS return_value, '작업을 찾을 수 없습니다.' AS message;
    -- 비활성 상태이면 생성 불가
    ELSEIF v_use_yn = 0 THEN
        SELECT 0 AS return_value, '비활성 상태의 작업은 스케줄을 생성할 수 없습니다.' AS message;
    ELSE
        -- 활성 구역 수 확인
        SELECT COUNT(*) INTO v_area_count
        FROM task_areas
        WHERE task_id = p_task_id
          AND use_yn = 1
          AND deleted_at IS NULL;
        
        -- 구역이 없으면 생성 불가
        IF v_area_count = 0 THEN
            SELECT 0 AS return_value, '등록된 구역이 없어 스케줄을 생성할 수 없습니다.' AS message;
        ELSE
        -- 해당 월의 시작일/종료일 계산
        SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
        SET v_end_date = LAST_DAY(v_start_date);
        
        -- 서비스 기간으로 범위 제한
        IF v_service_started_at IS NOT NULL AND v_service_started_at > v_start_date THEN
            SET v_start_date = v_service_started_at;
        END IF;
        IF v_service_ended_at IS NOT NULL AND v_service_ended_at < v_end_date THEN
            SET v_end_date = v_service_ended_at;
        END IF;
        
        -- 기존 해당 월 스케줄 삭제 (completed_at이 NULL인 것만)
        DELETE FROM task_schedules
        WHERE task_id = p_task_id
          AND scheduled_at >= STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d')
          AND scheduled_at <= LAST_DAY(STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d'))
          AND completed_at IS NULL;
        
        SET v_current_date = v_start_date;
        
        WHILE v_current_date <= v_end_date DO
            -- MySQL DAYOFWEEK: 1=일, 2=월, 3=화, 4=수, 5=목, 6=금, 7=토
            -- 우리 시스템: 1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일
            SET v_day_of_week = CASE DAYOFWEEK(v_current_date)
                WHEN 1 THEN 7  -- 일
                WHEN 2 THEN 1  -- 월
                WHEN 3 THEN 2  -- 화
                WHEN 4 THEN 3  -- 수
                WHEN 5 THEN 4  -- 목
                WHEN 6 THEN 5  -- 금
                WHEN 7 THEN 6  -- 토
            END;
            
            SET v_day_of_month = DAY(v_current_date);
            
            -- days_of_week가 '0'이면 fix_dates 기반 (월별)
            IF v_days_of_week = '0' THEN
                IF v_fix_dates IS NOT NULL AND FIND_IN_SET(v_day_of_month, REPLACE(v_fix_dates, ' ', '')) > 0 THEN
                    INSERT INTO task_schedules (task_id, user_id, scheduled_at)
                    VALUES (p_task_id, v_task_user_id, v_current_date);
                    SET v_insert_count = v_insert_count + 1;
                END IF;
            ELSE
                -- days_of_week 기반 (요일)
                IF FIND_IN_SET(v_day_of_week, v_days_of_week) > 0 THEN
                    INSERT INTO task_schedules (task_id, user_id, scheduled_at)
                    VALUES (p_task_id, v_task_user_id, v_current_date);
                    SET v_insert_count = v_insert_count + 1;
                END IF;
            END IF;
            
            SET v_current_date = DATE_ADD(v_current_date, INTERVAL 1 DAY);
        END WHILE;
        
        SELECT v_insert_count AS return_value, 
               CONCAT(v_insert_count, '건의 스케줄이 생성되었습니다.') AS message;
        END IF; -- v_area_count = 0
    END IF; -- v_task_user_id IS NULL
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 목록 조회 (년월 기준, 날짜순 - change_scheduled_at 우선)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_schedule_list$$

CREATE PROCEDURE get_task_schedule_list(
    IN p_task_kind_id INT,
    IN p_year_month VARCHAR(7)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        ts.task_schedule_id,
        ts.task_id,
        ts.user_id,
        ts.memo,
        DATE_FORMAT(ts.scheduled_at, '%Y-%m-%d') AS scheduled_date,
        DATE_FORMAT(ts.change_scheduled_at, '%Y-%m-%d') AS change_scheduled_date,
        DATE_FORMAT(ts.completed_at, '%Y-%m-%d %H:%i') AS completed_date,
        ts.canceled_at,
        ts.admin_user_id,
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS effective_date,
        CASE DAYOFWEEK(COALESCE(ts.change_scheduled_at, ts.scheduled_at))
            WHEN 1 THEN '일'
            WHEN 2 THEN '월'
            WHEN 3 THEN '화'
            WHEN 4 THEN '수'
            WHEN 5 THEN '목'
            WHEN 6 THEN '금'
            WHEN 7 THEN '토'
        END AS effective_day,
        c.client_name,
        u.user_name AS worker_name,
        u.user_mobile AS worker_mobile,
        au.user_name AS admin_name,
        CASE
            WHEN ts.canceled_at = 1 THEN 'canceled'
            WHEN ts.completed_at IS NOT NULL THEN 'completed'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) < CURDATE() THEN 'overdue'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) = CURDATE() THEN 'today'
            ELSE 'scheduled'
        END AS schedule_status
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    INNER JOIN users u ON ts.user_id = u.user_id
    LEFT JOIN users au ON ts.admin_user_id = au.user_id
    WHERE t.task_kind_id = p_task_kind_id
      AND (
          -- 원래 날짜가 해당 월에 속하거나
          (ts.scheduled_at >= v_start_date AND ts.scheduled_at <= v_end_date)
          OR
          -- 변경된 날짜가 해당 월에 속하는 경우
          (ts.change_scheduled_at >= v_start_date AND ts.change_scheduled_at <= v_end_date)
      )
      AND t.deleted_at IS NULL
    ORDER BY COALESCE(ts.change_scheduled_at, ts.scheduled_at) ASC, c.client_name ASC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 날짜 변경 (change_scheduled_at, admin_user_id 설정)
-- =============================================

DROP PROCEDURE IF EXISTS set_task_schedule_update$$

CREATE PROCEDURE set_task_schedule_update(
    IN p_task_schedule_id INT,
    IN p_change_scheduled_at DATE,
    IN p_admin_user_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    START TRANSACTION;
    
    UPDATE task_schedules
    SET change_scheduled_at = p_change_scheduled_at,
        admin_user_id = p_admin_user_id,
        updated_at = NOW()
    WHERE task_schedule_id = p_task_schedule_id;
    
    SET v_return_value = ROW_COUNT();
    
    COMMIT;
    
    SELECT v_return_value AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 스케줄 삭제 (물리 삭제)
-- =============================================

DROP PROCEDURE IF EXISTS set_task_schedule_delete$$

CREATE PROCEDURE set_task_schedule_delete(
    IN p_task_schedule_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    
    START TRANSACTION;
    
    -- 완료되지 않은 스케줄만 삭제 가능
    DELETE FROM task_schedules
    WHERE task_schedule_id = p_task_schedule_id
      AND completed_at IS NULL;
    
    SET v_return_value = ROW_COUNT();
    
    COMMIT;
    
    SELECT v_return_value AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 내 업무 목록 조회 (로그인 사용자 기준, 월별)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_my_list$$

CREATE PROCEDURE get_task_my_list(
    IN p_user_id INT,
    IN p_year_month VARCHAR(7)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        ts.task_schedule_id,
        ts.task_id,
        ts.user_id,
        ts.memo,
        DATE_FORMAT(ts.scheduled_at, '%Y-%m-%d') AS scheduled_date,
        DATE_FORMAT(ts.change_scheduled_at, '%Y-%m-%d') AS change_scheduled_date,
        DATE_FORMAT(ts.completed_at, '%Y-%m-%d %H:%i') AS completed_date,
        ts.canceled_at,
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS effective_date,
        CASE DAYOFWEEK(COALESCE(ts.change_scheduled_at, ts.scheduled_at))
            WHEN 1 THEN '일'
            WHEN 2 THEN '월'
            WHEN 3 THEN '화'
            WHEN 4 THEN '수'
            WHEN 5 THEN '목'
            WHEN 6 THEN '금'
            WHEN 7 THEN '토'
        END AS effective_day,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        c.client_name,
        c.client_id,
        CASE
            WHEN ts.canceled_at = 1 THEN 'canceled'
            WHEN ts.completed_at IS NOT NULL THEN 'completed'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) < CURDATE() THEN 'overdue'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) = CURDATE() THEN 'today'
            ELSE 'scheduled'
        END AS schedule_status,
        (SELECT COUNT(*) FROM task_areas ta 
         WHERE ta.task_id = t.task_id AND ta.use_yn = 1 AND ta.deleted_at IS NULL) AS area_count,
        (SELECT COUNT(*) FROM task_area_logs tal 
         INNER JOIN task_areas ta2 ON tal.task_area_id = ta2.task_area_id
         WHERE tal.task_schedule_id = ts.task_schedule_id 
           AND ta2.deleted_at IS NULL) AS completed_area_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    WHERE ts.user_id = p_user_id
      AND (
          (ts.scheduled_at >= v_start_date AND ts.scheduled_at <= v_end_date)
          OR
          (ts.change_scheduled_at >= v_start_date AND ts.change_scheduled_at <= v_end_date)
      )
      AND t.deleted_at IS NULL
    ORDER BY COALESCE(ts.change_scheduled_at, ts.scheduled_at) ASC, c.client_name ASC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 업무 상세 조회 (스케줄 + 구역 + 구역별 로그/사진)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_detail$$

CREATE PROCEDURE get_task_detail(
    IN p_task_schedule_id INT
)
BEGIN
    -- 1) 스케줄 기본 정보
    SELECT 
        ts.task_schedule_id,
        ts.task_id,
        ts.user_id,
        ts.memo,
        DATE_FORMAT(ts.scheduled_at, '%Y-%m-%d') AS scheduled_date,
        DATE_FORMAT(ts.change_scheduled_at, '%Y-%m-%d') AS change_scheduled_date,
        DATE_FORMAT(ts.completed_at, '%Y-%m-%d %H:%i') AS completed_date,
        ts.canceled_at,
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS effective_date,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        c.client_name,
        c.client_id,
        u.user_name AS worker_name,
        CASE
            WHEN ts.canceled_at = 1 THEN 'canceled'
            WHEN ts.completed_at IS NOT NULL THEN 'completed'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) < CURDATE() THEN 'overdue'
            WHEN COALESCE(ts.change_scheduled_at, ts.scheduled_at) = CURDATE() THEN 'today'
            ELSE 'scheduled'
        END AS schedule_status
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    INNER JOIN users u ON ts.user_id = u.user_id
    WHERE ts.task_schedule_id = p_task_schedule_id;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 업무 구역 목록 조회 (스케줄 기준, 로그/사진 포함)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_detail_areas$$

CREATE PROCEDURE get_task_detail_areas(
    IN p_task_schedule_id INT
)
BEGIN
    SELECT 
        ta.task_area_id,
        ta.floor,
        ta.area,
        ta.check_points,
        ta.min_photo_cnt,
        tal.task_area_log_id,
        tal.content AS log_content,
        DATE_FORMAT(tal.created_at, '%Y-%m-%d %H:%i') AS log_created_at
    FROM task_areas ta
    INNER JOIN task_schedules ts ON ta.task_id = ts.task_id
    LEFT JOIN task_area_logs tal ON ta.task_area_id = tal.task_area_id 
        AND tal.task_schedule_id = p_task_schedule_id
    WHERE ts.task_schedule_id = p_task_schedule_id
      AND ta.use_yn = 1
      AND ta.deleted_at IS NULL
    ORDER BY ta.floor ASC, ta.area ASC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 구역별 사진 목록 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_task_area_photos$$

CREATE PROCEDURE get_task_area_photos(
    IN p_task_area_log_id INT
)
BEGIN
    SELECT 
        tap.task_area_photo_id,
        tap.photo_file_path
    FROM task_area_photos tap
    WHERE tap.task_area_log_id = p_task_area_log_id
    ORDER BY tap.task_area_photo_id ASC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 구역별 업무 로그 저장 (INSERT or UPDATE)
-- =============================================

DROP PROCEDURE IF EXISTS set_task_area_log$$

CREATE PROCEDURE set_task_area_log(
    IN p_task_area_id INT,
    IN p_task_schedule_id INT,
    IN p_content VARCHAR(500)
)
BEGIN
    DECLARE v_log_id INT DEFAULT 0;
    
    -- 기존 로그 확인
    SELECT task_area_log_id INTO v_log_id
    FROM task_area_logs
    WHERE task_area_id = p_task_area_id
      AND task_schedule_id = p_task_schedule_id
    LIMIT 1;
    
    IF v_log_id > 0 THEN
        -- 기존 로그 업데이트
        UPDATE task_area_logs
        SET content = p_content,
            updated_at = NOW()
        WHERE task_area_log_id = v_log_id;
    ELSE
        -- 새 로그 생성
        INSERT INTO task_area_logs (task_area_id, task_schedule_id, content)
        VALUES (p_task_area_id, p_task_schedule_id, p_content);
        SET v_log_id = LAST_INSERT_ID();
    END IF;
    
    SELECT v_log_id AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 구역 사진 추가
-- =============================================

DROP PROCEDURE IF EXISTS set_task_area_photo_insert$$

CREATE PROCEDURE set_task_area_photo_insert(
    IN p_task_area_log_id INT,
    IN p_photo_file_path VARCHAR(500)
)
BEGIN
    INSERT INTO task_area_photos (task_area_log_id, photo_file_path)
    VALUES (p_task_area_log_id, p_photo_file_path);
    
    SELECT LAST_INSERT_ID() AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 구역 사진 삭제
-- =============================================

DROP PROCEDURE IF EXISTS set_task_area_photo_delete$$

CREATE PROCEDURE set_task_area_photo_delete(
    IN p_task_area_photo_id INT
)
BEGIN
    DECLARE v_file_path VARCHAR(500);
    
    SELECT photo_file_path INTO v_file_path
    FROM task_area_photos
    WHERE task_area_photo_id = p_task_area_photo_id;
    
    DELETE FROM task_area_photos
    WHERE task_area_photo_id = p_task_area_photo_id;
    
    SELECT ROW_COUNT() AS return_value, v_file_path AS file_path;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 업무 완료 처리 (completed_at, memo 저장)
-- =============================================

DROP PROCEDURE IF EXISTS set_task_schedule_complete$$

CREATE PROCEDURE set_task_schedule_complete(
    IN p_task_schedule_id INT,
    IN p_memo VARCHAR(500)
)
BEGIN
    UPDATE task_schedules
    SET completed_at = NOW(),
        memo = p_memo,
        updated_at = NOW()
    WHERE task_schedule_id = p_task_schedule_id
      AND completed_at IS NULL;
    
    SELECT ROW_COUNT() AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 현장직원 대시보드용 월별 스케줄 진행상황
-- =============================================

DROP PROCEDURE IF EXISTS get_staff_schedule_progress$$

CREATE PROCEDURE get_staff_schedule_progress(
    IN p_user_id INT,
    IN p_year_month VARCHAR(7)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        COUNT(*) AS total_count,
        SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    WHERE ts.user_id = p_user_id
      AND ts.scheduled_at >= v_start_date
      AND ts.scheduled_at <= v_end_date
      AND t.deleted_at IS NULL
      AND ts.canceled_at IS NULL
    GROUP BY t.task_kind_id
    ORDER BY t.task_kind_id;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Email:       bonoman77@gmail.com 
-- Description: 업체용 작업 보고 내역 (완료된 작업만, client_id 필터)
-- =============================================

DROP PROCEDURE IF EXISTS get_task_client_list$$

CREATE PROCEDURE get_task_client_list(
    IN p_client_id INT,
    IN p_year_month VARCHAR(7),
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    DECLARE v_offset INT;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    SET v_offset = (p_page - 1) * p_page_size;
    
    SELECT 
        ts.task_schedule_id,
        ts.task_id,
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS effective_date,
        DATE_FORMAT(ts.completed_at, '%Y-%m-%d %H:%i') AS completed_date,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        c.client_id,
        c.client_name,
        u.user_name AS worker_name,
        ts.memo,
        (SELECT COUNT(*) FROM task_areas ta 
         WHERE ta.task_id = t.task_id AND ta.use_yn = 1 AND ta.deleted_at IS NULL) AS area_count,
        (SELECT COUNT(*) FROM task_area_logs tal 
         INNER JOIN task_areas ta2 ON tal.task_area_id = ta2.task_area_id
         WHERE tal.task_schedule_id = ts.task_schedule_id 
           AND ta2.deleted_at IS NULL) AS completed_area_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    LEFT JOIN users u ON ts.user_id = u.user_id
    WHERE ts.completed_at IS NOT NULL
      AND t.deleted_at IS NULL
      AND ts.canceled_at IS NULL
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
      AND (p_client_id = 0 OR t.client_id = p_client_id)
    ORDER BY ts.completed_at DESC
    LIMIT v_offset, p_page_size;
END$$


DROP PROCEDURE IF EXISTS get_task_client_list_count$$

CREATE PROCEDURE get_task_client_list_count(
    IN p_client_id INT,
    IN p_year_month VARCHAR(7)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT COUNT(*) AS total_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    WHERE ts.completed_at IS NOT NULL
      AND t.deleted_at IS NULL
      AND ts.canceled_at IS NULL
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
      AND (p_client_id = 0 OR t.client_id = p_client_id);
END$$


-- 대시보드용: 업체별 최근 완료 작업 (limit 지정)
DROP PROCEDURE IF EXISTS get_task_client_recent$$

CREATE PROCEDURE get_task_client_recent(
    IN p_client_id INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        ts.task_schedule_id,
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS effective_date,
        DATE_FORMAT(ts.completed_at, '%Y-%m-%d %H:%i') AS completed_date,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        c.client_name,
        u.user_name AS worker_name,
        (SELECT COUNT(*) FROM task_areas ta 
         WHERE ta.task_id = t.task_id AND ta.use_yn = 1 AND ta.deleted_at IS NULL) AS area_count,
        (SELECT COUNT(*) FROM task_area_logs tal 
         INNER JOIN task_areas ta2 ON tal.task_area_id = ta2.task_area_id
         WHERE tal.task_schedule_id = ts.task_schedule_id 
           AND ta2.deleted_at IS NULL) AS completed_area_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    LEFT JOIN users u ON ts.user_id = u.user_id
    WHERE ts.completed_at IS NOT NULL
      AND t.deleted_at IS NULL
      AND ts.canceled_at IS NULL
      AND t.client_id = p_client_id
    ORDER BY ts.completed_at DESC
    LIMIT p_limit;
END$$


DELIMITER ;

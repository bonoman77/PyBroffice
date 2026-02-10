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
-- Description: 스케줄 목록 조회
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
        t.fix_dates,
		CASE
			WHEN t.use_yn = 0 THEN 'inactive'
			WHEN t.use_yn = 1
				AND NOW() >= t.service_started_at
				AND (t.service_ended_at IS NULL OR NOW() <= t.service_ended_at)
			THEN 'active'
		ELSE 'pending'
		END AS task_status
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
    
    -- task 정보 조회
    SELECT user_id, days_of_week, fix_dates, 
           DATE(service_started_at), DATE(service_ended_at)
    INTO v_task_user_id, v_days_of_week, v_fix_dates,
         v_service_started_at, v_service_ended_at
    FROM tasks
    WHERE task_id = p_task_id
      AND deleted_at IS NULL;
    
    -- task가 없으면 종료
    IF v_task_user_id IS NULL THEN
        SELECT 0 AS return_value, '작업을 찾을 수 없습니다.' AS message;
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
    END IF;
END$$


DELIMITER ;

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
        t.service_started_at,
        t.service_ended_at,
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
        t.fix_dates
    FROM tasks t
    INNER JOIN clients c ON t.client_id = c.client_id
    INNER JOIN users u ON t.user_id = u.user_id
    WHERE t.task_kind_id = p_task_kind_id
      AND t.deleted_at IS NULL
    ORDER BY t.created_at DESC;
END$$


DELIMITER ;


USE Broffice$brobiz;

DELIMITER $$


-- =============================================
-- Author:      김승균
-- Create date: 2026-01-27
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 사용자 로그인 (관리자)
-- =============================================

DROP PROCEDURE IF EXISTS get_user_admin_login$$

CREATE PROCEDURE get_user_admin_login(
    IN p_user_id INT
)
BEGIN
    -- 트랜잭션 격리 수준 설정 (READ UNCOMMITTED)
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    -- 사용자 정보 반환 (로그인 성공 시에만 결과 반환)
    SELECT 
        u.user_id,
        u.user_email,
        u.user_name,
        u.user_kind_id,
        u.user_mobile,
        u.client_id,
        c.client_name,
        u.admin_authed_at,
        IF(u.admin_authed_at IS NOT NULL, 1, 0) AS admin_auth_yn
    FROM users u
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE u.deleted_at IS NULL
      AND u.user_id = p_user_id
    LIMIT 1;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 업체 목록 조회 (업무 종류 포함)
-- =============================================

DROP PROCEDURE IF EXISTS get_client_list$$

CREATE PROCEDURE get_client_list()
BEGIN
    SELECT 
        c.client_id,
        c.client_name,
        c.client_phone,
        c.client_address,
        c.client_business_number,
        c.manager_name,
        c.manager_mobile,
        c.manager_position,
        c.contracted_at,
        c.memo,
        c.cleaning_yn,
        c.snack_yn,
        c.office_supplies_yn,
        c.created_at,
        CASE WHEN c.use_yn = 1 THEN 'active' ELSE 'inactive' END AS status,
        DATE_FORMAT(c.contracted_at, '%Y-%m-%d') AS contract_date,
        DATE_FORMAT(c.created_at, '%Y-%m-%d') AS create_date
    FROM clients c
    WHERE c.deleted_at IS NULL
    ORDER BY c.created_at DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 업무 종류별 업체 수 통계
-- =============================================

DROP PROCEDURE IF EXISTS get_client_stats_by_task_kind$$

CREATE PROCEDURE get_client_stats_by_task_kind()
BEGIN
    SELECT 
        COUNT(DISTINCT c.client_id) AS total_clients,
        COUNT(DISTINCT CASE WHEN c.cleaning_yn = 1 THEN c.client_id END) AS cleaning_clients,
        COUNT(DISTINCT CASE WHEN c.snack_yn = 1 THEN c.client_id END) AS snack_clients,
        COUNT(DISTINCT CASE WHEN c.office_supplies_yn = 1 THEN c.client_id END) AS supplies_clients
    FROM clients c
    WHERE c.deleted_at IS NULL;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-04
-- Email:       bonoman77@gmail.com 
-- Description: 업체 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_client_insert$$

CREATE PROCEDURE set_client_insert(
    IN p_client_name VARCHAR(100),
    IN p_client_phone VARCHAR(20),
    IN p_client_business_number VARCHAR(20),
    IN p_client_address VARCHAR(255),
    IN p_manager_name VARCHAR(100),
    IN p_manager_mobile VARCHAR(100),
    IN p_manager_position VARCHAR(100),
    IN p_contracted_at DATETIME,
    IN p_memo TEXT,
    IN p_cleaning_yn INT,
    IN p_snack_yn INT,
    IN p_office_supplies_yn INT,
    IN p_status VARCHAR(20)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_client_id INT;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 업체 등록
    INSERT INTO clients (
        client_name,
        client_phone,
        client_business_number,
        client_address,
        manager_name,
        manager_mobile,
        manager_position,
        contracted_at,
        memo,
        cleaning_yn,
        snack_yn,
        office_supplies_yn,
        use_yn, 
        created_at
    ) VALUES (
        p_client_name,
        p_client_phone,
        p_client_business_number,
        p_client_address,
        p_manager_name,
        p_manager_mobile,
        p_manager_position,
        p_contracted_at,
        p_memo,
        p_cleaning_yn,
        p_snack_yn,
        p_office_supplies_yn,
        IF (p_status = 'active', 1, 0),
        NOW()
    );
    
    SET v_client_id = LAST_INSERT_ID();
    SET v_return_value = 1; -- 성공
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value, v_client_id AS client_id;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-04
-- Email:       bonoman77@gmail.com 
-- Description: 업체 정보 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_client_update$$

CREATE PROCEDURE set_client_update(
    IN p_client_id INT,
    IN p_client_name VARCHAR(100),
    IN p_client_phone VARCHAR(20),
    IN p_client_address VARCHAR(255),
    IN p_client_business_number VARCHAR(20),
    IN p_manager_name VARCHAR(100),
    IN p_manager_mobile VARCHAR(100),
    IN p_manager_position VARCHAR(100),
    IN p_contracted_at DATETIME,
    IN p_memo TEXT,
    IN p_cleaning_yn INT,
    IN p_snack_yn INT,
    IN p_office_supplies_yn INT,
    IN p_status VARCHAR(20)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_client_count INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 업체 존재 여부 확인
    SELECT COUNT(*) INTO v_client_count
    FROM clients
    WHERE client_id = p_client_id
      AND deleted_at IS NULL;
    
    IF v_client_count = 0 THEN
        SET v_return_value = 2; -- 업체 없음
    ELSE
        UPDATE clients
        SET client_name = p_client_name,
            client_phone = p_client_phone,
            client_business_number = p_client_business_number,
            client_address = p_client_address,
            manager_name = p_manager_name,
            manager_mobile = p_manager_mobile,
            manager_position = p_manager_position,
            contracted_at = p_contracted_at,
            memo = p_memo,
            cleaning_yn = p_cleaning_yn,
            snack_yn = p_snack_yn,
            office_supplies_yn = p_office_supplies_yn,
            use_yn = IF (p_status = 'active', 1, 0),
            updated_at = NOW()
        WHERE client_id = p_client_id
          AND deleted_at IS NULL;
        
        SET v_return_value = 1; -- 성공
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 목록 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_user_list$$

CREATE PROCEDURE get_user_list()
BEGIN
    SELECT 
        u.user_id,
        u.user_name,
        u.user_email,
        u.user_mobile,
        u.user_kind_id,
        u.client_id,
        c.client_name,
        CASE 
            WHEN u.user_kind_id = 1 THEN 'admin'
            WHEN u.user_kind_id = 2 THEN 'staff'
            WHEN u.user_kind_id = 3 THEN 'client'
            ELSE 'user'
        END AS role,
        CASE 
            WHEN u.use_yn = 1 AND u.admin_authed_at IS NOT NULL THEN 'active'
            WHEN u.use_yn = 1 AND u.admin_authed_at IS NULL THEN 'pending'
            ELSE 'inactive'
        END AS status,
        u.use_yn,
        u.created_at, 
    FROM users u
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE u.deleted_at IS NULL
    ORDER BY u.created_at DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 통계
-- =============================================

DROP PROCEDURE IF EXISTS get_user_stats$$

CREATE PROCEDURE get_user_stats()
BEGIN
    SELECT 
        COUNT(*) AS total_users,
        COUNT(CASE WHEN use_yn = 1 AND admin_authed_at IS NOT NULL THEN 1 END) AS active_users,
        COUNT(CASE WHEN use_yn = 1 AND admin_authed_at IS NULL THEN 1 END) AS pending_users,
        COUNT(CASE WHEN use_yn = 0 THEN 1 END) AS inactive_users
    FROM users
    WHERE deleted_at IS NULL;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 등록 (공용)
-- =============================================

DROP PROCEDURE IF EXISTS set_user_insert$$

CREATE PROCEDURE set_user_insert(
    IN p_user_name VARCHAR(100),
    IN p_user_email VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_user_passwd VARCHAR(100),
    IN p_status VARCHAR(20),
    IN p_client_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_email_count INT DEFAULT 0;
    DECLARE v_user_id INT;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 이메일 중복 체크
    SELECT COUNT(*) INTO v_email_count
    FROM users
    WHERE user_email = p_user_email
      AND deleted_at IS NULL;
    
    IF v_email_count > 0 THEN
        SET v_return_value = 2; -- 이메일 중복
    ELSE
        -- 사용자 등록 (상태에 따라 use_yn 설정)
        INSERT INTO users (
            user_email,
            user_passwd,
            user_name,
            user_kind_id,
            user_mobile,
            client_id,
            use_yn, 
            admin_authed_at,
            created_at
        ) VALUES (
            p_user_email,
            UNHEX(SHA2(p_user_passwd, 512)),
            p_user_name,
            p_user_kind_id,
            p_user_mobile,
            CASE WHEN p_user_kind_id = 3 THEN p_client_id ELSE NULL END, -- 업체담당자가 아니면 NULL
            IF(p_status = 'active', 1, 0),
            IF(p_status = 'active', NOW(), NULL),
            NOW()
        );
        SET v_user_id = LAST_INSERT_ID();
        SET v_return_value = 1; -- 성공
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value, v_user_id AS user_id;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 정보 수정 (관리자용)
-- =============================================

DROP PROCEDURE IF EXISTS set_user_update$$

CREATE PROCEDURE set_user_update(
    IN p_user_id INT,
    IN p_user_name VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_user_passwd VARCHAR(100),
    IN p_status VARCHAR(20),
    IN p_client_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;
    DECLARE v_current_use_yn INT DEFAULT 0;
    DECLARE v_use_yn INT DEFAULT 0;
    DECLARE v_new_admin_authed_at DATETIME DEFAULT NULL;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 사용자 존재 여부 확인
    SELECT COUNT(*) INTO v_user_count
    FROM users
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;
    
    IF v_user_count = 0 THEN
        SET v_return_value = 2; -- 사용자 없음
    ELSE
        -- 현재 사용자 상태 조회
        SELECT use_yn INTO v_current_use_yn
        FROM users
        WHERE user_id = p_user_id
          AND deleted_at IS NULL;
        
        -- 상태에 따른 use_yn 및 admin_authed_at 설정
        IF p_status = 'active' THEN
            -- 활성: use_yn=1, 비활성->활성 전환 시에만 admin_authed_at 업데이트
            SET v_use_yn = 1;
            IF v_current_use_yn = 0 THEN
                SET v_new_admin_authed_at = NOW();
            ELSE
                -- 이미 활성이면 기존 값 유지
                SELECT admin_authed_at INTO v_new_admin_authed_at
                FROM users
                WHERE user_id = p_user_id
                  AND deleted_at IS NULL;
            END IF;
        ELSEIF p_status = 'pending' THEN
            -- 대기: use_yn=1, admin_authed_at=NULL
            SET v_use_yn = 1;
            SET v_new_admin_authed_at = NULL;
        ELSE
            -- 비활성: use_yn=0, admin_authed_at=NULL
            SET v_use_yn = 0;
            SET v_new_admin_authed_at = NULL;
        END IF;
        
        -- 비밀번호 변경 여부에 따라 업데이트
        IF p_user_passwd IS NOT NULL AND p_user_passwd != '' THEN
            UPDATE users
            SET user_name = p_user_name,
                user_mobile = p_user_mobile,
                user_kind_id = p_user_kind_id,
                user_passwd = UNHEX(SHA2(p_user_passwd, 512)),
                client_id = CASE WHEN p_user_kind_id = 3 THEN p_client_id ELSE NULL END, -- 업체담당자가 아니면 NULL
                use_yn = v_use_yn,
                admin_authed_at = v_new_admin_authed_at,
                updated_at = NOW()
            WHERE user_id = p_user_id
              AND deleted_at IS NULL;
        ELSE
            UPDATE users
            SET user_name = p_user_name,
                user_mobile = p_user_mobile,
                user_kind_id = p_user_kind_id,
                client_id = CASE WHEN p_user_kind_id = 3 THEN p_client_id ELSE NULL END, -- 업체담당자가 아니면 NULL
                use_yn = v_use_yn,
                admin_authed_at = v_new_admin_authed_at,
                updated_at = NOW()
            WHERE user_id = p_user_id
              AND deleted_at IS NULL;
        END IF;
        
        SET v_return_value = 1; -- 성공
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-09
-- Email:       bonoman77@gmail.com 
-- Description: 개별 사용자 정보 조회 (관리자용)
-- =============================================

DROP PROCEDURE IF EXISTS get_user_detail$$

CREATE PROCEDURE get_user_detail(
    IN p_user_id INT
)
BEGIN
    SELECT 
        u.user_id,
        u.user_name,
        u.user_email,
        u.user_mobile,
        u.user_kind_id,
        u.client_id,
        c.client_name,
        CASE 
            WHEN u.user_kind_id = 1 THEN 'admin'
            WHEN u.user_kind_id = 2 THEN 'staff'
            WHEN u.user_kind_id = 3 THEN 'client'
            ELSE 'user'
        END AS role,
        CASE 
            WHEN u.use_yn = 1 AND u.admin_authed_at IS NOT NULL THEN 'active'
            WHEN u.use_yn = 1 AND u.admin_authed_at IS NULL THEN 'pending'
            ELSE 'inactive'
        END AS status,
        u.use_yn,
        u.admin_authed_at,
        DATE_FORMAT(u.created_at, '%Y-%m-%d') AS create_date,
        DATE_FORMAT(u.updated_at, '%Y-%m-%d') AS update_date
    FROM users u
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE u.user_id = p_user_id
      AND u.deleted_at IS NULL
    LIMIT 1;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-05
-- Description: 회원 소프트 삭제 (관리자용)
-- =============================================
DROP PROCEDURE IF EXISTS set_user_delete$$

CREATE PROCEDURE set_user_delete(
    IN p_user_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_exists INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 회원 존재 여부 확인
    SELECT COUNT(*) INTO v_user_exists
    FROM users
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;
    
    IF v_user_exists = 0 THEN
        SET v_return_value = 2; -- 회원 없음
    ELSE
        -- 소프트 삭제 (deleted_at 업데이트) 및 업체 연결 해제
        UPDATE users
        SET deleted_at = NOW(),
            updated_at = NOW(),
            client_id = NULL  -- 업체 연결 해제
        WHERE user_id = p_user_id
          AND deleted_at IS NULL;
        
        SET v_return_value = 1; -- 성공
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value;
    
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-09
-- Email:       bonoman77@gmail.com 
-- Description: 활성 업체 목록 조회 (회원 등록/수정용)
-- =============================================
 
DROP PROCEDURE IF EXISTS get_active_client_list$$
 
CREATE PROCEDURE get_active_client_list()
BEGIN
    SELECT 
        c.client_id,
        c.client_name
    FROM clients c
    WHERE c.deleted_at IS NULL
      AND c.use_yn = 1
    ORDER BY c.client_name ASC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-09
-- Email:       bonoman77@gmail.com 
-- Description: 업무 종류별 업체 목록 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_client_list_by_task_kind$$

CREATE PROCEDURE get_client_list_by_task_kind(IN p_task_kind_id INT)
BEGIN
    SELECT 
        c.client_id,
        c.client_name,
        c.client_phone,
        c.client_address,
        c.client_business_number,
        c.manager_name,
        c.manager_mobile,
        c.manager_position,
        c.contracted_at,
        c.memo,
        c.cleaning_yn,
        c.snack_yn,
        c.office_supplies_yn,
        c.created_at,
        CASE WHEN c.use_yn = 1 THEN 'active' ELSE 'inactive' END AS status,
        DATE_FORMAT(c.contracted_at, '%Y-%m-%d') AS contract_date,
        DATE_FORMAT(c.created_at, '%Y-%m-%d') AS create_date
    FROM clients c
    WHERE c.deleted_at IS NULL
      AND c.use_yn = 1
      AND (
        (p_task_kind_id = 4 AND c.cleaning_yn = 1) OR  -- 청소
        (p_task_kind_id = 5 AND c.snack_yn = 1) OR     -- 간식
        (p_task_kind_id = 6 AND c.office_supplies_yn = 1) -- 비품
      )
    ORDER BY c.created_at DESC;
END$$
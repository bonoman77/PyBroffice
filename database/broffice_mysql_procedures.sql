USE Broffice$brobiz;


-- =============================================
-- Author:      김승균
-- Create date: 2026-01-27
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 사용자 로그인
-- =============================================


DELIMITER $$

DROP PROCEDURE IF EXISTS get_user_login$$

CREATE PROCEDURE get_user_login(
    IN p_user_email VARCHAR(100),
    IN p_user_passwd VARCHAR(100)
)
BEGIN
    DECLARE v_user_id INT;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 사용자 ID 조회
    SELECT user_id INTO v_user_id
    FROM users
    WHERE deleted_at IS NULL
      AND user_email = p_user_email
      AND user_passwd = UNHEX(SHA2(p_user_passwd, 512))
    LIMIT 1;
    
    -- 로그인 성공 시 로그 기록
    IF v_user_id IS NOT NULL THEN
        INSERT INTO user_login_logs (user_id, login_at)
        VALUES (v_user_id, NOW());
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 사용자 정보 반환 (로그인 성공 시에만 결과 반환)
    SELECT 
        u.user_id,
        u.user_name,
        u.user_kind_id,
        u.user_email,
        u.user_mobile,
        u.client_id,
        c.client_name, 
        u.admin_authed_at,
        IF(u.admin_authed_at IS NOT NULL, 1, 0) AS admin_auth_yn
    FROM users u
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE u.deleted_at IS NULL
      AND u.user_email = p_user_email
      AND u.user_passwd = UNHEX(SHA2(p_user_passwd, 512))
    LIMIT 1;
    
END$$

DELIMITER ;


-- =============================================
-- Author:      김승균
-- Create date: 2026-01-28
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 사용자 등록(가입)
-- =============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS set_user_regist$$

CREATE PROCEDURE set_user_regist(
    IN p_user_name VARCHAR(100),
    IN p_user_email VARCHAR(100),
    IN p_user_passwd VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_client_id INT,
    IN p_auth_code VARCHAR(100)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_email_count INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 이메일 중복 체크 (이메일이 있는 경우만)
    IF p_user_email IS NOT NULL AND p_user_email != '' THEN
        SELECT COUNT(*) INTO v_email_count
        FROM users
        WHERE user_email = p_user_email
          AND deleted_at IS NULL;
        
        IF v_email_count > 0 THEN
            SET v_return_value = 2; -- 이메일 중복
        END IF;
    END IF;
    
    -- 이메일 중복이 아닌 경우 계정 중복 체크
    IF v_return_value = 0 THEN
        -- 사용자 등록
        INSERT INTO users (
            user_email,
            user_passwd,
            user_name,
            user_kind_id,
            user_mobile,
            client_id,
            auth_code,
            authed_at,
            created_at
        ) VALUES (
            p_user_email,
            UNHEX(SHA2(p_user_passwd, 512)), -- SHA2-512 단방향 암호화
            p_user_name,
            p_user_kind_id,
            p_user_mobile,
            p_client_id,
            p_auth_code,
            NOW(), -- 등록 시점의 날짜 (인증은 필요시 구현)
            NOW()
        );
        
        SET v_return_value = 1; -- 성공
    END IF;
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value;
    
END$$

DELIMITER ;


-- =============================================
-- Author:      김승균
-- Create date: 2026-01-27
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 사용자 로그인 (관리자)
-- =============================================


DELIMITER $$

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

DELIMITER ;

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 관리자 사용자 승인
-- =============================================

DELIMITER $$

DROP PROCEDURE IF EXISTS set_user_admin_auth_update$$

CREATE PROCEDURE set_user_admin_auth_update(
    IN p_user_id INT,
    IN p_admin_user_id INT
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;
    
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
        -- 관리자 승인 처리
        UPDATE users
        SET admin_auth_at = NOW(),
            admin_auth_user_id = p_admin_user_id,
            updated_at = NOW()
        WHERE user_id = p_user_id
          AND deleted_at IS NULL;
        
        IF ROW_COUNT() > 0 THEN
            SET v_return_value = 1; -- 성공
        ELSE
            SET v_return_value = 3; -- 업데이트 실패
        END IF;
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
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 업체 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_client_insert$$

CREATE PROCEDURE set_client_insert(
    IN p_client_name VARCHAR(100),
    IN p_client_phone VARCHAR(100),
    IN p_client_address VARCHAR(300),
    IN p_client_business_number VARCHAR(100),
    IN p_manager_name VARCHAR(100),
    IN p_manager_mobile VARCHAR(100),
    IN p_manager_position VARCHAR(100),
    IN p_contracted_at DATETIME,
    IN p_memo VARCHAR(500),
    IN p_cleaning_yn VARCHAR(1),
    IN p_snack_yn VARCHAR(1),
    IN p_office_supplies_yn VARCHAR(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_client_id INT;
    DECLARE v_task_kind INT;
    DECLARE v_pos INT;
    DECLARE v_remaining VARCHAR(100);
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 업체 등록
    INSERT INTO clients (
        client_name,
        client_phone,
        client_address,
        client_business_number,
        manager_name,
        manager_mobile,
        manager_position,
        contracted_at,
        memo,
        cleaning_yn,
        snack_yn,
        office_supplies_yn,
        created_at
    ) VALUES (
        p_client_name,
        p_client_phone,
        p_client_address,
        p_client_business_number,
        p_manager_name,
        p_manager_mobile,
        p_manager_position,
        p_contracted_at,
        p_memo,
        p_cleaning_yn,
        p_snack_yn,
        p_office_supplies_yn,
        NOW()
    );
    
    SET v_return_value = 1; -- 성공
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_return_value AS return_value, v_client_id AS client_id;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 업체 정보 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_client_update$$

CREATE PROCEDURE set_client_update(
    IN p_client_id INT,
    IN p_client_name VARCHAR(100),
    IN p_client_phone VARCHAR(100),
    IN p_client_address VARCHAR(300),
    IN p_client_business_number VARCHAR(100),
    IN p_manager_name VARCHAR(100),
    IN p_manager_mobile VARCHAR(100),
    IN p_manager_position VARCHAR(100),
    IN p_contracted_at DATETIME,
    IN p_memo VARCHAR(500),
    IN p_cleaning_yn VARCHAR(1),
    IN p_snack_yn VARCHAR(1),
    IN p_office_supplies_yn VARCHAR(1)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_client_count INT DEFAULT 0;
    DECLARE v_task_kind INT;
    DECLARE v_pos INT;
    DECLARE v_remaining VARCHAR(100);
    
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
        -- 업체 정보 수정
        UPDATE clients
        SET client_name = p_client_name,
            client_phone = p_client_phone,
            client_address = p_client_address,
            client_business_number = p_client_business_number,
            manager_name = p_manager_name,
            manager_mobile = p_manager_mobile,
            manager_position = p_manager_position,
            contracted_at = p_contracted_at,
            memo = p_memo,
            cleaning_yn = p_cleaning_yn,
            snack_yn = p_snack_yn,
            office_supplies_yn = p_office_supplies_yn,
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
        DATE_FORMAT(u.created_at, '%Y-%m-%d') AS create_date
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
-- Description: 사용자 등록 (관리자용)
-- =============================================

DROP PROCEDURE IF EXISTS set_user_insert$$

CREATE PROCEDURE set_user_insert(
    IN p_user_name VARCHAR(100),
    IN p_user_email VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_user_passwd VARCHAR(100)
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
        -- 사용자 등록
        INSERT INTO users (
            user_email,
            user_passwd,
            user_name,
            user_kind_id,
            user_mobile,
            use_yn, 
            created_at
        ) VALUES (
            p_user_email,
            UNHEX(SHA2(p_user_passwd, 512)),
            p_user_name,
            p_user_kind_id,
            p_user_mobile,
            1,
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
-- Description: 사용자 정보 수정 (휴대폰)
-- =============================================

DROP PROCEDURE IF EXISTS set_user_profile_update$$

CREATE PROCEDURE set_user_profile_update(
    IN p_user_id INT,
    IN p_user_mobile VARCHAR(100)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;
    
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
        UPDATE users
        SET user_mobile = p_user_mobile,
            updated_at = NOW()
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
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 정보 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_user_update$$

CREATE PROCEDURE set_user_update(
    IN p_user_id INT,
    IN p_user_name VARCHAR(100),
    IN p_user_email VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_user_passwd VARCHAR(100)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;
    DECLARE v_email_count INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 사용자 존재 여부 확인
    SELECT COUNT(*) INTO v_user_count
    FROM users
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;
    
    IF v_user_count = 0 THEN
        SET v_return_value = 4; -- 사용자 없음
    ELSE
        -- 이메일 중복 체크 (자신 제외)
        IF p_user_email IS NOT NULL AND p_user_email != '' THEN
            SELECT COUNT(*) INTO v_email_count
            FROM users
            WHERE user_email = p_user_email
              AND user_id != p_user_id
              AND deleted_at IS NULL;
            
            IF v_email_count > 0 THEN
                SET v_return_value = 2; -- 이메일 중복
            END IF;
        END IF;
        
        -- 중복이 없으면 사용자 정보 수정
        IF v_return_value = 0 THEN
            IF p_user_passwd IS NOT NULL AND p_user_passwd != '' THEN
                UPDATE users
                SET user_name = p_user_name,
                    user_email = p_user_email,
                    user_mobile = p_user_mobile,
                    user_kind_id = p_user_kind_id,
                    user_passwd = UNHEX(SHA2(p_user_passwd, 512)),
                    updated_at = NOW()
                WHERE user_id = p_user_id
                  AND deleted_at IS NULL;
            ELSE
                UPDATE users
                SET user_name = p_user_name,
                    user_email = p_user_email,
                    user_mobile = p_user_mobile,
                    user_kind_id = p_user_kind_id,
                    updated_at = NOW()
                WHERE user_id = p_user_id
                  AND deleted_at IS NULL;
            END IF;
            
            SET v_return_value = 1; -- 성공
        END IF;
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
-- Description: 사용자 비밀번호 확인
-- =============================================

DROP PROCEDURE IF EXISTS get_user_pass_confirm$$

CREATE PROCEDURE get_user_pass_confirm(
    IN p_user_id INT,
    IN p_old_passwd VARCHAR(100)
)
BEGIN
    DECLARE v_user_yn INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_user_yn
    FROM users
    WHERE user_id = p_user_id
      AND user_passwd = UNHEX(SHA2(p_old_passwd, 512))
      AND deleted_at IS NULL;
    
    SELECT v_user_yn AS UserYn;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 비밀번호 변경
-- =============================================

DROP PROCEDURE IF EXISTS set_user_pass_update$$

CREATE PROCEDURE set_user_pass_update(
    IN p_user_id INT,
    IN p_new_passwd VARCHAR(100)
)
BEGIN
    UPDATE users
    SET user_passwd = UNHEX(SHA2(p_new_passwd, 512)),
        updated_at = NOW()
    WHERE user_id = p_user_id
      AND deleted_at IS NULL;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-03
-- Email:       bonoman77@gmail.com 
-- Description: 사용자 프로필 상세 정보 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_user_profile$$

CREATE PROCEDURE get_user_profile(
    IN p_user_id INT
)
BEGIN
    SELECT 
        u.user_id,
        u.user_name,
        u.user_email,
        u.user_mobile,
        u.user_kind_id,
        u.use_yn,
        CASE 
            WHEN u.user_kind_id = 1 THEN 'admin'
            WHEN u.user_kind_id = 2 THEN 'staff'
            WHEN u.user_kind_id = 3 THEN 'client'
            ELSE 'user'
        END AS role,
        CASE 
            WHEN u.user_kind_id = 1 THEN '관리자'
            WHEN u.user_kind_id = 2 THEN '현장직원'
            WHEN u.user_kind_id = 3 THEN '업체담당자'
            ELSE '일반'
        END AS user_kind_name,
        c.client_name,
        c.client_id,
        DATE_FORMAT(u.admin_authed_at, '%Y-%m-%d %H:%i') AS admin_authed_at,
        DATE_FORMAT(u.created_at, '%Y-%m-%d %H:%i') AS joined_at,
        DATE_FORMAT(
            (SELECT login_at 
             FROM user_login_logs 
             WHERE user_id = p_user_id 
             ORDER BY login_at DESC 
             LIMIT 1), 
            '%Y-%m-%d %H:%i'
        ) AS last_login_at
    FROM users u
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE u.user_id = p_user_id
      AND u.deleted_at IS NULL;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-04
-- Email:       bonoman77@gmail.com 
-- Description: 관리자용 회원 정보 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_user_admin_update$$

CREATE PROCEDURE set_user_admin_update(
    IN p_user_id INT,
    IN p_user_name VARCHAR(100),
    IN p_user_mobile VARCHAR(100),
    IN p_user_kind_id INT,
    IN p_user_passwd VARCHAR(100)
)
BEGIN
    DECLARE v_return_value INT DEFAULT 0;
    DECLARE v_user_count INT DEFAULT 0;
    
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
        -- 비밀번호 변경 여부에 따라 업데이트
        IF p_user_passwd IS NOT NULL AND p_user_passwd != '' THEN
            UPDATE users
            SET user_name = p_user_name,
                user_mobile = p_user_mobile,
                user_kind_id = p_user_kind_id,
                user_passwd = UNHEX(SHA2(p_user_passwd, 512)),
                updated_at = NOW()
            WHERE user_id = p_user_id
              AND deleted_at IS NULL;
        ELSE
            UPDATE users
            SET user_name = p_user_name,
                user_mobile = p_user_mobile,
                user_kind_id = p_user_kind_id,
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
    IN p_office_supplies_yn INT
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
    IN p_office_supplies_yn INT
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

DELIMITER ;

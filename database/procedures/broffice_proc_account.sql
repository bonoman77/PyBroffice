USE Broffice$brobiz;

DELIMITER $$


-- =============================================
-- Author:      김승균
-- Create date: 2026-01-27
-- Email:       bonoman77@gmail.com 
-- Description: Broffice 사용자 로그인
-- =============================================

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
            CASE 
                WHEN p_user_kind_id = 3 THEN p_client_id 
                ELSE NULL 
            END,
            CASE 
                WHEN p_status IN ('active', 'pending') THEN 1 
                ELSE 0 
            END,
            CASE 
                WHEN p_status = 'active' THEN NOW() 
                ELSE NULL 
            END,
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
        DATE_FORMAT(u.created_at, '%Y-%m-%d %H:%i') AS created_at,
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


DELIMITER ;
USE Broffice$brobiz;

DELIMITER $$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 목록 조회 (페이징)
-- =============================================

DROP PROCEDURE IF EXISTS get_client_request_list$$

CREATE PROCEDURE get_client_request_list(
    IN p_user_kind_id INT,
    IN p_user_id INT,
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT DEFAULT 0;
    SET v_offset = (p_page - 1) * p_page_size;
    
    SELECT 
        cr.request_id,
        cr.user_id AS UserId,
        u.user_name AS UserName,
        COALESCE(c.client_name, '') AS ClientName,
        cr.title AS Title,
        cr.content AS Content,
        cr.admin_checked_at AS AdminCheckedAt,
        DATE_FORMAT(cr.created_at, '%Y-%m-%d') AS CreateDate
    FROM client_requests cr
    INNER JOIN users u ON cr.user_id = u.user_id
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE cr.deleted_at IS NULL
      AND (p_user_id = 0 OR cr.user_id = p_user_id)
    ORDER BY cr.created_at DESC
    LIMIT v_offset, p_page_size;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 전체 건수 조회 (페이징용)
-- =============================================

DROP PROCEDURE IF EXISTS get_client_request_list_count$$

CREATE PROCEDURE get_client_request_list_count(
    IN p_user_kind_id INT,
    IN p_user_id INT
)
BEGIN
    SELECT COUNT(*) AS total_count
    FROM client_requests cr
    INNER JOIN users u ON cr.user_id = u.user_id
    WHERE cr.deleted_at IS NULL
      AND (p_user_id = 0 OR cr.user_id = p_user_id);
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 내용 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_client_request_content$$

CREATE PROCEDURE get_client_request_content(
    IN p_request_id INT
)
BEGIN
    SELECT 
        cr.request_id,
        cr.title,
        cr.content,
        cr.admin_checked_at,
        cr.created_at
    FROM client_requests cr
    WHERE cr.request_id = p_request_id
      AND cr.deleted_at IS NULL;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_client_request_insert$$

CREATE PROCEDURE set_client_request_insert(
    IN p_user_id INT,
    IN p_title VARCHAR(200),
    IN p_content VARCHAR(3000)
)
BEGIN
    DECLARE v_request_id INT DEFAULT 0;
    
    START TRANSACTION;
    
    INSERT INTO client_requests (
        user_id,
        title,
        content,
        created_at
    ) VALUES (
        p_user_id,
        p_title,
        p_content,
        NOW()
    );
    
    SET v_request_id = LAST_INSERT_ID();
    
    COMMIT;
    
    SELECT v_request_id AS request_id;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_client_request_update$$

CREATE PROCEDURE set_client_request_update(
    IN p_request_id INT,
    IN p_title VARCHAR(200),
    IN p_content VARCHAR(3000)
)
BEGIN
    UPDATE client_requests
    SET title = p_title,
        content = p_content,
        updated_at = NOW()
    WHERE request_id = p_request_id
      AND deleted_at IS NULL;
    
    SELECT p_request_id AS request_id;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 업체 요청사항 삭제 (소프트 삭제)
-- =============================================

DROP PROCEDURE IF EXISTS set_client_request_delete$$

CREATE PROCEDURE set_client_request_delete(
    IN p_request_id INT
)
BEGIN
    UPDATE client_requests
    SET deleted_at = NOW()
    WHERE request_id = p_request_id
      AND deleted_at IS NULL;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 대시보드용 업체 요청사항 최근 N건
-- =============================================

DROP PROCEDURE IF EXISTS get_client_request_recent$$

CREATE PROCEDURE get_client_request_recent(
    IN p_user_id INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        cr.request_id,
        cr.user_id AS UserId,
        u.user_name AS UserName,
        COALESCE(c.client_name, '') AS ClientName,
        cr.title AS Title,
        cr.admin_checked_at AS AdminCheckedAt,
        DATE_FORMAT(cr.created_at, '%Y-%m-%d %H:%i') AS CreateDate
    FROM client_requests cr
    INNER JOIN users u ON cr.user_id = u.user_id
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE cr.deleted_at IS NULL
      AND (p_user_id = 0 OR cr.user_id = p_user_id)
    ORDER BY cr.created_at DESC
    LIMIT p_limit;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 관리자 확인 처리
-- =============================================

DROP PROCEDURE IF EXISTS set_client_request_check$$

CREATE PROCEDURE set_client_request_check(
    IN p_request_id INT
)
BEGIN
    UPDATE client_requests
    SET admin_checked_at = NOW()
    WHERE request_id = p_request_id
      AND deleted_at IS NULL
      AND admin_checked_at IS NULL;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$


DELIMITER ;

USE Broffice$brobiz;

DELIMITER $$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Email:       bonoman77@gmail.com 
-- Description: 공지사항 목록 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_list$$

CREATE PROCEDURE get_notice_list(
    IN p_user_kind_id INT
)
BEGIN
    SELECT 
        n.notice_id,
        u.user_name AS UserName,
        n.content AS Title,
        n.target_user_kind_id,
        CASE 
            WHEN n.target_user_kind_id = 0 THEN '전체'
            WHEN n.target_user_kind_id = 1 THEN '관리자'
            WHEN n.target_user_kind_id = 2 THEN '현장직원'
            WHEN n.target_user_kind_id = 3 THEN '업체담당자'
            ELSE '전체'
        END AS TargetUserKindName,
        n.top_expose_yn AS TopExposeYn,
        n.display_yn AS DisplayYn,
        DATE_FORMAT(n.created_at, '%Y-%m-%d') AS CreateDate
    FROM notices n
    INNER JOIN users u ON n.user_id = u.user_id
    WHERE n.deleted_at IS NULL
      AND n.display_yn = 1
      AND (n.target_user_kind_id = 0 OR n.target_user_kind_id = p_user_kind_id)
    ORDER BY n.top_expose_yn DESC, n.created_at DESC;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Email:       bonoman77@gmail.com 
-- Description: 공지사항 내용 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_content$$

CREATE PROCEDURE get_notice_content(
    IN p_notice_id INT
)
BEGIN
    SELECT 
        n.notice_id,
        n.content,
        n.target_user_kind_id,
        CASE 
            WHEN n.target_user_kind_id = 0 THEN '전체'
            WHEN n.target_user_kind_id = 1 THEN '관리자'
            WHEN n.target_user_kind_id = 2 THEN '현장직원'
            WHEN n.target_user_kind_id = 3 THEN '업체담당자'
            ELSE '전체'
        END AS TargetUserKindName,
        n.top_expose_yn,
        n.created_at
    FROM notices n
    WHERE n.notice_id = p_notice_id
      AND n.deleted_at IS NULL;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Email:       bonoman77@gmail.com 
-- Description: 공지사항 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_notice_insert$$

CREATE PROCEDURE set_notice_insert(
    IN p_user_id INT,
    IN p_target_user_kind_id INT,
    IN p_content NVARCHAR(3000),
    IN p_top_expose_yn TINYINT(1),
    IN p_display_yn TINYINT(1)
)
BEGIN
    DECLARE v_notice_id INT DEFAULT 0;
    
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- 공지사항 등록
    INSERT INTO notices (
        user_id,
        target_user_kind_id,
        content,
        top_expose_yn,
        display_yn,
        created_at
    ) VALUES (
        p_user_id,
        p_target_user_kind_id,
        p_content,
        p_top_expose_yn,
        p_display_yn,
        NOW()
    );
    
    SET v_notice_id = LAST_INSERT_ID();
    
    -- 트랜잭션 커밋
    COMMIT;
    
    -- 결과 반환
    SELECT v_notice_id AS notice_id;
    
END$$


DELIMITER ;

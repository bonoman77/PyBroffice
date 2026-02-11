USE Broffice$brobiz;

DELIMITER $$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Description: 공지사항 목록 조회 (p_writer_kind_id: 작성자 유형 필터, 0이면 전체)
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_list$$

CREATE PROCEDURE get_notice_list(
    IN p_user_kind_id INT,
    IN p_writer_kind_id INT,
    IN p_user_id INT,
    IN p_page INT,
    IN p_page_size INT
)
BEGIN
    DECLARE v_offset INT DEFAULT 0;
    SET v_offset = (p_page - 1) * p_page_size;
    
    SELECT 
        n.notice_id,
        n.user_id AS UserId,
        u.user_name AS UserName,
        COALESCE(c.client_name, '') AS ClientName,
        n.title AS Title,
        n.content AS Content,
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
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE n.deleted_at IS NULL
      AND (p_user_kind_id = 1 OR n.display_yn = 1)
      AND (p_user_kind_id = 1 OR n.target_user_kind_id = 0 OR n.target_user_kind_id = p_user_kind_id)
      AND (p_writer_kind_id = 0 OR u.user_kind_id = p_writer_kind_id)
      AND (p_user_id = 0 OR n.user_id = p_user_id)
    ORDER BY n.top_expose_yn DESC, n.created_at DESC
    LIMIT v_offset, p_page_size;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 공지사항 전체 건수 조회 (페이징용)
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_list_count$$

CREATE PROCEDURE get_notice_list_count(
    IN p_user_kind_id INT,
    IN p_writer_kind_id INT,
    IN p_user_id INT
)
BEGIN
    SELECT COUNT(*) AS total_count
    FROM notices n
    INNER JOIN users u ON n.user_id = u.user_id
    WHERE n.deleted_at IS NULL
      AND (p_user_kind_id = 1 OR n.display_yn = 1)
      AND (p_user_kind_id = 1 OR n.target_user_kind_id = 0 OR n.target_user_kind_id = p_user_kind_id)
      AND (p_writer_kind_id = 0 OR u.user_kind_id = p_writer_kind_id)
      AND (p_user_id = 0 OR n.user_id = p_user_id);
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Description: 공지사항 내용 조회
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_content$$

CREATE PROCEDURE get_notice_content(
    IN p_notice_id INT
)
BEGIN
    SELECT 
        n.notice_id,
        n.title,
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
        n.display_yn,
        DATE_FORMAT(n.created_at, '%Y-%m-%d %H:%i:%s') AS create_date
    FROM notices n
    WHERE n.notice_id = p_notice_id
      AND n.deleted_at IS NULL;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-06
-- Description: 공지사항 등록
-- =============================================

DROP PROCEDURE IF EXISTS set_notice_insert$$

CREATE PROCEDURE set_notice_insert(
    IN p_user_id INT,
    IN p_target_user_kind_id INT,
    IN p_title VARCHAR(200),
    IN p_content TEXT,
    IN p_top_expose_yn TINYINT(1),
    IN p_display_yn TINYINT(1)
)
BEGIN
    DECLARE v_notice_id INT DEFAULT 0;
    
    START TRANSACTION;
    
    INSERT INTO notices (
        user_id,
        target_user_kind_id,
        title,
        content,
        top_expose_yn,
        display_yn,
        created_at
    ) VALUES (
        p_user_id,
        p_target_user_kind_id,
        p_title,
        p_content,
        p_top_expose_yn,
        p_display_yn,
        NOW()
    );
    
    SET v_notice_id = LAST_INSERT_ID();
    
    COMMIT;
    
    SELECT v_notice_id AS notice_id;
    
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 대시보드 KPI (계약업체수, 청소/간식/비품 업체수)
-- =============================================

DROP PROCEDURE IF EXISTS get_dashboard_kpi$$

CREATE PROCEDURE get_dashboard_kpi()
BEGIN
    SELECT 
        COUNT(*) AS total_client_count,
        SUM(CASE WHEN cleaning_yn = 1 THEN 1 ELSE 0 END) AS cleaning_count,
        SUM(CASE WHEN snack_yn = 1 THEN 1 ELSE 0 END) AS snack_count,
        SUM(CASE WHEN office_supplies_yn = 1 THEN 1 ELSE 0 END) AS supplies_count
    FROM clients
    WHERE use_yn = 1
      AND deleted_at IS NULL;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 대시보드용 업체 요청사항 (user_kind_id=3이 쓴 것만)
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_list_by_writer_kind$$

CREATE PROCEDURE get_notice_list_by_writer_kind(
    IN p_writer_kind_id INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        n.notice_id,
        u.user_name AS UserName,
        COALESCE(c.client_name, '') AS ClientName,
        n.title AS Title,
        n.content AS Content,
        n.target_user_kind_id,
        n.top_expose_yn AS TopExposeYn,
        n.display_yn AS DisplayYn,
        DATE_FORMAT(n.created_at, '%Y-%m-%d %H:%i') AS CreateDate
    FROM notices n
    INNER JOIN users u ON n.user_id = u.user_id
    LEFT JOIN clients c ON u.client_id = c.client_id
    WHERE n.deleted_at IS NULL
      AND u.user_kind_id = p_writer_kind_id
    ORDER BY n.created_at DESC
    LIMIT p_limit;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 공지사항 수정
-- =============================================

DROP PROCEDURE IF EXISTS set_notice_update$$

CREATE PROCEDURE set_notice_update(
    IN p_notice_id INT,
    IN p_target_user_kind_id INT,
    IN p_title VARCHAR(200),
    IN p_content TEXT,
    IN p_top_expose_yn TINYINT(1),
    IN p_display_yn TINYINT(1)
)
BEGIN
    UPDATE notices
    SET target_user_kind_id = p_target_user_kind_id,
        title = p_title,
        content = p_content,
        top_expose_yn = p_top_expose_yn,
        display_yn = p_display_yn,
        updated_at = NOW()
    WHERE notice_id = p_notice_id
      AND deleted_at IS NULL;
    
    SELECT p_notice_id AS notice_id;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 공지사항 삭제 (소프트 삭제)
-- =============================================

DROP PROCEDURE IF EXISTS set_notice_delete$$

CREATE PROCEDURE set_notice_delete(
    IN p_notice_id INT
)
BEGIN
    UPDATE notices
    SET deleted_at = NOW()
    WHERE notice_id = p_notice_id
      AND deleted_at IS NULL;
    
    SELECT ROW_COUNT() AS affected_rows;
END$$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 대시보드 이번달 스케줄 수 (task_kind_id별)
-- =============================================

DROP PROCEDURE IF EXISTS get_dashboard_schedule_count$$

CREATE PROCEDURE get_dashboard_schedule_count(
    IN p_year_month VARCHAR(7)
)
BEGIN
    SELECT 
        SUM(CASE WHEN t.task_kind_id = 4 THEN 1 ELSE 0 END) AS cleaning_total,
        SUM(CASE WHEN t.task_kind_id = 4 AND ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS cleaning_completed,
        SUM(CASE WHEN t.task_kind_id = 5 THEN 1 ELSE 0 END) AS snack_total,
        SUM(CASE WHEN t.task_kind_id = 5 AND ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS snack_completed,
        SUM(CASE WHEN t.task_kind_id = 6 THEN 1 ELSE 0 END) AS supplies_total,
        SUM(CASE WHEN t.task_kind_id = 6 AND ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS supplies_completed
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    WHERE DATE_FORMAT(ts.scheduled_at, '%Y-%m') = p_year_month
      AND ts.canceled_at = 0
      AND t.deleted_at IS NULL;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-11
-- Description: 대시보드용 공지사항 (target_user_kind_id 기준)
-- =============================================

DROP PROCEDURE IF EXISTS get_notice_list_by_target$$

CREATE PROCEDURE get_notice_list_by_target(
    IN p_target_user_kind_id INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        n.notice_id,
        u.user_name AS UserName,
        n.title AS Title,
        n.content AS Content,
        n.target_user_kind_id,
        n.top_expose_yn AS TopExposeYn,
        n.display_yn AS DisplayYn,
        DATE_FORMAT(n.created_at, '%Y-%m-%d') AS CreateDate
    FROM notices n
    INNER JOIN users u ON n.user_id = u.user_id
    WHERE n.deleted_at IS NULL
      AND n.display_yn = 1
      AND (n.target_user_kind_id = 0 OR n.target_user_kind_id = p_target_user_kind_id)
    ORDER BY n.top_expose_yn DESC, n.created_at DESC
    LIMIT p_limit;
END$$


DELIMITER ;

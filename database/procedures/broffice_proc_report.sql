DELIMITER $$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: 리포트 - 월별 작업 종합 통계
-- =============================================

DROP PROCEDURE IF EXISTS get_report_monthly_summary$$

CREATE PROCEDURE get_report_monthly_summary(
    IN p_year_month VARCHAR(7),
    IN p_manage_user_id INT
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
        SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN ts.completed_at IS NULL AND ts.canceled_at IS NULL 
                  AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) < NOW() THEN 1 ELSE 0 END) AS overdue_count,
        SUM(CASE WHEN ts.completed_at IS NULL AND ts.canceled_at IS NULL 
                  AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= NOW() THEN 1 ELSE 0 END) AS pending_count,
        SUM(CASE WHEN ts.canceled_at IS NOT NULL THEN 1 ELSE 0 END) AS canceled_count,
        ROUND(SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS completion_rate
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    WHERE t.deleted_at IS NULL
      AND (p_manage_user_id = 0 OR c.manage_user_id = p_manage_user_id)
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
    GROUP BY t.task_kind_id
    ORDER BY t.task_kind_id;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: 리포트 - 업체별 작업 현황
-- =============================================

DROP PROCEDURE IF EXISTS get_report_by_client$$

CREATE PROCEDURE get_report_by_client(
    IN p_year_month VARCHAR(7),
    IN p_task_kind_id INT,
    IN p_manage_user_id INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        c.client_id,
        c.client_name,
        COUNT(*) AS total_count,
        SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN ts.completed_at IS NULL AND ts.canceled_at IS NULL THEN 1 ELSE 0 END) AS incomplete_count,
        ROUND(SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS completion_rate,
        SUM(CASE WHEN t.task_kind_id = 4 THEN 1 ELSE 0 END) AS cleaning_count,
        SUM(CASE WHEN t.task_kind_id = 5 THEN 1 ELSE 0 END) AS snack_count,
        SUM(CASE WHEN t.task_kind_id = 6 THEN 1 ELSE 0 END) AS supplies_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    WHERE t.deleted_at IS NULL
      AND c.deleted_at IS NULL
      AND (p_task_kind_id = 0 OR t.task_kind_id = p_task_kind_id)
      AND (p_manage_user_id = 0 OR c.manage_user_id = p_manage_user_id)
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
    GROUP BY c.client_id, c.client_name
    ORDER BY total_count DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: 리포트 - 직원별 작업 현황
-- =============================================

DROP PROCEDURE IF EXISTS get_report_by_worker$$

CREATE PROCEDURE get_report_by_worker(
    IN p_year_month VARCHAR(7),
    IN p_task_kind_id INT,
    IN p_manage_user_id INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        u.user_id,
        u.user_name,
        COUNT(*) AS total_count,
        SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed_count,
        SUM(CASE WHEN ts.completed_at IS NULL AND ts.canceled_at IS NULL THEN 1 ELSE 0 END) AS incomplete_count,
        ROUND(SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS completion_rate,
        SUM(CASE WHEN t.task_kind_id = 4 THEN 1 ELSE 0 END) AS cleaning_count,
        SUM(CASE WHEN t.task_kind_id = 5 THEN 1 ELSE 0 END) AS snack_count,
        SUM(CASE WHEN t.task_kind_id = 6 THEN 1 ELSE 0 END) AS supplies_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    LEFT JOIN users u ON ts.user_id = u.user_id
    INNER JOIN clients c ON t.client_id = c.client_id
    WHERE t.deleted_at IS NULL
      AND (p_task_kind_id = 0 OR t.task_kind_id = p_task_kind_id)
      AND (p_manage_user_id = 0 OR c.manage_user_id = p_manage_user_id)
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
    GROUP BY u.user_id, u.user_name
    ORDER BY total_count DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: 리포트 - 일별 작업 추이 (차트용)
-- =============================================

DROP PROCEDURE IF EXISTS get_report_daily_trend$$

CREATE PROCEDURE get_report_daily_trend(
    IN p_year_month VARCHAR(7),
    IN p_task_kind_id INT,
    IN p_manage_user_id INT
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        DATE_FORMAT(COALESCE(ts.change_scheduled_at, ts.scheduled_at), '%Y-%m-%d') AS work_date,
        COUNT(*) AS total_count,
        SUM(CASE WHEN ts.completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed_count
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    WHERE t.deleted_at IS NULL
      AND ts.canceled_at IS NULL
      AND (p_task_kind_id = 0 OR t.task_kind_id = p_task_kind_id)
      AND (p_manage_user_id = 0 OR c.manage_user_id = p_manage_user_id)
      AND (COALESCE(ts.change_scheduled_at, ts.scheduled_at) >= v_start_date 
           AND COALESCE(ts.change_scheduled_at, ts.scheduled_at) <= v_end_date)
    GROUP BY work_date
    ORDER BY work_date;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: 리포트 - 관리직원 목록 조회 (clients.manage_user_id 기준)
-- =============================================

DROP PROCEDURE IF EXISTS get_report_managers$$

CREATE PROCEDURE get_report_managers()
BEGIN
    SELECT DISTINCT
        u.user_id,
        u.user_name
    FROM clients c
    INNER JOIN users u ON c.manage_user_id = u.user_id AND u.deleted_at IS NULL
    WHERE c.deleted_at IS NULL
      AND c.use_yn = 1
    ORDER BY u.user_name;
END$$


DELIMITER ;

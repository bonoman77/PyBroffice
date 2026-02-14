DELIMITER $$

-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: SMS - 업무완료 시 발송 대상 정보 조회
--              (관리팀장 + 업체담당자 연락처)
-- =============================================

DROP PROCEDURE IF EXISTS get_sns_recipients$$

CREATE PROCEDURE get_sns_recipients(
    IN p_task_schedule_id INT
)
BEGIN
    -- 관리팀장 (clients.manage_user_id)
    SELECT 
        'manager' AS recipient_type,
        mu.user_id,
        mu.user_name,
        mu.user_mobile,
        c.client_id,
        c.client_name,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        DATE_FORMAT(ts.scheduled_date, '%Y-%m-%d') AS work_date,
        IFNULL(wu.user_name, '') AS worker_name
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    INNER JOIN users mu ON c.manage_user_id = mu.user_id AND mu.deleted_at IS NULL
    LEFT JOIN users wu ON ts.user_id = wu.user_id
    WHERE ts.task_schedule_id = p_task_schedule_id

    UNION ALL

    -- 업체담당자 (clients.contractor_mobile)
    SELECT 
        'client' AS recipient_type,
        0 AS user_id,
        c.contractor_name AS user_name,
        c.contractor_mobile AS user_mobile,
        c.client_id,
        c.client_name,
        t.task_kind_id,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name,
        DATE_FORMAT(ts.scheduled_date, '%Y-%m-%d') AS work_date,
        IFNULL(wu.user_name, '') AS worker_name
    FROM task_schedules ts
    INNER JOIN tasks t ON ts.task_id = t.task_id
    INNER JOIN clients c ON t.client_id = c.client_id
    LEFT JOIN users wu ON ts.user_id = wu.user_id
    WHERE ts.task_schedule_id = p_task_schedule_id
      AND c.contractor_mobile IS NOT NULL
      AND c.contractor_mobile != '';
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: SMS - 발송 로그 저장
-- =============================================

DROP PROCEDURE IF EXISTS insert_task_sns_log$$

CREATE PROCEDURE insert_task_sns_log(
    IN p_user_id INT,
    IN p_task_schedule_id INT,
    IN p_from_mobile VARCHAR(100),
    IN p_to_mobile VARCHAR(100),
    IN p_content VARCHAR(500),
    IN p_scheduled_send_at DATETIME,
    IN p_send_status VARCHAR(100),
    IN p_twilio_sid VARCHAR(100),
    IN p_twilio_status VARCHAR(100)
)
BEGIN
    INSERT INTO task_sns_logs (
        user_id, task_schedule_id, from_mobile, to_mobile,
        content, scheduled_send_at, send_status,
        twilio_sid, twilio_status, created_at
    ) VALUES (
        p_user_id, p_task_schedule_id, p_from_mobile, p_to_mobile,
        p_content, p_scheduled_send_at, p_send_status,
        p_twilio_sid, p_twilio_status, NOW()
    );
    
    SELECT LAST_INSERT_ID() AS task_sns_log_id;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: SMS - 발송 로그 상태 업데이트
-- =============================================

DROP PROCEDURE IF EXISTS update_task_sns_log$$

CREATE PROCEDURE update_task_sns_log(
    IN p_task_sns_log_id INT,
    IN p_sent_at DATETIME,
    IN p_send_status VARCHAR(100),
    IN p_twilio_sid VARCHAR(100),
    IN p_twilio_status VARCHAR(100),
    IN p_twilio_error_code VARCHAR(100),
    IN p_twilio_error_message VARCHAR(100)
)
BEGIN
    UPDATE task_sns_logs
    SET sent_at = p_sent_at,
        send_status = p_send_status,
        twilio_sid = p_twilio_sid,
        twilio_status = p_twilio_status,
        twilio_error_code = p_twilio_error_code,
        twilio_error_message = p_twilio_error_message,
        updated_at = NOW()
    WHERE task_sns_log_id = p_task_sns_log_id;
    
    SELECT ROW_COUNT() AS return_value;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: SMS - 발송 예정/완료 내역 조회 (리포트용)
-- =============================================

DROP PROCEDURE IF EXISTS get_sns_log_list$$

CREATE PROCEDURE get_sns_log_list(
    IN p_year_month VARCHAR(7),
    IN p_send_status VARCHAR(100)
)
BEGIN
    DECLARE v_start_date DATE;
    DECLARE v_end_date DATE;
    
    SET v_start_date = STR_TO_DATE(CONCAT(p_year_month, '-01'), '%Y-%m-%d');
    SET v_end_date = LAST_DAY(v_start_date);
    
    SELECT 
        sl.task_sns_log_id,
        sl.user_id,
        IFNULL(u.user_name, sl.to_mobile) AS recipient_name,
        sl.task_schedule_id,
        sl.from_mobile,
        sl.to_mobile,
        sl.content,
        DATE_FORMAT(sl.scheduled_send_at, '%Y-%m-%d %H:%i') AS scheduled_send_at,
        DATE_FORMAT(sl.sent_at, '%Y-%m-%d %H:%i') AS sent_at,
        sl.send_status,
        sl.twilio_sid,
        sl.twilio_status,
        sl.twilio_error_code,
        sl.twilio_error_message,
        DATE_FORMAT(sl.created_at, '%Y-%m-%d %H:%i') AS created_at,
        c.client_name,
        CASE t.task_kind_id
            WHEN 4 THEN '청소'
            WHEN 5 THEN '간식'
            WHEN 6 THEN '비품'
            ELSE '기타'
        END AS task_kind_name
    FROM task_sns_logs sl
    LEFT JOIN users u ON sl.user_id = u.user_id
    LEFT JOIN task_schedules ts ON sl.task_schedule_id = ts.task_schedule_id
    LEFT JOIN tasks t ON ts.task_id = t.task_id
    LEFT JOIN clients c ON t.client_id = c.client_id
    WHERE sl.scheduled_send_at >= v_start_date
      AND sl.scheduled_send_at <= DATE_ADD(v_end_date, INTERVAL 1 DAY)
      AND (p_send_status = '' OR sl.send_status = p_send_status)
    ORDER BY sl.scheduled_send_at DESC;
END$$


-- =============================================
-- Author:      김승균
-- Create date: 2026-02-13
-- Email:       bonoman77@gmail.com 
-- Description: SMS - 예약 발송 대기 건 조회 (스케줄러용)
-- =============================================

DROP PROCEDURE IF EXISTS get_pending_sns_logs$$

CREATE PROCEDURE get_pending_sns_logs()
BEGIN
    SELECT 
        sl.task_sns_log_id,
        sl.to_mobile,
        sl.content,
        sl.scheduled_send_at
    FROM task_sns_logs sl
    WHERE sl.send_status = 'scheduled'
      AND sl.scheduled_send_at <= NOW()
    ORDER BY sl.scheduled_send_at ASC;
END$$


DELIMITER ;

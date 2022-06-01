SELECT * FROM sys.dm_exec_requests
WHERE session_id > 50
GO

SELECT * FROM sys.dm_os_latch_stats
ORDER BY waiting_requests_count DESC

SELECT yield_count, * FROM sys.dm_os_schedulers
GO

SELECT * FROM sys.dm_os_threads
WHERE thread_address = 0x00000091681E88C8
GO


SELECT * FROM sys.dm_os_waiting_tasks
WHERE session_id > 50
GO

SELECT * FROM sys.dm_io_pending_io_requests
GO

SELECT * FROM sys.dm_os_workers

-- Query per scheduler...
SELECT 
a.scheduler_id ,
b.session_id,
(SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
( (CASE WHEN statement_end_offset = -1 
THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
ELSE statement_end_offset END) - statement_start_offset) / 2+1)) AS sql_statement
FROM sys.dm_os_schedulers a 
INNER JOIN sys.dm_os_tasks b on a.active_worker_address = b.worker_address
INNER JOIN sys.dm_exec_requests c on b.task_address = c.task_address
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) AS s2 
GO

SELECT   
    t1.session_id,
    t4.program_name,
    CONVERT(varchar(10), t1.status) AS status,  
    CONVERT(varchar(15), t1.command) AS command,  
    t5.scheduler_id,
    t5.current_tasks_count,
    t5.runnable_tasks_count,
    t5.current_workers_count,
    t5.work_queue_count,
    t5.active_workers_count,
    t5.yield_count,
    t5.last_timer_activity,
    t5.load_factor,
    CONVERT(varchar(10), t2.state) AS worker_state, 
    w_suspended =   
      CASE t2.wait_started_ms_ticks  
        WHEN 0 THEN 0  
        ELSE   
          t3.ms_ticks - t2.wait_started_ms_ticks  
      END,  
    w_runnable =   
      CASE t2.wait_resumed_ms_ticks  
        WHEN 0 THEN 0  
        ELSE   
          t3.ms_ticks - t2.wait_resumed_ms_ticks  
      END  
  FROM sys.dm_exec_requests AS t1  
  INNER JOIN sys.dm_os_workers AS t2  
    ON t2.task_address = t1.task_address  
  CROSS JOIN sys.dm_os_sys_info AS t3  
  INNER JOIN sys.dm_exec_sessions t4
    ON t1.session_id = t4.session_id
  INNER JOIN sys.dm_os_schedulers t5
    ON t5.scheduler_id = t1.scheduler_id
  WHERE t1.scheduler_id IS NOT NULL
    AND t1.session_id > 50 AND t1.session_id <> @@spid
ORDER BY worker_state


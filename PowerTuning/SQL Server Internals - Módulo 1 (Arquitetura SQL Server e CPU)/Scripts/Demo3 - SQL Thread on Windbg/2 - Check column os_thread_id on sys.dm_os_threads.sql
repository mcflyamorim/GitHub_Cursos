SELECT   
    t1.session_id,
    t3.os_thread_id,
    CONVERT(VARBINARY(MAX), t3.os_thread_id) binThreadID,
    CONVERT(varchar(10), t1.status) AS status,  
    CONVERT(varchar(15), t1.command) AS command
  FROM sys.dm_exec_requests AS t1  
  LEFT OUTER JOIN sys.dm_os_workers AS t2  
    ON t2.task_address = t1.task_address  
  LEFT OUTER JOIN sys.dm_os_threads t3
  on t3.thread_address = t2.thread_address
GO

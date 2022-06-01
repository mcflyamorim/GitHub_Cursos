-- Tarefas esperando...
SELECT * FROM sys.dm_os_waiting_tasks
join sys.dm_exec_sessions es
on dm_os_waiting_tasks.session_id = es.session_id
and es.is_user_process = 1
GO

-- Lastwaittype
SELECT * FROM master.dbo.sysprocesses
join sys.dm_exec_sessions es
on sysprocesses.spid = es.session_id
and es.is_user_process = 1
GO

SELECT
    [er].[session_id],
    [es].[program_name],
    [est].text,
    [er].[database_id],
    [eqp].[query_plan],
    [er].[cpu_time], 
    [er].[last_Wait_type]
FROM sys.dm_exec_requests [er]
INNER JOIN sys.dm_exec_sessions [es] ON
    [es].[session_id] = [er].[session_id]
OUTER APPLY sys.dm_exec_sql_text ([er].[sql_handle]) [est]
OUTER APPLY sys.dm_exec_query_plan ([er].[plan_handle]) [eqp]
WHERE
    [es].[is_user_process] = 1
    AND [er].[last_Wait_type] = N'SOS_SCHEDULER_YIELD'
ORDER BY
    [er].[session_id];
GO


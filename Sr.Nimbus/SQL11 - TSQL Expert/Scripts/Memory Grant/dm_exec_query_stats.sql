SELECT *
FROM sys.dm_exec_query_stats s
CROSS APPLY sys.dm_exec_sql_text( s.sql_handle ) t
GO 

SELECT *
FROM sys.dm_exec_query_stats
WHERE
    plan_handle IN
    (
        SELECT
            plan_handle
        FROM sys.dm_exec_requests
        WHERE
            session_id = 56
    )
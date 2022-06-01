
-- Qual o máximo de threads ? 
-- dm_os_sys_info.max_workers_count
SELECT cpu_count AS [Logical CPU Count], scheduler_count, hyperthread_ratio AS [Hyperthread Ratio],
cpu_count/hyperthread_ratio AS [Physical CPU Count], 
max_workers_count AS [Max Workers Count]
FROM sys.dm_os_sys_info 
GO

-- Quantas queries conseguimos rodar antes de bater o limite?... 
-- dm_os_nodes.active_worker_count
SELECT node_id, node_state_desc, active_worker_count
FROM sys.dm_os_nodes  
WHERE node_state_desc <> N'ONLINE DAC' 
GO

-- Tarefas esperando...
SELECT * FROM sys.dm_os_waiting_tasks
join sys.dm_exec_sessions es
on dm_os_waiting_tasks.session_id = es.session_id
and es.is_user_process = 1
GO

-- Sessão rodando o update está com status slepping
SELECT session_id, status FROM sys.dm_exec_sessions
WHERE session_id = 71 -- ID da sessão rodando o update


dbcc sqlperf('sys.dm_os_wait_stats' , CLEAR)
go
select wait_type, waiting_tasks_count, cast((cast(wait_time_ms as float)/waiting_tasks_count) as float) as avg_wait_time_ms, 
wait_time_ms, signal_wait_time_ms
from sys.dm_os_wait_stats
where wait_type = 'THREADPOOL'
AND waiting_tasks_count > 0
go

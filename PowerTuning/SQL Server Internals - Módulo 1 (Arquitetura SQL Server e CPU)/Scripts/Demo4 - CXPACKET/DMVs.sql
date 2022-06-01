-- Show only user tasks that are waiting
--
select wt.waiting_task_address, wt.session_id, wt.exec_context_id, wt.wait_type, 
wt.wait_duration_ms, wt.resource_description 
from sys.dm_os_waiting_tasks wt
join sys.dm_exec_sessions es
on wt.session_id = es.session_id
and es.is_user_process = 1
go
--
-- Show user tasks
--
select t.session_id, t.request_id, t.exec_context_id, t.task_state, t.scheduler_id, 
t.task_address, 
t.parent_task_address
from sys.dm_os_tasks t
join sys.dm_exec_sessions es
on t.session_id = es.session_id
and es.is_user_process = 1
go

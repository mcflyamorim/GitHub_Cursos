----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

USE [master]
GO
if exists (select * from sysdatabases where name='Fabiano_Test_Async_IO_Completion')
BEGIN
  ALTER DATABASE Fabiano_Test_Async_IO_Completion SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_Async_IO_Completion
end
GO
-- Criando banco pra testes
-- +-20 segundos pra rodar... 
CREATE DATABASE Fabiano_Test_Async_IO_Completion
 ON  PRIMARY 
( NAME = N'Fabiano_Test_Async_IO_Completion_1', FILENAME = N'E:\Fabiano_Test_Async_IO_Completion_1.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Fabiano_Test_Async_IO_Completion_log', FILENAME = N'E:\Fabiano_Test_Async_IO_Completion_log.ldf' , SIZE = 10MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO


-- Enquanto o create database está rodando, consultar as seguintes DMVs
-- pra ver o Wait e as threads fazendo as escritas...
DECLARE @SPID INT = 56 -- SPID da sessão rodando o backup

SELECT session_id, start_time, status, command, wait_type, wait_time, last_wait_type, wait_resource 
FROM sys.dm_exec_requests
WHERE session_id = @SPID;

SELECT waiting_task_address, session_id, wait_duration_ms, wait_type, resource_address
FROM sys.dm_os_waiting_tasks
WHERE session_id = @SPID
ORDER BY exec_context_id;

SELECT dm_os_tasks.session_id, 
       dm_os_threads.os_thread_id,
       dm_os_tasks.exec_context_id,
       dm_os_tasks.pending_io_count,
       dm_os_tasks.scheduler_id,
       dm_os_workers.last_wait_type,
       dm_os_workers.pending_io_count,
       '~~[' + CONVERT(varchar(20), CONVERT(VARBINARY(20), dm_os_threads.os_thread_id), 2) + ']k' AS windbgcommand
FROM sys.dm_os_tasks
INNER JOIN sys.dm_os_workers
ON dm_os_workers.task_address = dm_os_tasks.task_address
LEFT OUTER JOIN sys.dm_os_threads
  on dm_os_threads.thread_address = dm_os_workers.thread_address
WHERE session_id = @SPID
ORDER BY dm_os_tasks.session_id desc, exec_context_id ASC;
GO

/*
  Vamos analisar o resultado da query em dm_os_threads

  session_id start_time              status      command          wait_type              wait_time   last_wait_type       wait_resource
  ---------- ----------------------- ----------- ---------------- ---------------------- ----------- -------------------- ------------------------
  56         2020-07-27 12:56:51.620 suspended   CREATE DATABASE  ASYNC_IO_COMPLETION    7180        ASYNC_IO_COMPLETION  

  waiting_task_address session_id wait_duration_ms     wait_type                      resource_address
  -------------------- ---------- -------------------- ------------------------------ ------------------
  0x000002B25D202108   56         7181                 ASYNC_IO_COMPLETION            0x0000000000000001
  0x000002B26F694CA8   56         7091                 PREEMPTIVE_OS_WRITEFILEGATHER  NULL

  session_id os_thread_id exec_context_id pending_io_count scheduler_id last_wait_type                  pending_io_count windbgcommand
  ---------- ------------ --------------- ---------------- ------------ ------------------------------- ---------------- -------------------------
  56         15948        0               0                7            ASYNC_IO_COMPLETION             76               ~~[00003E4C]k
  56         12980        1               32               8            PREEMPTIVE_OS_WRITEFILEGATHER   181              ~~[000032B4]k

*/


-- DROP EVENT SESSION CapturaAsync_IO_Completion ON SERVER 
CREATE EVENT SESSION CapturaAsync_IO_Completion ON SERVER
ADD EVENT sqlos.wait_completed
(
    ACTION ([package0].[callstack])
    WHERE [wait_type]=(178) -- somente ASYNC_IO_COMPLETION
)
ADD TARGET package0.ring_buffer
WITH(MAX_DISPATCH_LATENCY = 1 SECONDS)
GO
-- Inicia evento
ALTER EVENT SESSION CapturaAsync_IO_Completion ON SERVER
STATE = START;
GO

-- Rodar Create DB novamente

-- Ver dados coletados no evento...
SELECT
    [event_session_address],
    [target_name],
    [execution_count],
    CAST ([target_data] AS XML)
FROM sys.dm_xe_session_targets [xst]
INNER JOIN sys.dm_xe_sessions [xs]
    ON [xst].[event_session_address] = [xs].[address]
WHERE [xs].[name] = N'CapturaAsync_IO_Completion';
GO

-- Copiar symbols na mesma pasta do processo do sqlservr.exe
-- "D\Symbols\sqlservr.pdb\" -> "C:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019\MSSQL\Binn"
-- NOTE: Parece que o SQL está conseguindo resolver mesmo sem eu ter os simbolos na pasta Binn... 
-- ainda não sei como... talvez devido a eu ter o Debugging Tools for Windows instalado...
-- anyway, na dúvida, copia lá que não dói nada...

-- Ligar TFs 3656 e 2592 pra usar os symbols 
DBCC TRACEON (3656, 2592, -1)  
GO
-- Ver dados coletados no evento...
SELECT
    [event_session_address],
    [target_name],
    [execution_count],
    CAST ([target_data] AS XML)
FROM sys.dm_xe_session_targets [xst]
INNER JOIN sys.dm_xe_sessions [xs]
    ON [xst].[event_session_address] = [xs].[address]
WHERE [xs].[name] = N'CapturaAsync_IO_Completion';
GO
DBCC TRACEOFF(3656, 2592, -1)  
GO
-- Fica fácil de ver que o Wait é relacionado com o create database
-- sqllang.dll!DBDDLAgent::CreateDatabase
/*
sqldk.dll!SOS_OS::TriggerDump+0x9318
sqldk.dll!SOS_Scheduler::PromotePendingTask+0x2d1
sqldk.dll!SOS_Task::PostWait+0x64
sqldk.dll!WaitableBase::Wait+0x132
sqlmin.dll!BootPagePtr::~BootPagePtr+0x181f
sqlmin.dll!AsyncWorkerPool::DoWork+0x9
sqlmin.dll!DBMgr::CreateAndFormatFiles+0x3c8
sqllang.dll!CSQLObject::Parse+0xa03e
sqllang.dll!DBDDLAgent::CreateDatabase+0x169
sqllang.dll!ShouldBdcSendDBOperationRequestForSystemAG+0x15fa
sqllang.dll!CSQLSource::Execute+0x13d8
sqllang.dll!CSQLSource::Execute+0xe18
sqllang.dll!CSQLSource::Execute+0x463
sqllang.dll!CSQLSource::FError+0x142d
sqllang.dll!SNIPacketRelease+0x10e5
sqllang.dll!SNIPacketRelease+0xec3
sqldk.dll!MemoryPoolManager::AllocatePages+0xc83
sqldk.dll!OsInfo::IsXPlatInstance+0x4bd
sqldk.dll!OsInfo::IsXPlatInstance+0x2c5
sqldk.dll!SystemThread::MakeMiniSOSThread+0x770
sqldk.dll!SystemThread::MakeMiniSOSThread+0x127b
sqldk.dll!SystemThread::MakeMiniSOSThread+0x1081
KERNEL32.DLL!BaseThreadInitThunk+0x14
ntdll.dll!RtlUserThreadStart+0x21</value>
*/

-- Cleanup
DROP EVENT SESSION CapturaAsync_IO_Completion ON SERVER 
GO

/*

Ou, usar o https://github.com/microsoft/SQLCallStackResolver
... BEM mais fácil e da pra fazer "offline"...

*/
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
if exists (select * from sysdatabases where name='Fabiano_Test_AsynchronousDiskPool')
BEGIN
  ALTER DATABASE Fabiano_Test_AsynchronousDiskPool SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_AsynchronousDiskPool
end
GO

-- Criar banco
-- AsynchronousDiskPool vai criar 1 thread para cada disco...
-- Ou seja, 5 threads (F, G, H, I e C)
-- Criando banco pra testes
CREATE DATABASE Fabiano_Test_AsynchronousDiskPool
 ON  PRIMARY 
( NAME = N'Fabiano_Test_AsynchronousDiskPool_1', FILENAME = N'F:\Fabiano_Test_AsynchronousDiskPool_1.mdf' , SIZE = 100MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_AsynchronousDiskPool_2', FILENAME = N'G:\Fabiano_Test_AsynchronousDiskPool_2.ndf' , SIZE = 100MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_AsynchronousDiskPool_3', FILENAME = N'H:\Fabiano_Test_AsynchronousDiskPool_3.mdf' , SIZE = 100MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_AsynchronousDiskPool_4', FILENAME = N'I:\Fabiano_Test_AsynchronousDiskPool_4.ndf' , SIZE = 100MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Fabiano_Test_AsynchronousDiskPool_log', FILENAME = N'C:\DBs\Fabiano_Test_AsynchronousDiskPool_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

/*

  Abrir windbg

  Adicionar bp em sqlmin!FCB::SyncWrite
  bp sqlmin!FCB::SyncWrite

  Go no windbg
  g

  Rodar o CREATE DATABASE... windbg vai parar no sqlmin!FCB::SyncWrite

  !uniqstack vai retornar a stack de todas as threads...
  Procurar pela thread com o CREATE DATABASE (sqllang!CStmtCreateDB)
  e as outras threads fazendo os I/Os ...

  Se necessário, congelar algumas threads pra conseguir ver o resultado das DMVs abaixo...
  pra congelar usar ~<threadid>f

  ~* u pra fazer unfreeze de todas as threads...

*/

-- Enquanto comando está rodando... ver DMVs...
-- Provavelmente vou conseguir ver duas threads... 
-- uma com ASYNC_IO_COMPLETION e outra com PREEMPTIVE_AlgumaCoisa... Depende de onde parou...
DECLARE @SPID INT = 51 -- SPID da sessão rodando o backup

SELECT * FROM sys.dm_io_pending_io_requests

SELECT * FROM sys.dm_exec_requests
WHERE session_id = @SPID;

SELECT * FROM sys.dm_os_waiting_tasks
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

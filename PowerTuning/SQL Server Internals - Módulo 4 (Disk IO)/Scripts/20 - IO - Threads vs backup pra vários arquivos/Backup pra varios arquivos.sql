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
if exists (select * from sysdatabases where name='Fabiano_Test_BackupThreads')
BEGIN
  ALTER DATABASE Fabiano_Test_BackupThreads SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_BackupThreads
end
GO

-- Criando banco pra testes
CREATE DATABASE Fabiano_Test_BackupThreads
 ON  PRIMARY 
( NAME = N'Fabiano_Test_BackupThreads_1', FILENAME = N'F:\Fabiano_Test_BackupThreads_1.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads_2', FILENAME = N'G:\Fabiano_Test_BackupThreads_2.ndf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads_3', FILENAME = N'H:\Fabiano_Test_BackupThreads_3.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads_4', FILENAME = N'I:\Fabiano_Test_BackupThreads_4.ndf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Fabiano_Test_BackupThreads_log', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE Fabiano_Test_BackupThreads
GO
-- Criar tabela com +- 160MB
-- 43 segundos pra rodar...
IF OBJECT_ID('Products1') IS NOT NULL
  DROP TABLE Products1
GO
SELECT TOP 20000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT;
GO

USE [master]
GO
if exists (select * from sysdatabases where name='Fabiano_Test_BackupThread2')
BEGIN
  ALTER DATABASE Fabiano_Test_BackupThread2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_BackupThread2
end
GO

-- Criando mais banco pra testes
-- Agora 4 arquivos mas todos eles no C:\
CREATE DATABASE Fabiano_Test_BackupThread2
 ON  PRIMARY 
( NAME = N'Fabiano_Test_BackupThreads2_1', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads2_1.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads2_2', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads2_2.ndf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads2_3', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads2_3.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ),
( NAME = N'Fabiano_Test_BackupThreads2_4', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads2_4.ndf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Fabiano_Test_BackupThreads2_log', FILENAME = N'C:\DBs\Fabiano_Test_BackupThreads2_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE Fabiano_Test_BackupThread2
GO
-- Criar tabela com +- 1.6GB
-- 28 segundos pra rodar...
IF OBJECT_ID('Products1') IS NOT NULL
  DROP TABLE Products1
GO
SELECT TOP 200000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT;
GO


-- Abrir ..\\Scripts\Backup pra vários arquivos\Open Windbg attached to sqlservr.exe.cmd
-- pra fazer o attach windbg no processo do SQL
USE master
GO
-- Apagar arquivos de backup feitos anteriormente
EXEC xp_cmdshell 'del E:\Fabiano_Test_BackupThreads*'
GO
-- Rodar backup do banco e salvar no E:\
-- Com 4 arquivos, demora 10 segundos pra rodar
BACKUP DATABASE Fabiano_Test_BackupThreads TO 
DISK = 'E:\Fabiano_Test_BackupThreads_file1.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads_file2.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads_file3.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads_file4.bak'
WITH INIT , NOUNLOAD , NAME = 'Fabiano_Test_BackupThreads backup', NOSKIP , STATS = 10, NOFORMAT, COMPRESSION
GO



-- Enquanto o backup está rodando, consultar as seguintes DMVs
-- E logo em seguida dar um break no Windbg

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

/*
  Vamos analisar o resultado da query em dm_os_threads

  session_id os_thread_id exec_context_id pending_io_count scheduler_id last_wait_type         pending_io_count windbgcommand
  ---------- ------------ --------------- ---------------- ------------ ---------------------- ---------------- -------------------------
  52         27828        0               13               5            ASYNC_IO_COMPLETION    156              ~~[00006CB4]k
  52         4604         1               7                6            BACKUPIO               125              ~~[000011FC]k
  52         27784        2               41               4            BACKUPIO               274              ~~[00006C88]k
  52         11892        3               7                1            BACKUPIO               461              ~~[00002E74]k
  52         22372        4               0                1048587      BACKUPBUFFER           68               ~~[00005764]k
  52         23244        5               7                3            BACKUPIO               8                ~~[00005ACC]k
  52         7136         6               0                1048588      BACKUPBUFFER           73               ~~[00001BE0]k
  52         22992        7               0                1048589      BACKUPBUFFER           71               ~~[000059D0]k
  52         21560        8               0                1048590      BACKUPBUFFER           73               ~~[00005438]k

  (9 rows affected)

  Temos 9 threads relacionadas ao backup... 
  1 thread (no context_id 0) com wait em ASYNC_IO_COMPLETION, essa é a thread 
  que iniciou o comando de backup
  4 threads em schedulers do usuário (scheduler_id  < 11)
  4 threads em schedulers internos (scheduler_id > 11)

  Pra ler os dados que serão backup"ados" o SQL criou uma thread pra cada 
  arquivo em disco diferente
  ... nesse caso, temos 4 arquivos em discos diferentes, então o SQL criou 
  4 threads pra fazer as leituras

  Pra cada arquivo no stripe set do backup, o SQL criou uma thread pra 
  fazer as escritas... 
  ... repare que o "destino" dos arquivos não precisa ser em discos 
  diferentes pra ele criar várias threads
  ... portanto, pra ler ele cria 1 thread pra cada disco, mas pra 
  escrever não precisa ser em discos diferentes... 
  ... SQL vai criar uma thread pra cada arquivo...

  AS threads de escrita ficaram nos hidden schedulers pra evitar scheduler 
  stalls... 
  Algumas operações de backup podem fazer sync I/O e ficarem sem fazer 
  Switch causando um "falso"
  stall (non-yielding scheduler)... Um exemplo é o backup pra uma Fita, 
  que precisa ser escrito
  em uma ordem especifica, nesse caso, não da pra enviar o I/O Async... 
  Isso quer dizer que se eu tiver um I/O de escrita de backup sem fazer 
  yield o scheduler monitor não vai
  pegar? ... ;P ops...


  As stacks no WinDbg ficam assim:

  1 thread (os_thread_id = 27828) que iniciou o comando (sqllang!process_request): 

  0:156> ~~[00006CB4]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d2fef508 00007ff9`d6157bef ntdll!NtSignalAndWaitForSingleObject+0x14
  01 00000059`d2fef510 00007ff9`5aa6b685 KERNELBASE!SignalObjectAndWait+0xcf
  02 00000059`d2fef5c0 00007ff9`5aa6b590 sqldk!SOS_Scheduler::SwitchToThreadWorker+0x136
  03 00000059`d2fef890 00007ff9`5aa621ba sqldk!SOS_Scheduler::Switch+0x8e
  04 00000059`d2fef8d0 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  05 00000059`d2fef940 00007ff9`4e4acf5f sqldk!WaitableBase::Wait+0x16a
  06 00000059`d2fef9c0 00007ff9`4fa16e3e sqlmin!AsynchronousDiskPool::WaitUntilDoneOrTimeout+0x10c
  07 00000059`d2fefaf0 00007ff9`4fa26e6e sqlmin!BackupOperation::BackupData+0x68e
  08 00000059`d2ff0f30 00007ff9`4fa4068f sqlmin!BackupDatabaseOperation::PerformDataCopySteps+0x81e
  09 00000059`d2ff8bd0 00007ff9`51f82ee6 sqlmin!BackupEntry::BackupDatabase+0x7af
  0a 00000059`d2ffc750 00007ff9`51367488 sqllang!CStmtDumpDb::XretExecute+0xd6
  0b 00000059`d2ffc7e0 00007ff9`51366ec8 sqllang!CMsqlExecContext::ExecuteStmts<1,1>+0x8f8
  0c 00000059`d2ffd380 00007ff9`51366513 sqllang!CMsqlExecContext::FExecute+0x946
  0d 00000059`d2ffe360 00007ff9`5137031d sqllang!CSQLSource::Execute+0xb9c
  0e 00000059`d2ffe660 00007ff9`51351a55 sqllang!process_request+0xcdd
  0f 00000059`d2ffed60 00007ff9`51351833 sqllang!process_commands_internal+0x4b7
  10 00000059`d2ffee90 00007ff9`5aa69b33 sqllang!process_messages+0x1f3
  11 00000059`d2fff070 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  12 00000059`d2fff670 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  13 00000059`d2fff6e0 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  14 00000059`d2fff800 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  15 00000059`d2fff8d0 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  16 00000059`d2fffbd0 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  17 00000059`d2fffcc0 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  18 00000059`d2fffcf0 00000000`00000000 ntdll!RtlUserThreadStart+0x21


  4 threads (os_thread_id = 4604, 27784, 11892 e 23244) lendo os dados 
  que serão backup"ados"
  repare que essas 4 threads estão fazendo sqlmin!BackupMedium::WriteDataStream

    0:156> ~~[000011FC]k
   # Child-SP          RetAddr           Call Site
  00 00000059`cabf8888 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`cabf8890 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`cabf8930 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`cabf8c90 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`cabf8d00 00007ff9`4fa9ff84 sqldk!WaitableBase::Wait+0x16a
  05 00000059`cabf8d80 00007ff9`4fa5a74e sqlmin!BackupOperation::WaitForEventNoThrow+0xa4
  06 00000059`cabf8e00 00007ff9`4fa5a61e sqlmin!BackupIoRequest::WaitForCompletionInternal+0x7e
  07 00000059`cabf8e80 00007ff9`4fa379fc sqlmin!BackupIoRequest::WaitForCompletion+0xe
  08 00000059`cabf8eb0 00007ff9`4fa384aa sqlmin!BackupOperation::CopyFileToBackupSet0+0x5dc
  09 00000059`cabfa510 00007ff9`4f3f9797 sqlmin!BackupOperation::CopyFileToBackupSet+0x15a
  0a 00000059`cabfca50 00007ff9`4f3fb216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x113
  0b 00000059`cabfcaf0 00007ff9`4e3e20f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
  0c 00000059`cabfcbb0 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0d 00000059`cabfec30 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0e 00000059`cabff230 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0f 00000059`cabff2a0 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  10 00000059`cabff3c0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  11 00000059`cabff490 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  12 00000059`cabff790 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  13 00000059`cabff880 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  14 00000059`cabff8b0 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[00006C88]k
   # Child-SP          RetAddr           Call Site
  00 00000059`dbdf89a8 00007ff9`d6157bef ntdll!NtSignalAndWaitForSingleObject+0x14
  01 00000059`dbdf89b0 00007ff9`5aa6b685 KERNELBASE!SignalObjectAndWait+0xcf
  02 00000059`dbdf8a60 00007ff9`5aa6b590 sqldk!SOS_Scheduler::SwitchToThreadWorker+0x136
  03 00000059`dbdf8d30 00007ff9`5aa621ba sqldk!SOS_Scheduler::Switch+0x8e
  04 00000059`dbdf8d70 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  05 00000059`dbdf8de0 00007ff9`4fa9ff84 sqldk!WaitableBase::Wait+0x16a
  06 00000059`dbdf8e60 00007ff9`4fa5a74e sqlmin!BackupOperation::WaitForEventNoThrow+0xa4
  07 00000059`dbdf8ee0 00007ff9`4fa5a61e sqlmin!BackupIoRequest::WaitForCompletionInternal+0x7e
  08 00000059`dbdf8f60 00007ff9`4fa379fc sqlmin!BackupIoRequest::WaitForCompletion+0xe
  09 00000059`dbdf8f90 00007ff9`4fa384aa sqlmin!BackupOperation::CopyFileToBackupSet0+0x5dc
  0a 00000059`dbdfa5f0 00007ff9`4f3f9797 sqlmin!BackupOperation::CopyFileToBackupSet+0x15a
  0b 00000059`dbdfcb30 00007ff9`4f3fb216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x113
  0c 00000059`dbdfcbd0 00007ff9`4e3e20f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
  0d 00000059`dbdfcc90 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0e 00000059`dbdfed10 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0f 00000059`dbdff310 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  10 00000059`dbdff380 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  11 00000059`dbdff4a0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  12 00000059`dbdff570 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  13 00000059`dbdff870 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  14 00000059`dbdff960 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  15 00000059`dbdff990 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[00002E74]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d35f8e78 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`d35f8e80 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`d35f8f20 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`d35f9280 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`d35f92f0 00007ff9`4fa9ff84 sqldk!WaitableBase::Wait+0x16a
  05 00000059`d35f9370 00007ff9`4fa5a74e sqlmin!BackupOperation::WaitForEventNoThrow+0xa4
  06 00000059`d35f93f0 00007ff9`4fa5a61e sqlmin!BackupIoRequest::WaitForCompletionInternal+0x7e
  07 00000059`d35f9470 00007ff9`4fa379fc sqlmin!BackupIoRequest::WaitForCompletion+0xe
  08 00000059`d35f94a0 00007ff9`4fa384aa sqlmin!BackupOperation::CopyFileToBackupSet0+0x5dc
  09 00000059`d35fab00 00007ff9`4f3f9797 sqlmin!BackupOperation::CopyFileToBackupSet+0x15a
  0a 00000059`d35fd040 00007ff9`4f3fb216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x113
  0b 00000059`d35fd0e0 00007ff9`4e3e20f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
  0c 00000059`d35fd1a0 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0d 00000059`d35ff220 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0e 00000059`d35ff820 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0f 00000059`d35ff890 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  10 00000059`d35ff9b0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  11 00000059`d35ffa80 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  12 00000059`d35ffd80 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  13 00000059`d35ffe70 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  14 00000059`d35ffea0 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[00005ACC]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d43f8d68 00007ff9`d6157bef ntdll!NtSignalAndWaitForSingleObject+0x14
  01 00000059`d43f8d70 00007ff9`5aa6b685 KERNELBASE!SignalObjectAndWait+0xcf
  02 00000059`d43f8e20 00007ff9`5aa6b590 sqldk!SOS_Scheduler::SwitchToThreadWorker+0x136
  03 00000059`d43f90f0 00007ff9`5aa621ba sqldk!SOS_Scheduler::Switch+0x8e
  04 00000059`d43f9130 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  05 00000059`d43f91a0 00007ff9`4fa9ff84 sqldk!WaitableBase::Wait+0x16a
  06 00000059`d43f9220 00007ff9`4fa5a74e sqlmin!BackupOperation::WaitForEventNoThrow+0xa4
  07 00000059`d43f92a0 00007ff9`4fa5a61e sqlmin!BackupIoRequest::WaitForCompletionInternal+0x7e
  08 00000059`d43f9320 00007ff9`4fa379fc sqlmin!BackupIoRequest::WaitForCompletion+0xe
  09 00000059`d43f9350 00007ff9`4fa384aa sqlmin!BackupOperation::CopyFileToBackupSet0+0x5dc
  0a 00000059`d43fa9b0 00007ff9`4f3f9797 sqlmin!BackupOperation::CopyFileToBackupSet+0x15a
  0b 00000059`d43fcef0 00007ff9`4f3fb216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x113
  0c 00000059`d43fcf90 00007ff9`4e3e20f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
  0d 00000059`d43fd050 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0e 00000059`d43ff0d0 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0f 00000059`d43ff6d0 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  10 00000059`d43ff740 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  11 00000059`d43ff860 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  12 00000059`d43ff930 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  13 00000059`d43ffc30 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  14 00000059`d43ffd20 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  15 00000059`d43ffd50 00000000`00000000 ntdll!RtlUserThreadStart+0x21

  E mais 4 threads (os_thread_id = 22372, 7136, 22992 e 21560) fazendo as escritas
  repare que essas 4 threads estão faznedo sqlmin!BackupOperation::CopyFileToBackupSet
  Como a leitura dos dados ta sendo feita num disco lento/ruim (pendrive) elas estão
  na verdade esperando um buffer (sqlmin!BackupSynchronizedBufferList::WaitForValidBuffer) 
  pra enviar os I/Os de escrita... 

  0:156> ~~[00005764]k
   # Child-SP          RetAddr           Call Site
  00 00000059`cadfb0c8 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`cadfb0d0 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`cadfb170 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`cadfb4d0 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`cadfb540 00007ff9`4fa313bd sqldk!WaitableBase::Wait+0x16a
  05 00000059`cadfb5c0 00007ff9`4fa6cc10 sqlmin!BackupSynchronizedBufferList::WaitForValidBuffer+0xed
  06 00000059`cadfb620 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x680
  07 00000059`cadfb820 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  08 00000059`cadfcaf0 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  09 00000059`cadfcbe0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0a 00000059`cadfcc80 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0b 00000059`cadfed00 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0c 00000059`cadff300 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0d 00000059`cadff370 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  0e 00000059`cadff490 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  0f 00000059`cadff560 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  10 00000059`cadff860 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  11 00000059`cadff950 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  12 00000059`cadff980 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[00001BE0]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da1fb0d8 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`da1fb0e0 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`da1fb180 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`da1fb4e0 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`da1fb550 00007ff9`4fa313bd sqldk!WaitableBase::Wait+0x16a
  05 00000059`da1fb5d0 00007ff9`4fa6cc10 sqlmin!BackupSynchronizedBufferList::WaitForValidBuffer+0xed
  06 00000059`da1fb630 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x680
  07 00000059`da1fb830 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  08 00000059`da1fcb00 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  09 00000059`da1fcbf0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0a 00000059`da1fcc90 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0b 00000059`da1fed10 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0c 00000059`da1ff310 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0d 00000059`da1ff380 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  0e 00000059`da1ff4a0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  0f 00000059`da1ff570 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  10 00000059`da1ff870 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  11 00000059`da1ff960 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  12 00000059`da1ff990 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[000059D0]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da5fb698 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`da5fb6a0 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`da5fb740 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`da5fbaa0 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`da5fbb10 00007ff9`4fa313bd sqldk!WaitableBase::Wait+0x16a
  05 00000059`da5fbb90 00007ff9`4fa6cc10 sqlmin!BackupSynchronizedBufferList::WaitForValidBuffer+0xed
  06 00000059`da5fbbf0 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x680
  07 00000059`da5fbdf0 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  08 00000059`da5fd0c0 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  09 00000059`da5fd1b0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0a 00000059`da5fd250 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0b 00000059`da5ff2d0 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0c 00000059`da5ff8d0 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0d 00000059`da5ff940 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  0e 00000059`da5ffa60 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  0f 00000059`da5ffb30 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  10 00000059`da5ffe30 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  11 00000059`da5fff20 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  12 00000059`da5fff50 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:156> ~~[00005438]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da7faed8 00007ff9`d6098b03 ntdll!NtWaitForSingleObject+0x14
  01 00000059`da7faee0 00007ff9`5aa61ae2 KERNELBASE!WaitForSingleObjectEx+0x93
  02 00000059`da7faf80 00007ff9`5aa621ba sqldk!SOS_Scheduler::SwitchContext+0x745
  03 00000059`da7fb2e0 00007ff9`5aa63804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
  04 00000059`da7fb350 00007ff9`4fa313bd sqldk!WaitableBase::Wait+0x16a
  05 00000059`da7fb3d0 00007ff9`4fa6cc10 sqlmin!BackupSynchronizedBufferList::WaitForValidBuffer+0xed
  06 00000059`da7fb430 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x680
  07 00000059`da7fb630 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  08 00000059`da7fc900 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  09 00000059`da7fc9f0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0a 00000059`da7fca90 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0b 00000059`da7feb10 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  0c 00000059`da7ff110 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  0d 00000059`da7ff180 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  0e 00000059`da7ff2a0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  0f 00000059`da7ff370 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  10 00000059`da7ff670 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  11 00000059`da7ff760 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  12 00000059`da7ff790 00000000`00000000 ntdll!RtlUserThreadStart+0x21

*/


-- Vamos fazer um teste onde não temos o problema de ficar esperando 
-- o buffer pra gerar o I/O de escrita pra ver se a stack muda... 
-- Dessa vez, vamos também usar 8 arquivos no stripe set... 

-- Apagar arquivos de backup feitos anteriormente
EXEC xp_cmdshell 'del E:\Fabiano_Test_BackupThreads*'
GO
-- Rodar backup do banco e salvar no E:\
-- Com 8 arquivos, demora 10 segundos pra rodar
BACKUP DATABASE Fabiano_Test_BackupThread2 TO 
DISK = 'E:\Fabiano_Test_BackupThreads2_file1.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads2_file2.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file3.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads2_file4.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file5.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file6.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file7.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file8.bak' 
WITH INIT , NOUNLOAD , NAME = 'Fabiano_Test_BackupThreads2 backup', NOSKIP , STATS = 10, NOFORMAT, COMPRESSION
GO

-- Enquanto roda, consultar DMV e fazer break no windbg pra pegar as stacks

/*
  Agora temos 10 threads... 
  1 que iniciou o comando, 1 fazendo a leitura e 8 fazendo as escritas 

  session_id os_thread_id exec_context_id pending_io_count scheduler_id last_wait_type        pending_io_count windbgcommand
  ---------- ------------ --------------- ---------------- ------------ --------------------- ---------------- -------------------------
  52         27828        0               8                5            ASYNC_IO_COMPLETION   275              ~~[00006CB4]k
  52         29508        1               586              6            BACKUPBUFFER          890              ~~[00007344]k
  52         21560        2               1                1048590      BACKUPBUFFER          98               ~~[00005438]k
  52         22992        3               0                1048589      BACKUPBUFFER          95               ~~[000059D0]k
  52         7136         4               0                1048588      BACKUPBUFFER          98               ~~[00001BE0]k
  52         22372        5               0                1048587      BACKUPBUFFER          94               ~~[00005764]k
  52         2804         6               0                1048591      BACKUPBUFFER          20               ~~[00000AF4]k
  52         18848        7               0                1048592      BACKUPBUFFER          20               ~~[000049A0]k
  52         2912         8               0                1048593      BACKUPBUFFER          20               ~~[00000B60]k
  52         8012         9               0                1048594      BACKUPBUFFER          20               ~~[00001F4C]k

  (10 rows affected)

  Vamos ver como estão as stacks das 8 threads fazendo a escrita...
  Repare que agora as threads não estão paradas no "sqlmin!BackupMedium::WriteDataStream"... 
  Todas as threads chamaram a sqlmin!DiskWriteAsync -> KERNELBASE!WriteFile pra fazer os I/Os

  0:135> ~~[00005438]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da7faf98 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`da7fafa0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`da7fb010 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`da7fb110 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`da7fb160 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`da7fb1b0 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`da7fb200 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`da7fb260 00007ff9`4fad8874 sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`da7fb290 00007ff9`4fac95f3 sqlmin!MediaWriteInterface::RunEncodeOutputCycle+0x184
  09 00000059`da7fb3b0 00007ff9`4fa6c849 sqlmin!BackupMediaIoRequest::IsIoDone+0x253
  0a 00000059`da7fb430 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x2b9
  0b 00000059`da7fb630 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`da7fc900 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`da7fc9f0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`da7fca90 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`da7feb10 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`da7ff110 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`da7ff180 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`da7ff2a0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`da7ff370 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`da7ff670 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`da7ff760 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`da7ff790 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[000059D0]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da5fb6a8 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`da5fb6b0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`da5fb720 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`da5fb820 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`da5fb870 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`da5fb8c0 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`da5fb910 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`da5fb970 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`da5fb9a0 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`da5fbb80 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`da5fbbf0 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`da5fbdf0 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`da5fd0c0 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`da5fd1b0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`da5fd250 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`da5ff2d0 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`da5ff8d0 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`da5ff940 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`da5ffa60 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`da5ffb30 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`da5ffe30 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`da5fff20 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`da5fff50 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[00001BE0]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da1fb0e8 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`da1fb0f0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`da1fb160 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`da1fb260 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`da1fb2b0 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`da1fb300 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`da1fb350 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`da1fb3b0 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`da1fb3e0 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`da1fb5c0 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`da1fb630 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`da1fb830 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`da1fcb00 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`da1fcbf0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`da1fcc90 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`da1fed10 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`da1ff310 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`da1ff380 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`da1ff4a0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`da1ff570 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`da1ff870 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`da1ff960 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`da1ff990 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[00005764]k
   # Child-SP          RetAddr           Call Site
  00 00000059`cadfb0d8 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`cadfb0e0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`cadfb150 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`cadfb250 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`cadfb2a0 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`cadfb2f0 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`cadfb340 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`cadfb3a0 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`cadfb3d0 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`cadfb5b0 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`cadfb620 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`cadfb820 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`cadfcaf0 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`cadfcbe0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`cadfcc80 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`cadfed00 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`cadff300 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`cadff370 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`cadff490 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`cadff560 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`cadff860 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`cadff950 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`cadff980 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[00000AF4]k
   # Child-SP          RetAddr           Call Site
  00 00000059`da9fb1b8 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`da9fb1c0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`da9fb230 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`da9fb330 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`da9fb380 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`da9fb3d0 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`da9fb420 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`da9fb480 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`da9fb4b0 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`da9fb690 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`da9fb700 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`da9fb900 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`da9fcbd0 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`da9fccc0 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`da9fcd60 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`da9fede0 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`da9ff3e0 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`da9ff450 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`da9ff570 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`da9ff640 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`da9ff940 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`da9ffa30 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`da9ffa60 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[000049A0]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d85fb048 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`d85fb050 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`d85fb0c0 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`d85fb1c0 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`d85fb210 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`d85fb260 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`d85fb2b0 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`d85fb310 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`d85fb340 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`d85fb520 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`d85fb590 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`d85fb790 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`d85fca60 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`d85fcb50 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`d85fcbf0 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`d85fec70 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`d85ff270 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`d85ff2e0 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`d85ff400 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`d85ff4d0 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`d85ff7d0 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`d85ff8c0 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`d85ff8f0 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[00000B60]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d87fb008 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`d87fb010 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`d87fb080 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`d87fb180 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`d87fb1d0 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`d87fb220 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`d87fb270 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`d87fb2d0 00007ff9`4fad809d sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`d87fb300 00007ff9`4fad0c7b sqlmin!MediaWriteInterface::StartEncodedWrite+0x31d
  09 00000059`d87fb4e0 00007ff9`4fa6cbe9 sqlmin!BackupMedium::StartWrite+0x2b
  0a 00000059`d87fb550 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x659
  0b 00000059`d87fb750 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`d87fca20 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`d87fcb10 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`d87fcbb0 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`d87fec30 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`d87ff230 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`d87ff2a0 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`d87ff3c0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`d87ff490 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`d87ff790 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`d87ff880 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`d87ff8b0 00000000`00000000 ntdll!RtlUserThreadStart+0x21
  0:135> ~~[00001F4C]k
   # Child-SP          RetAddr           Call Site
  00 00000059`d8dfb2a8 00007ff9`d608508d ntdll!NtWriteFile+0x14
  01 00000059`d8dfb2b0 00007ff9`4e38aa6c KERNELBASE!WriteFile+0xfd
  02 00000059`d8dfb320 00007ff9`4f68698c sqlmin!DiskWriteAsync+0x1b7
  03 00000059`d8dfb420 00007ff9`4f681735 sqlmin!Win32FileSystemHandler::WriteAsync+0x4c
  04 00000059`d8dfb470 00007ff9`4fa59e78 sqlmin!DBWriteAsync+0x65
  05 00000059`d8dfb4c0 00007ff9`4fa4c7e4 sqlmin!BackupIoRequest::StartDirectWrite+0x98
  06 00000059`d8dfb510 00007ff9`4fad8428 sqlmin!BackupFile::StartWrite+0x224
  07 00000059`d8dfb570 00007ff9`4fad8874 sqlmin!MediaWriteInterface::StartWrites+0x88
  08 00000059`d8dfb5a0 00007ff9`4fac95f3 sqlmin!MediaWriteInterface::RunEncodeOutputCycle+0x184
  09 00000059`d8dfb6c0 00007ff9`4fa6c849 sqlmin!BackupMediaIoRequest::IsIoDone+0x253
  0a 00000059`d8dfb740 00007ff9`4fa84df8 sqlmin!BackupMedium::WriteDataStream+0x2b9
  0b 00000059`d8dfb940 00007ff9`4fa87c45 sqlmin!BackupStream::DoFileBackup+0x2e8
  0c 00000059`d8dfcc10 00007ff9`4fa94664 sqlmin!BackupStream::ThreadMainRoutine+0xd5
  0d 00000059`d8dfcd00 00007ff9`4e3e20f3 sqlmin!BackupThread::ThreadBase+0x54
  0e 00000059`d8dfcda0 00007ff9`5aa69b33 sqlmin!SubprocEntrypoint+0xd25
  0f 00000059`d8dfee20 00007ff9`5aa6a48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000059`d8dff420 00007ff9`5aa6a295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000059`d8dff490 00007ff9`5aa87020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000059`d8dff5b0 00007ff9`5aa87b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000059`d8dff680 00007ff9`5aa87931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000059`d8dff980 00007ff9`d8277bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000059`d8dffa70 00007ff9`d83cce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000059`d8dffaa0 00000000`00000000 ntdll!RtlUserThreadStart+0x21
*/


-- Obervação em relação ao tamanho do I/O enviado... 
-- Do BOL:
/*
  For Transparent Data Encryption (TDE) enabled databases with a 
  single data file, 
  the default MAXTRANSFERSIZE is 65536 (64 KB). For non-TDE 
  encrypted databases the default 
  MAXTRANSFERSIZE is 1048576 (1 MB) when using backup to DISK, 
  and 65536 (64 KB) when using VDI or TAPE. 
*/

-- Ou seja I/O de 1MB é o padrão, mas se vc quiser aumentar, 
-- pode usar o MAXTRANSFERSIZE
-- "the possible values are multiples of 65536 bytes (64 KB) 
-- ranging up to 4194304 bytes (4 MB)."

-- Se o banco tiver TDE habilitado, daí você vai precisar MUITO 
-- do MAXTRANSFERSIZE, senão o SQL vai ficar  
-- enviando um zilhão de I/O de 64KB...

USE Master;
GO
CREATE MASTER KEY ENCRYPTION
BY PASSWORD='@bc123456789';
GO
CREATE CERTIFICATE TDE_Cert
WITH 
SUBJECT='Database_Encryption';
GO
USE Fabiano_Test_BackupThread2
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDE_Cert;
GO
ALTER DATABASE Fabiano_Test_BackupThread2
SET ENCRYPTION ON;
GO


-- Apagar arquivos de backup feitos anteriormente
EXEC xp_cmdshell 'del E:\Fabiano_Test_BackupThreads*'
GO
-- Rodar backup do banco e salvar no E:\
-- Com TDE, se eu não especificar o MAXTRANSFERSIZE, backup demora 17 minutos :-( ... OMG
-- Com MAXTRANSFERSIZE = 4MB, demora 56 segundos...
BACKUP DATABASE Fabiano_Test_BackupThread2 TO 
DISK = 'E:\Fabiano_Test_BackupThreads2_file1.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads2_file2.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file3.bak'
,DISK = 'E:\Fabiano_Test_BackupThreads2_file4.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file5.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file6.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file7.bak' 
,DISK = 'E:\Fabiano_Test_BackupThreads2_file8.bak' 
WITH INIT , NOUNLOAD , NAME = 'Fabiano_Test_BackupThreads2 backup', NOSKIP , STATS = 10, NOFORMAT, COMPRESSION
--,MAXTRANSFERSIZE = 4194304 
GO

-- Cleanup

USE [master]
GO
if exists (select * from sysdatabases where name='Fabiano_Test_BackupThread2')
BEGIN
  ALTER DATABASE Fabiano_Test_BackupThread2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_BackupThread2
end
GO
DROP CERTIFICATE TDE_Cert
GO
DROP MASTER KEY
GO
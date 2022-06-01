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
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
end
GO

-- Pra verificar permissões do usuário do serviço do SQL
-- IFI = SeManageVolumePrivilege
xp_cmdshell 'whoami /priv'
GO
exec xp_readerrorlog 0, 1, N'Database Instant File Initialization' -- 2014SP2+
GO
SELECT * FROM sys.dm_server_services -- SQL2012+
GO


-- 1 - Formatar disco, desmarcar opção de "quick format"...
-- 2 - Copiar arquivo pro disco 
---- D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 4 (IO, Latches e Tempdb)\Scripts\Instant file initialization demo\Test1.txt
-- 3 - Apagar arquivo copiado no disco
-- 4 - Criar banco
-- 5 - Setar banco pra offline
-- 6 - Abrir banco no XVI32.exe e procurar pelo conteúdo do arquivo "Test1.txt" 
--     que estava no disco...


-- Criar banco de 200MB no pendrive (F:\) com IFI
-- 7 segundos pra rodar
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'F:\Test1.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'F:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE [master]
GO
-- Seta o banco pra offline e abre no XVI32.exe
ALTER DATABASE [Test1] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO


-- Aaaa, mas daí o cara precisa de acesso ao arquivo mdf... muito difícil de acontecer...


-- Volta o banco pra online
ALTER DATABASE [Test1] SET ONLINE
GO

-- Faz um backup do banco
BACKUP DATABASE [Test1] TO  DISK = N'C:\temp\Test1.bak' WITH NOFORMAT, NOINIT,  
NAME = N'Test1-Full Database Backup', SKIP, NOREWIND, NOUNLOAD,  STATS = 10, NO_COMPRESSION
GO

-- Restaura o backup... pode ser em outra instancia ou outra maq
USE [master]
RESTORE DATABASE [Test1_Restaurado] FROM  DISK = N'c:\temp\Test1.bak' 
WITH  FILE = 1,  
MOVE N'Test1' TO N'c:\temp\Test1_Restaurado.mdf',  
MOVE N'Test1_log' TO N'c:\temp\Test1_Restaurado_log.ldf',  
NOUNLOAD,  STATS = 5, REPLACE
GO

-- Seta o banco restaurado pra offline e abre o arquivo no XVI32.exe
ALTER DATABASE [Test1_Restaurado] SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- Cleanup
ALTER DATABASE [Test1_Restaurado] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [Test1_Restaurado]
ALTER DATABASE [Test1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [Test1]
GO

-- TF1806 desabilita IFI, mesmo que usuário tenha privilégio de SeManageVolumePrivilege
-- Quanto tempo demoraria pra criar o banco, sem o IFI?...
-- TF3004 pra mostrar os detalhes do SQL zerando o log no errorlog
DBCC TRACEON (1806, 3605, 3004)
GO
-- +-50 segundos pra rodar
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'F:\Test1.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'F:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
DBCC TRACEOFF (1806, 3605, 3004)
GO
--Zeroing completed on F:\Test1.mdf (elapsed = 44317 ms)
--Zeroing F:\Test1.mdf from page 0 to 25600 (0x0 to 0xc800000)


-- Internamente SQL utiliza a função SetFileValidData...
-- "bp KERNELBASE!SetFileValidData" no Windbg vai fazer o SQL parar
-- quando a função for chamada...

ALTER DATABASE [Test1] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [Test1]
GO

-- Abrir windbg e colocar bp em KERNELBASE!SetFileValidData
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'F:\Test1.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'F:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
/*
00 00000025`1c5fb2b8 00007ffb`31bebdee KERNELBASE!SetFileValidData
01 00000025`1c5fb2c0 00007ffb`32c7e9f7 sqlmin!FCB::InitializeSpace+0x180
02 00000025`1c5fc3a0 00007ffb`32b99718 sqlmin!FileMgr::CreateNewFile+0x6d7
03 00000025`1c5fd020 00007ffb`32b9b216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x94
04 00000025`1c5fd0c0 00007ffb`31b820f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
05 00000025`1c5fd180 00007ffb`3d4e9b33 sqlmin!SubprocEntrypoint+0xd25
06 00000025`1c5ff200 00007ffb`3d4ea48d sqldk!SOS_Task::Param::Execute+0x232
07 00000025`1c5ff800 00007ffb`3d4ea295 sqldk!SOS_Scheduler::RunTask+0xb5
08 00000025`1c5ff870 00007ffb`3d507020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
09 00000025`1c5ff990 00007ffb`3d507b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
0a 00000025`1c5ffa60 00007ffb`3d507931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
0b 00000025`1c5ffd60 00007ffb`9f9b7bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
0c 00000025`1c5ffe50 00007ffb`a108ce51 KERNEL32!BaseThreadInitThunk+0x14
0d 00000025`1c5ffe80 00000000`00000000 ntdll!RtlUserThreadStart+0x21
*/

-- Com o TF3004, o BP não vai ser disparado...
-- Depois de uns 20 segundos, dar um break no Windbg e ver as stacks
-- !uniqstack
-- Procurar pela thread fazendo o "ZeroFile" logo após o InitializeSpace
-- Repare que a thread fazendo o WriteFileGather, é diferente da thread
-- que executou o CREATE DATABASE 
--- Pra achar a thread que chamou o CREATE DATABASE, procurar por "sqllang!CStmtCreateDB"
DBCC TRACEON (1806, 3605, 3004)
GO
-- +-50 segundos pra rodar
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'F:\Test1.mdf' , SIZE = 204800KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'F:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
DBCC TRACEOFF (1806, 3605, 3004)
GO

/*
-- Thread fazendo a escrita...
00 00000025`19bf18b8 00007ffb`9e16f82c ntdll!NtWriteFileGather+0x14
01 00000025`19bf18c0 00007ffb`32c2d2e7 KERNELBASE!WriteFileGather+0x6c
02 00000025`19bf1920 00007ffb`32c2dbd7 sqlmin!InitializeFile+0x1e7
03 00000025`19bf9a80 00007ffb`32c2d088 sqlmin!FCB::ZeroFile+0x5a7
04 00000025`19bfabd0 00007ffb`32c7e9f7 sqlmin!FCB::InitializeSpace+0x21d
05 00000025`19bfbcb0 00007ffb`32b99718 sqlmin!FileMgr::CreateNewFile+0x6d7
06 00000025`19bfc930 00007ffb`32b9b216 sqlmin!AsynchronousDiskAction::ExecuteDeferredAction+0x94
07 00000025`19bfc9d0 00007ffb`31b820f3 sqlmin!AsynchronousDiskWorker::ThreadRoutine+0x106
08 00000025`19bfca90 00007ffb`3d4e9b33 sqlmin!SubprocEntrypoint+0xd25
09 00000025`19bfeb10 00007ffb`3d4ea48d sqldk!SOS_Task::Param::Execute+0x232
0a 00000025`19bff110 00007ffb`3d4ea295 sqldk!SOS_Scheduler::RunTask+0xb5
0b 00000025`19bff180 00007ffb`3d507020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
0c 00000025`19bff2a0 00007ffb`3d507b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
0d 00000025`19bff370 00007ffb`3d507931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
0e 00000025`19bff670 00007ffb`9f9b7bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
0f 00000025`19bff760 00007ffb`a108ce51 KERNEL32!BaseThreadInitThunk+0x14
10 00000025`19bff790 00000000`00000000 ntdll!RtlUserThreadStart+0x21

-- Thread que chamou o CREATE DATABASE
00 00000025`0d7fa5a8 00007ffb`9e1e7bef ntdll!NtSignalAndWaitForSingleObject+0x14
01 00000025`0d7fa5b0 00007ffb`3d4eb685 KERNELBASE!SignalObjectAndWait+0xcf
02 00000025`0d7fa660 00007ffb`3d4eb590 sqldk!SOS_Scheduler::SwitchToThreadWorker+0x136
03 00000025`0d7fa930 00007ffb`3d4e21ba sqldk!SOS_Scheduler::Switch+0x8e
04 00000025`0d7fa970 00007ffb`3d4e3804 sqldk!SOS_Scheduler::SuspendNonPreemptive+0xe3
05 00000025`0d7fa9e0 00007ffb`31c4cf5f sqldk!WaitableBase::Wait+0x16a
06 00000025`0d7faa60 00007ffb`31c58b29 sqlmin!AsynchronousDiskPool::WaitUntilDoneOrTimeout+0x10c
07 00000025`0d7fab90 00007ffb`32bcccb8 sqlmin!AsyncWorkerPool::DoWork+0x9
08 00000025`0d7fabc0 00007ffb`3011897e sqlmin!DBMgr::CreateAndFormatFiles+0x3c8
09 00000025`0d7fafc0 00007ffb`30119209 sqllang!CStmtCreateDB::CreateLocalDatabaseFragment+0x8fe
0a 00000025`0d7fb870 00007ffb`3011de6a sqllang!DBDDLAgent::CreateDatabase+0x169
0b 00000025`0d7fb980 00007ffb`2f527488 sqllang!CStmtCreateDB::XretExecute+0x130a
0c 00000025`0d7fc550 00007ffb`2f526ec8 sqllang!CMsqlExecContext::ExecuteStmts<1,1>+0x8f8
0d 00000025`0d7fd0f0 00007ffb`2f526513 sqllang!CMsqlExecContext::FExecute+0x946
0e 00000025`0d7fe0d0 00007ffb`2f53031d sqllang!CSQLSource::Execute+0xb9c
0f 00000025`0d7fe3d0 00007ffb`2f511a55 sqllang!process_request+0xcdd
10 00000025`0d7fead0 00007ffb`2f511833 sqllang!process_commands_internal+0x4b7
11 00000025`0d7fec00 00007ffb`3d4e9b33 sqllang!process_messages+0x1f3
12 00000025`0d7fede0 00007ffb`3d4ea48d sqldk!SOS_Task::Param::Execute+0x232
13 00000025`0d7ff3e0 00007ffb`3d4ea295 sqldk!SOS_Scheduler::RunTask+0xb5
14 00000025`0d7ff450 00007ffb`3d507020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
15 00000025`0d7ff570 00007ffb`3d507b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
16 00000025`0d7ff640 00007ffb`3d507931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
17 00000025`0d7ff940 00007ffb`9f9b7bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
18 00000025`0d7ffa30 00007ffb`a108ce51 KERNEL32!BaseThreadInitThunk+0x14
19 00000025`0d7ffa60 00000000`00000000 ntdll!RtlUserThreadStart+0x21

*/
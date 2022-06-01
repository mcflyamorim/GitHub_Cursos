----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

USE master
GO

-- 1 - Iniciar SQL com -T9038 pra forçar apenas 1 Log Writer
-- 2 - Ajustar Max Worker Threads
-- 3 - Abrir Perfmon em ...\Scripts\23 - IO - Multiple Log Writers e sqlmin!SQLServerLogMgrLogFlush\Perfmon.msc

EXEC sys.sp_configure N'max worker threads', N'5000'
GO
RECONFIGURE
GO

-- Verificando que só temos 1 thread pro LogWriter
SELECT * FROM sys.dm_exec_requests
WHERE command LIKE '%Log writer%'
GO

USE master
GO

-- Criando banco de testes...
if exists (select * from sysdatabases where name='Test_Fabiano_MultipleLogWriters')
BEGIN
  ALTER DATABASE Test_Fabiano_MultipleLogWriters SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_MultipleLogWriters
end
GO
CREATE DATABASE Test_Fabiano_MultipleLogWriters
 ON  PRIMARY 
( NAME = N'Test_Fabiano_MultipleLogWriters', FILENAME = N'D:\DBs\Test_Fabiano_MultipleLogWriters.mdf' , SIZE = 5120MB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_MultipleLogWriters_log', FILENAME = N'D:\DBs\Test_Fabiano_MultipleLogWriters_log.ldf' , SIZE = 5120MB , MAXSIZE = UNLIMITED , FILEGROWTH = 5120MB )
GO
ALTER DATABASE Test_Fabiano_MultipleLogWriters 
SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;
GO
ALTER DATABASE Test_Fabiano_MultipleLogWriters 
ADD FILEGROUP Test_Fabiano_MultipleLogWriters_mod CONTAINS MEMORY_OPTIMIZED_DATA;
GO
ALTER DATABASE Test_Fabiano_MultipleLogWriters 
ADD FILE (name='Test_Fabiano_MultipleLogWriters_mod1', FILENAME='D:\DBs\Test_Fabiano_MultipleLogWriters.mod') 
TO FILEGROUP Test_Fabiano_MultipleLogWriters_mod
GO

USE Test_Fabiano_MultipleLogWriters
GO
-- Tabela com Identity como primary key...
DROP TABLE IF EXISTS Table1
CREATE TABLE [dbo].[Table1]
(
  [Col1] [bigint] NOT NULL IDENTITY(1, 1),
  [Col2] [varchar] (250) NOT NULL,
  [Col3] [varchar] (250) NOT NULL,
  Col4 char(200) DEFAULT 'x'
) 
GO
ALTER TABLE Table1 ADD CONSTRAINT xpkTable1 PRIMARY KEY(Col1)
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS
GO

-- Query pra inserir os dados na tabela Table1
DROP PROC IF EXISTS st_InsertTable1
GO
CREATE PROC st_InsertTable1
AS
;WITH  t4    AS (SELECT n
                FROM   (VALUES(0),(0),(0),(0)) t(n))
     ,t256  AS (SELECT     0 AS n
                FROM       t4 AS a
                CROSS JOIN t4 AS b
                CROSS JOIN t4 AS c
                CROSS JOIN t4 AS d)
     ,t16M  AS (SELECT     ROW_NUMBER()
                               OVER (ORDER BY (a.n)) AS num
                FROM       t256 AS a
                CROSS JOIN t256 AS b
                CROSS JOIN t256 AS c)
INSERT INTO Table1 (Col2,Col3)
SELECT TOP (500)
       ISNULL(CONVERT(VarChar(250), 'Col2'), '') AS Col2,
       ISNULL(CONVERT(VarChar(250), 'Col3'), '') AS Col3
  FROM t16M
OPTION (MAXDOP 1)
GO

-- Testando a sp...
EXEC Test_Fabiano_MultipleLogWriters.dbo.st_InsertTable1
GO

-- Clear Wait Stats 
DBCC SQLPERF('sys.dm_os_wait_stats'    , CLEAR)
DBCC SQLPERF('sys.dm_os_latch_stats'   , CLEAR)
DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR)
TRUNCATE TABLE Table1
CHECKPOINT -- Pra truncar o log...
GO

-- Executar .bat pra rodar proc em 
-- 500 threads e 30 iterations
-- Depois de 30 minutos eu desisti de esperar...
EXEC xp_cmdShell '"D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 4 (Disk IO)\Scripts\23 - IO - Multiple Log Writers e sqlmin!SQLServerLogMgrLogFlush\RunQuery.cmd"'
GO

-- Enquanto estiver rodando... 
USE master
GO
EXEC sp_whoisactive
GO


-- Como ficaram os waits? 
-- Top Waits
SELECT * FROM master.dbo.vw_TopWaits
GO
/*
WaitType                            Wait Percentage AvgWait_Sec AvgRes_Sec AvgSig_Sec Wait_Sec   Resource_Sec Signal_Sec Wait Count
----------------------------------- --------------- ----------- ---------- ---------- ---------- ------------ ---------- ----------
LCK_M_IX                            39.64           1.81        1.81       0.00       53665.49   53659.01     6.48       29571
LATCH_EX                            31.59           0.22        0.22       0.00       42769.02   42759.38     9.65       191796
LATCH_SH                            12.08           0.00        0.00       0.00       16348.29   16113.92     234.37     3629859
PAGELATCH_EX                        10.24           0.00        0.00       0.00       13864.85   13745.75     119.10     3910263
PAGELATCH_SH                        6.39            0.00        0.00       0.00       8646.22    7481.37      1164.85    5687597
PAGELATCH_UP                        0.04            0.04        0.04       0.00       48.99      48.78        0.21       1230
IO_COMPLETION                       0.03            0.00        0.00       0.00       37.99      35.83        2.16       105246
ASYNC_NETWORK_IO                    0.00            0.00        0.00       0.00       1.24       1.22         0.02       921
WRITELOG                            0.00            0.00        0.00       0.00       1.12       0.95         0.17       4922
PAGEIOLATCH_EX                      0.00            0.00        0.00       0.00       0.48       0.43         0.05       1219
*/

-- Vamos re-criar tabela e usar uma chave que não é sequencial...
-- pra evitar esses waits...
DROP TABLE IF EXISTS Table1
CREATE TABLE [dbo].[Table1]
(
  [Col1] UNIQUEIDENTIFIER NOT NULL,
  [Col2] [varchar] (250) NOT NULL,
  [Col3] [varchar] (250) NOT NULL,
  Col4 char(200) DEFAULT 'x'
) ON [PRIMARY]
GO
ALTER TABLE Table1 ADD CONSTRAINT xpkTable1 PRIMARY KEY(Col1)
GO

-- Alterar proc pra inserir os dados na tabela Table1
-- pra usar o NEWID como GUID
ALTER PROC st_InsertTable1
AS
;WITH  t4    AS (SELECT n
                FROM   (VALUES(0),(0),(0),(0)) t(n))
     ,t256  AS (SELECT     0 AS n
                FROM       t4 AS a
                CROSS JOIN t4 AS b
                CROSS JOIN t4 AS c
                CROSS JOIN t4 AS d)
     ,t16M  AS (SELECT     ROW_NUMBER()
                               OVER (ORDER BY (a.n)) AS num
                FROM       t256 AS a
                CROSS JOIN t256 AS b
                CROSS JOIN t256 AS c)
INSERT INTO Table1 (Col1,Col2,Col3)
SELECT TOP (500)
       NEWID() AS Col1,
       ISNULL(CONVERT(VarChar(250), 'Col2'), '') AS Col2,
       ISNULL(CONVERT(VarChar(250), 'Col3'), '') AS Col3
  FROM t16M
OPTION (MAXDOP 1)
GO

-- Clear Wait Stats 
DBCC SQLPERF('sys.dm_os_wait_stats'    , CLEAR)
DBCC SQLPERF('sys.dm_os_latch_stats'   , CLEAR)
DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR)
TRUNCATE TABLE Table1
CHECKPOINT -- Pra truncar o log...
GO

-- Executar .bat pra rodar proc em 
-- 500 threads e 30 iterations
EXEC xp_cmdShell '"D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 4 (Disk IO)\Scripts\23 - IO - Multiple Log Writers e sqlmin!SQLServerLogMgrLogFlush\RunQuery.cmd"'
GO

-- Maravilha... melhorou MUITO... 
-- Agora levou apenas 23 segundos pra rodar...
-- Como ficaram os waits? 
-- Top Waits
SELECT * FROM master.dbo.vw_TopWaits
GO
/*
WaitType                            Wait Percentage AvgWait_Sec AvgRes_Sec AvgSig_Sec Wait_Sec   Resource_Sec Signal_Sec Wait Count
----------------------------------- --------------- ----------- ---------- ---------- ---------- ------------ ---------- ----------
PAGELATCH_SH                        70.82           0.00        0.00       0.00       6346.68    5338.99      1007.69    1293544
LATCH_SH                            13.62           0.00        0.00       0.00       1220.60    848.41       372.19     262128
PAGELATCH_EX                        5.12            0.00        0.00       0.00       458.47     443.19       15.28      94779
LOGBUFFER                           2.55            0.00        0.00       0.00       228.34     178.46       49.89      86157
PAGELATCH_UP                        1.82            0.00        0.00       0.00       162.69     155.79       6.90       35292
WRITELOG                            1.51            0.01        0.01       0.00       135.30     123.00       12.30      20625
PAGEIOLATCH_EX                      1.27            0.01        0.01       0.00       113.86     109.01       4.85       10634
LOGMGR_FLUSH                        1.20            0.00        0.00       0.00       107.11     1.75         105.36     42449
LCK_M_IX                            0.86            0.92        0.92       0.00       77.08      77.03        0.04       84
LATCH_EX                            0.82            0.01        0.01       0.00       73.52      73.28        0.25       6681
*/

-- Enquanto uma thread está com PAGELATCH_EX, as outras vão esperar pra obter 
-- o PAGELATCH_SH

-- E se eu criar a tabela como in-memory 
-- pra ficar latch free?
-- Vamos testar...

-- Re-criar tabela e usar uma chave que não é sequencial...
-- + in-memory...
DROP TABLE IF EXISTS Table1
CREATE TABLE [dbo].[Table1]
(
  [Col1] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY NONCLUSTERED,
  [Col2] [varchar] (250) NOT NULL,
  [Col3] [varchar] (250) NOT NULL,
  Col4 char(200) NOT NULL DEFAULT 'x'
)
WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
GO

-- Clear Wait Stats 
DBCC SQLPERF('sys.dm_os_wait_stats'    , CLEAR)
DBCC SQLPERF('sys.dm_os_latch_stats'   , CLEAR)
DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR)
DELETE FROM Table1
CHECKPOINT -- Pra truncar o log...
GO

-- Executar .bat pra rodar proc em 
-- 500 threads e 30 iterations
EXEC xp_cmdShell '"D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 4 (Disk IO)\Scripts\23 - IO - Multiple Log Writers e sqlmin!SQLServerLogMgrLogFlush\RunQuery.cmd"'
GO

-- Wow, agora rodou em apenas 10/11 segundos...
-- Top Waits
SELECT * FROM master.dbo.vw_TopWaits
GO
/*
WaitType                            Wait Percentage AvgWait_Sec AvgRes_Sec AvgSig_Sec Wait_Sec   Resource_Sec Signal_Sec Wait Count
----------------------------------- --------------- ----------- ---------- ---------- ---------- ------------ ---------- ----------
SOS_SCHEDULER_YIELD                 54.44           0.02        0.00       0.02       182.52     0.02         182.51     9522
WRITELOG                            36.44           0.01        0.00       0.00       122.17     71.41        50.76      22248
PREEMPTIVE_OS_DISCONNECTNAMEDPIPE   2.17            0.01        0.01       0.00       7.27       7.27         0.00       500
PREEMPTIVE_OS_DELETESECURITYCONTEXT 2.03            0.01        0.01       0.00       6.82       6.82         0.00       500
LOGBUFFER                           1.92            0.00        0.00       0.00       6.45       1.64         4.81       4108
LOGMGR_FLUSH                        1.74            0.01        0.00       0.01       5.85       0.53         5.32       1024
IO_COMPLETION                       0.42            0.00        0.00       0.00       1.40       1.39         0.01       4004
PREEMPTIVE_OS_AUTHORIZATIONOPS      0.26            0.00        0.00       0.00       0.88       0.88         0.00       500
PREEMPTIVE_OS_QUERYCONTEXTATTRIBUTE 0.26            0.00        0.00       0.00       0.86       0.86         0.00       500
PREEMPTIVE_OS_REVERTTOSELF          0.24            0.00        0.00       0.00       0.81       0.81         0.00       500
*/

-- Agora o gargalo esta em CPU e na escrita no Log...
-- E se a gente definir a tabela como in-memory + schema_only? 
-- Vai escrever menos no log... não é ZERO, mas é bem menos... 
-- https://chrisadkin.io/2017/07/17/in-memory-engine-durability-schema_only-and-transaction-rollback/

-- Mas e se eu precisar dos dados? 
-- Não posso confiar no SCHEMA_ONLY né... 


-- E como estão os spinlocks? 
-- Top spinlocks
SELECT *
FROM sys.dm_os_spinlock_stats
ORDER BY collisions DESC;
GO
/*
name                        collisions           spins                spins_per_collision sleep_time           backoffs
--------------------------- -------------------- -------------------- ------------------- -------------------- --------------------
LOGFLUSHQ                   196119               227493296            1159.976            4121                 54822
LOGCACHE_ACCESS             30854                44040                1.427368            1206777              2012153
SOS_SUSPEND_QUEUE           9484                 4514583              476.021             57                   878
SOS_SCHEDULER               6995                 2414581              345.1867            15                   501
LOCK_HASH                   3401                 7723672              2271                1                    951
SOS_CACHESTORE              3166                 1325875              418.7855            0                    1326
SQL_MGR                     2799                 66772                23.85566            0                    11
LOCK_RW_CMED_HASH_SET       2714                 0                    0                   0                    0
OPT_IDX_STATS               2255                 80742                35.80576            0                    0
COMPPLAN_SKELETON           1825                 121012               66.30795            0                    1
SOS_TLIST                   864                  1169099              1353.124            15                   191
BLOCKER_ENUM                533                  22713                42.61351            1                    8
XDESMGR                     369                  23294                63.12737            0                    1
...
*/
-- Acesso ao LOGFLUSHQ e LOGCACHE_ACCESS... Acesso ao LogCache é serializado (só 1 por vez) 
-- via spinlock ... 
-- Lembra, só temos 1 thread fazendo LOG WRITER

-- Verificando que só temos 1 thread pro LogWriter
SELECT * FROM sys.dm_exec_requests
WHERE command LIKE '%LOG WRITER%'
GO

-- E se eu tiver mais de 1 thread? ... 
-- será que ajuda em algo? 

-- Vamos remover o TF9038 do startup e reiniciar SQL...


-- Agora temos 4 threads pro LogWriter
SELECT * FROM sys.dm_exec_requests
WHERE command LIKE '%LOG WRITER%'
GO

DBCC SQLPERF('sys.dm_os_wait_stats'    , CLEAR)
DBCC SQLPERF('sys.dm_os_latch_stats'   , CLEAR)
DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR)
DELETE FROM Table1 -- Truncate não suportado em tabelas memory optimized 
CHECKPOINT -- Pra truncar o log...
GO

-- Executar .bat pra rodar proc em 
-- 500 threads e 30 iterations
EXEC xp_cmdShell '"D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 4 (Disk IO)\Scripts\23 - IO - Multiple Log Writers e sqlmin!SQLServerLogMgrLogFlush\RunQuery.cmd"'
GO

-- Agora roda em apenas 7 segundos... e veja o uso de CPU enquanto roda!!! WOW...
-- Top Waits
SELECT * FROM master.dbo.vw_TopWaits
GO
/*
WaitType                            Wait Percentage AvgWait_Sec AvgRes_Sec AvgSig_Sec Wait_Sec   Resource_Sec Signal_Sec Wait Count
----------------------------------- --------------- ----------- ---------- ---------- ---------- ------------ ---------- ----------
SOS_SCHEDULER_YIELD                 29.43           0.00        0.00       0.00       237.01     0.10         236.91     49605
SOS_WORKER_MIGRATION                26.67           12.64       12.64      0.00       214.82     214.80       0.02       17
WRITELOG                            20.62           0.00        0.00       0.00       166.05     123.91       42.14      36271
LOGMGR_FLUSH                        17.77           0.00        0.00       0.00       143.15     37.54        105.61     126275
PAGEIOLATCH_SH                      1.56            0.00        0.00       0.00       12.53      12.46        0.06       4131
CMEMTHREAD                          0.88            0.00        0.00       0.00       7.12       6.97         0.15       3178
LOGBUFFER                           0.77            0.00        0.00       0.00       6.22       3.80         2.42       1814
LCK_M_S                             0.75            0.86        0.86       0.00       6.01       6.01         0.00       7
SOS_PHYS_PAGE_CACHE                 0.51            0.00        0.00       0.00       4.12       0.65         3.47       1303
IO_COMPLETION                       0.47            0.00        0.00       0.00       3.78       3.77         0.01       2923
*/

-- Da pra melhorar mais... sem dúvida... basta paciencia e ir ajustando aos poucos...
-- ? ALTER DATABASE Test_Fabiano_MultipleLogWriters SET DELAYED_DURABILITY = FORCED
-- ? tempdb
-- ? columnstore

-- Scripts uteis
/*
sp_whoisactive @get_locks = 1
GO
-- Top spinlocks
SELECT TOP 10 *
FROM sys.dm_os_spinlock_stats
ORDER BY spins_per_collision DESC;
GO
-- Top Waits
SELECT * FROM master.dbo.vw_TopWaits
GO
-- Top latches
SELECT * FROM master.dbo.vw_TopLatches
GO
-- Como estão os Waits? ... 
SELECT session_id, exec_context_id, wait_duration_ms, wait_type, resource_description
FROM sys.dm_os_waiting_tasks
WHERE wait_type <> 'DISPATCHER_QUEUE_SEMAPHORE'
ORDER BY session_id DESC
GO

-- Verifica espaço livre no log...
SELECT (total_log_size_in_bytes - used_log_space_in_bytes)*1.0/1024/1024 AS [free log space in MB]  
FROM sys.dm_db_log_space_usage;
GO
*/
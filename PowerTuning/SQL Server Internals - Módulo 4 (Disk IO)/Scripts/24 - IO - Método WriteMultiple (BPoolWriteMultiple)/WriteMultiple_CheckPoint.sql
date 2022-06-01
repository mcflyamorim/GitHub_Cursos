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
if exists (select * from sysdatabases where name='Test_Fabiano_WriteMultiple')
BEGIN
  ALTER DATABASE Test_Fabiano_WriteMultiple SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_WriteMultiple
end
GO
-- Criar banco de 1024MB no pendrive (E:\) e Log no C:\
-- 7 segundos pra rodar
CREATE DATABASE [Test_Fabiano_WriteMultiple]
 ON  PRIMARY 
( NAME = N'Test_Fabiano_WriteMultiple', FILENAME = N'E:\Test_Fabiano_WriteMultiple.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_WriteMultiple_log', FILENAME = N'C:\DBs\Test_Fabiano_WriteMultiple_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
-- Desabilitar indirect checkpoint... 
ALTER DATABASE Test_Fabiano_WriteMultiple SET TARGET_RECOVERY_TIME = 0 SECONDS WITH NO_WAIT
GO

USE Test_Fabiano_WriteMultiple
GO


-- Abrir perfmon e ver contadores...
-- ...\Scripts\24 - IO - Método WriteMultiple (BPoolWriteMultiple)\Perfmon.msc


-- Criar xEvent capturando file_read_completed
-- DROP EVENT SESSION CapturaIOs ON SERVER 

-- Criar evento pra capturar I/Os
CREATE EVENT SESSION [CapturaIOs] ON SERVER 
ADD EVENT sqlserver.file_write_completed(SET collect_path=(1)
    ACTION(sqlserver.session_id,sqlserver.sql_text)
    WHERE ([sqlserver].[equal_i_sql_unicode_string]([path],N'E:\Test_Fabiano_WriteMultiple.mdf')))
ADD TARGET package0.ring_buffer
WITH(MAX_DISPATCH_LATENCY = 1 SECONDS)
GO
-- Iniciar xEvent
ALTER EVENT SESSION CapturaIOs ON SERVER STATE = START;
GO

-- Abrir xEvent e clicar no "watch live data"... 

-- Gerar algumas modificações...
DROP TABLE IF EXISTS TabCheckPoint
GO
CREATE TABLE TabCheckPoint (Col1 CHAR(7500) DEFAULT NEWID())
GO
-- Inserindo algumas linhas (sujando mais páginas) na tabela o checkpoint é disparado?
SET NOCOUNT ON
BEGIN TRAN
GO
INSERT INTO TabCheckPoint DEFAULT VALUES
GO 10000
COMMIT
GO


-- Como ficou o cache? 
-- Quantas páginas sujas?...
SELECT Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END,
       DBName = DB_NAME(database_id),
       Pages = COUNT(1)
  FROM sys.dm_os_buffer_descriptors as bd
 WHERE bd.database_id = DB_ID('Test_Fabiano_WriteMultiple')
GROUP BY is_modified, database_id
GO

-- Nada do checkpoint entrar...

/*
  Estressar o disco E:\

  c:\sqlio\sqlio.exe -kR -t64 -dE -s9999 -b128
*/
-- Vamos gerar mais modificações... 

SET NOCOUNT ON
BEGIN TRAN
GO
INSERT INTO TabCheckPoint DEFAULT VALUES
GO 100000
COMMIT
GO


-- Ver resultado do XEvent e perfmon... 
-- I/Os de até 1MB(128 páginas) sendo executados... 

-- Enquanto isso no errorlog...
/*
  SQL Server has encountered 40 occurrence(s) of I/O requests taking longer than 15 seconds to complete on file [E:\Test_Fabiano_WriteMultiple.mdf] in database id 10.  The OS file handle is 0x00000000000085B0.  The offset of the latest long I/O is: 0x0000002237e000.  The duration of the long I/O is: 16699 ms.

  last target outstanding: 2, avgWriteLatency 111
  average throughput:   0.19 MB/sec, I/O saturation: 1009, context switches 2085
  average writes per second:   0.24 writes/sec
  FlushCache: cleaned up 11208 bufs with 109 writes in 463587 ms (avoided 8791 new dirty bufs) for db 10:0
*/
-- Pra resolver esses problemas, ver o internals de memória parte 1, onde falo sobre checkpoint...

-- Cleanup
DROP EVENT SESSION CapturaIOs ON SERVER 
GO

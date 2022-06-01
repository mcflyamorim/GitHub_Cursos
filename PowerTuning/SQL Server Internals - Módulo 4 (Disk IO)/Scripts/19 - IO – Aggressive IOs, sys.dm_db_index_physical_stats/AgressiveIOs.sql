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

-- 10 minutos pra rodar...
if exists (select * from sysdatabases where name='Test_Fabiano_AgressiveIOs')
BEGIN
  ALTER DATABASE Test_Fabiano_AgressiveIOs SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_AgressiveIOs
end
GO
CREATE DATABASE Test_Fabiano_AgressiveIOs
 ON  PRIMARY 
( NAME = N'Test_Fabiano_AgressiveIOs', FILENAME = N'C:\DBs\Test_Fabiano_AgressiveIOs.mdf' , SIZE = 5GB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_AgressiveIOs_log', FILENAME = N'C:\DBs\Test_Fabiano_AgressiveIOs_log.ldf' , SIZE = 500MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
USE Test_Fabiano_AgressiveIOs
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 300000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO [OrdersBig]
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
 CROSS JOIN Northwind.dbo.Orders E
OPTION (MAXDOP 12)
GO
CREATE CLUSTERED INDEX ixClustered ON [OrdersBig](CustomerID)
GO


-- Algumas operações podem gerar uma quantidade massiva de IOPS
-- e IOs com tamanho bem grande
USE Test_Fabiano_AgressiveIOs
GO

-- 9595.62 MBs
-- SELECT 9825920 / 1024.
EXEC sp_spaceused OrdersBig
GO


-- Abrir perfmon e ver contadores...
-- ...\Scripts\19 - IO – Aggressive IOs, sys.dm_db_index_physical_stats\Perfmon.msc


-- Criar xEvent capturando file_read_completed
-- DROP EVENT SESSION CapturaIOs ON SERVER 

-- Ajustar o filtro pra pegar apenas dados dessa sessão...
SELECT @@SPID
GO
CREATE EVENT SESSION [CapturaIOs] ON SERVER 
ADD EVENT sqlserver.file_read_completed(
    ACTION(sqlserver.session_id,sqlserver.sql_text)
    WHERE ([sqlserver].[session_id]=(51)))
ADD TARGET package0.ring_buffer
WITH(MAX_DISPATCH_LATENCY = 1 SECONDS)
GO



-- Iniciar xEvent
ALTER EVENT SESSION CapturaIOs ON SERVER STATE = START;
GO

-- Abrir xEvent e clicar no "watch live data"... 

CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
-- Ler os dados da tabela via ReadFileScatter
SET STATISTICS IO, TIME ON
SELECT COUNT(*) FROM OrdersBig
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
GO
-- Maior I/O via read-ahead foi de 512 páginas, 4MB...

-- Disk transfer/sec bem alto... 
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID('Test_Fabiano_AgressiveIOs'), OBJECT_ID('OrdersBig'), 1, NULL, 'DETAILED')
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
-- MaxDop 20... Current disk queue bem alto... e disk transfers tbm alto...
SET STATISTICS IO, TIME ON
SELECT COUNT(*) FROM OrdersBig
OPTION (MAXDOP 20)
SET STATISTICS IO, TIME OFF
GO
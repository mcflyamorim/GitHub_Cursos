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

-- 30 segundos pra rodar...
if exists (select * from sysdatabases where name='Test_Fabiano_BatchSort')
BEGIN
  ALTER DATABASE Test_Fabiano_BatchSort SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_BatchSort
end
GO
CREATE DATABASE Test_Fabiano_BatchSort
 ON  PRIMARY 
( NAME = N'Test_Fabiano_BatchSort', FILENAME = N'D:\DBs\Test_Fabiano_BatchSort.mdf' , SIZE = 1GB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_BatchSort_log', FILENAME = N'C:\DBs\Test_Fabiano_BatchSort_log.ldf' , SIZE = 50MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE Test_Fabiano_BatchSort
GO
-- Criando tabela para testes...
-- 1 minuto pra rodar...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 10000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixCustomerID ON OrdersBig (CustomerID)
GO


-- Abrir perfmon em e analisar contadores...
-- ...\Scripts\10 - IO - Batch sort\Perfmon.msc


CHECKPOINT; DBCC DROPCLEANBUFFERS()
-- Incluir dados do ixCustomerID na memória...
SELECT COUNT(*) FROM OrdersBig WITH(INDEX=ixCustomerID)
GO

-- Query com batch sort...
SET STATISTICS IO, TIME ON
DECLARE @dt DATE
SELECT TOP 20000 @dt = OrderDate
  FROM OrdersBig WITH(FORCESEEK)
 WHERE CustomerID >= 0
OPTION (RECOMPILE, MAXDOP 1
                 --,QueryTraceON 2340 -- Desabilita BatchSort
       )
SET STATISTICS IO, TIME OFF
-- Scan count 1, logical reads 101891, physical reads 1, read-ahead reads 32696
-- SQL Server Execution Times:
--  CPU time = 297 ms,  elapsed time = 12580 ms.
GO


CHECKPOINT; DBCC DROPCLEANBUFFERS()
-- Incluir dados do ixCustomerID na memória...
SELECT COUNT(*) FROM OrdersBig WITH(INDEX=ixCustomerID)
GO


-- Query sem batch sort...
-- Read ahead/sec é menor... 
-- Demora o dobro do tempo...
SET STATISTICS IO, TIME ON
DECLARE @dt DATE
SELECT TOP 20000 @dt = OrderDate
  FROM OrdersBig WITH(FORCESEEK)
 WHERE CustomerID >= 0
OPTION (RECOMPILE, MAXDOP 1
                 , QUERYTRACEON 2340 -- Desabilita BatchSort
       )
SET STATISTICS IO, TIME OFF
-- Scan count 1, logical reads 77272, physical reads 284, read-ahead reads 33280
-- SQL Server Execution Times:
--  CPU time = 219 ms,  elapsed time = 26803 ms.
GO


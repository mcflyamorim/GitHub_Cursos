USE Northwind
GO
-- Preparar ambiente... Criar tabelas com 90 mil linhas...
-- 2 minutos e 25 secs pra rodar
IF OBJECT_ID('TesteCXPacket') IS NOT NULL
  DROP TABLE TesteCXPacket
GO
SELECT TOP 90000
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000)) AS Col1
  INTO TesteCXPacket
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
OPTION (MAXDOP 4)
GO
CREATE CLUSTERED INDEX ix1 ON TesteCXPacket(CustomerID)
GO

-- Query com MAXDOP 1 pra não "gastar" muito CPU...
SET STATISTICS IO, TIME ON
GO
SELECT * FROM TesteCXPacket
WHERE CustomerID <= -1
  AND Col1 = 0x321
ORDER BY Value
OPTION (RECOMPILE, MAXDOP 1)
GO
SET STATISTICS IO, TIME OFF
GO

-- Porque demora tanto pra rodar? 
-- Porque CPU bate 100%?
-- Porque sys.dm_os_waiting_tasks mostra várias linhas e wait em CXPACKET?

SELECT * FROM sys.dm_os_waiting_tasks
WHERE session_id = 55
GO

-- Pode uma query com OPTION(MAXDOP 1) fazer uso de paralelismo?





/*
  https://docs.microsoft.com/en-us/sql/t-sql/statements/update-statistics-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
  Starting with SQL Server 2016 (13.x), sampling of data to build statistics 
  is done in parallel, when using compatibility level 130, to improve 
  the performance of statistics collection. The query optimizer will use 
  parallel sample statistics, whenever a table size exceeds a certain threshold.

  https://docs.microsoft.com/en-us/archive/blogs/sqlserverstorageengine/query-optimizer-additions-in-sql-server
  Collection of statistics using FULLSCAN can be run in parallel since SQL Server 2005. 
  In SQL Server 2016 under compatibility level 130, we have enabled collection of 
  statistics using SAMPLE in parallel (up to 16 degree of parallelism), which 
  decreases the overall stats update elapsed time. Since auto created stats 
  are sampled by default, all such will be updated in parallel under the latest compatibility level.

  https://support.microsoft.com/en-us/help/4041809/kb4041809-update-adds-support-for-maxdop-for-create-statistics-and-upd
  KB4041809 - Update adds support for MAXDOP option 
  for CREATE STATISTICS and UPDATE STATISTICS statements in SQL Server 2014, 2016 and 2017

  https://sqlperformance.com/2016/07/sql-statistics/statistics-maxdop
*/



sp_helpstats TesteCXPacket
GO
DROP STATISTICS TesteCXPacket._WA_Sys_00000004_01142BA1
GO
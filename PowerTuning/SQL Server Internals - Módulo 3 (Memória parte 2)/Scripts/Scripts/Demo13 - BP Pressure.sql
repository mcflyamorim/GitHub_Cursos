/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind
GO

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 2GB
EXEC sp_configure 'max server memory', 2048
RECONFIGURE
GO


-- 1 minute to run
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 5000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
-- 1 minute to run...
-- Creating a 200000 rows table...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 200000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(5000), NEWID()) AS Col2
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO


-- Table has +- 1565.76MB
-- We've 2GB available to BP, table should fit in it...
EXEC sp_spaceused ProductsBig
GO


-- Disable read ahead to make physical reads worse...
DBCC TRACEON(652)
GO


-- First execution takes 6/8 seconds...
-- All physical reads
SET STATISTICS IO ON
SELECT COUNT(*) 
  FROM ProductsBig
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
-- Table 'ProductsBig'. Scan count 1, logical reads 200002, physical reads 25004, read-ahead reads 0
GO

-- How BP looks like? 
SELECT TOP 10 type, name, pages_kb / 1024 AS size_mb FROM sys.dm_os_memory_clerks
ORDER BY 3 DESC
GO


-- Second execution takes 0 seconds...
-- All logical reads
SET STATISTICS IO ON
SELECT COUNT(*) 
  FROM ProductsBig
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
-- Table 'ProductsBig'. Scan count 1, logical reads 200002, physical reads 0, read-ahead reads 0
GO


ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=66)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- What if I run a query that requires lot of memory grant?
-- 926MB of memory grant
-- OrdersBig = 144MB size on BP data cache...
DECLARE @i Int
SELECT @i = OrderID + Value 
  FROM OrdersBig
 ORDER BY Value
OPTION (MIN_GRANT_PERCENT = 100)
GO


-- Third execution should take 0 seconds...
-- All logical reads ? Right? 
SET STATISTICS IO ON
SELECT COUNT(*) 
  FROM ProductsBig
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
-- Table 'ProductsBig'. Scan count 1, logical reads 200002, physical reads 0, read-ahead reads 0
GO

-- What if I run a query that requires lot of memory grant?
-- 926MB of memory grant
-- OrdersBig = 144MB size on BP data cache...
DECLARE @i Int
SELECT @i = OrderID + Value 
  FROM OrdersBig
 ORDER BY Value
OPTION (MIN_GRANT_PERCENT = 100)
GO
-- How BP looks like? 
SELECT TOP 10 type, name, pages_kb / 1024 AS size_mb FROM sys.dm_os_memory_clerks
ORDER BY 3 DESC
GO


-- Cleanup
ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=25)
GO
ALTER RESOURCE GOVERNOR DISABLE;
GO


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

-- Creating a 2 million rows table...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 2000000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO


-- If there is not have enough memory to run the query, it will wait... 
-- and eventually time out... 
-- When a query memory grant timeout, its grant can be reduced to minimum mg, 
-- if minimum is not available, throw error 8645.... 
-- i.e = 25x query cost in seconds... or 250 cost = 4.1 minutes... 
-- max/limit of 24 hours (86400 seconds)... 
-- RG can be used to adjust this timeout...
-- Query wait at instance level can also be used...



-- Scenario 1
-- There is enought memory to run query, but queue is different


-- For instance
-- Let's suppose the following query
-- Memory grant = 102440KB 
DECLARE @Top INT = 448500
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 448500))
GO

-- How many queries we can run in parallel, without wait?
-- What's is the maximum Workspace Memory?

-- query workspace memory grant perf counter
SELECT * 
  FROM sys.dm_os_performance_counters
 WHERE counter_name = 'Maximum Workspace Memory (KB)'
GO
-- In MB?
SELECT 1575840 / 1024. -- 1538.90MB
GO
-- Worskpace / QueryMemoryGrant
SELECT 1575840 / 102440. -- 15.38
GO

-- Answer = 15 Queries?
-- Let's try 20 on SQLQueryStress (20 threads and 5 iterations...)

EXEC sp_whoisactive


-- Why it is not running 15 if there is enough memory available ?
-- (query sys.dm_exec_query_resource_semaphores)?
-- Query will not start unless available workspace is 150% of requested grant...
-- in other words, it requires +- 150MB 
-- to be available

-- For how long query 16 will wait? 
-- QueryCost * 25
-- SELECT 128.75 * 25 = 3218.75



-- Let's try 100 on SQLQueryStress (100 threads and 5 iterations...)

-- Run one more query while querystress is running 100 threads
-- This will wait a LOT since position on queue is very low...
-- Did we had a MemoryGrant warning? 
DECLARE @Top INT = 448500
DECLARE @Var1 INT, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 448500))
GO

-- While it is running/waiting... check wait_order column on sys.dm_exec_query_memory_grants
GO


ALTER WORKLOAD GROUP [default] WITH(REQUEST_MEMORY_GRANT_TIMEOUT_SEC=1)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO


-- What now?
-- now we've got our minimum grant and query is running... 
DECLARE @Top INT = 448500
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 448500))
GO


-- Set RG back to default value...
ALTER WORKLOAD GROUP [default] WITH(REQUEST_MEMORY_GRANT_TIMEOUT_SEC=0)
GO
ALTER RESOURCE GOVERNOR DISABLE;
GO
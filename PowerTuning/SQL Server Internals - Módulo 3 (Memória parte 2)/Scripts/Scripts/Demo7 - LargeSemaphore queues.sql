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


-- Query is categorized based on cost and grant size... 
-- depending on the cost and grant size, 
-- it set it to its specific queue on proper semaphore
-- Two semaphore queues - intended to favor lower-cost queries
--- Small memory grant - queries with cost of < 3 and grant size < 5MB
--- Large semaphore - everything else
--- Large semaphore has 5 queues...  
-- query cost <10, 10-99, 100-999, 1000-9999, 10k+


-- Run queries on sqlquerystress to check data on sys.dm_exec_query_memory_grants


-- is_small = 1
-- Small query... requires less than 5MB and cost is lower than 3
-- goes to low resource_semaphore
DECLARE @Top INT = 100
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 20000), MAX_GRANT_PERCENT = 1)
GO

-- Query cost = 7.88
-- Query queue = 5 (cost between <10)
DECLARE @Top INT = 2000000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 95000), MIN_GRANT_PERCENT = 50)
GO

-- Query cost = 12.90
-- Query queue = 6 (cost between 10-99)
DECLARE @Top INT = 2000000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 150000), MIN_GRANT_PERCENT = 50)
GO


-- Query cost = 245.32
-- Query queue = 7 (cost between 100-999)
DECLARE @Top INT = 2000000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 850000), MIN_GRANT_PERCENT = 50)
GO


-- Query cost = 1052.16
-- Query queue = 8 (cost between 1000-9999)
DECLARE @Top INT = 2000000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = Tab1.ProductID, @Var2 = Tab1.ProductName, @Var3 = Tab1.Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 INNER HASH JOIN ProductsBig
    ON ProductsBig.ProductID = Tab1.ProductID
 ORDER BY Tab1.ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 2000000), MIN_GRANT_PERCENT = 50)
GO

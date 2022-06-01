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

-- Creating a 4 million rows table...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 4000000 IDENTITY(Int, 1,1) AS ProductID, 
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


-- Calculating workspace size and single query grant
SELECT (2048 * 75.) / 100 -- 1536MB -- 75% of MaxServerMemory
SELECT (1536 * 25.) / 100 -- 348MB -- 25% of Workspace


-- What if a query needs a LOT of memory to run a sort?
-- Estimated data size = 557MB
-- Memory grant = 374256KB (limit.. 25% of workspace memory grant available)
-- 17 seconds to run...

DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM ProductsBig
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, RECOMPILE)
GO

-- How to expand it?

ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=100)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- Memory grant = 909488KB
-- No warning...
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM ProductsBig
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, RECOMPILE)
GO


-- Set request_max_memory_grant_percent back to 25%
ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=25)
GO
ALTER RESOURCE GOVERNOR DISABLE;
GO

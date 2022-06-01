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


-- Calculating workspace size and single query grant
SELECT (2048 * 75.) / 100 -- 1536MB -- 75% of MaxServerMemory
SELECT (1536 * 25.) / 100 -- 348MB -- 25% of Workspace



-- Memory grant ideal determined by QO 
-- (hey, remember this is based on ESTIMATED number of rows...)

-- How much memory granted to sort only 10k rows?
-- memory grant = 4MB
DECLARE @Top INT = 2000000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 10000))
GO


-- Statistics... Estimated number of rows and row size... 
-- What would be the estimation for the whole table (2000000 rows)? 

-- What is ProductsBig's row size?
-- SELECT (4 + 8 + 250) = 262
SELECT Name, length
  FROM syscolumns
 WHERE OBJECT_ID('ProductsBig') = id
GO

-- How many rows? 2000000
-- SELECT 262 * 2000000 = 524000000 bytes...
-- SELECT 524000000 / 1024 / 1024 = 499MB
SELECT Name, rowcnt
  FROM sysindexes
 WHERE OBJECT_ID('ProductsBig') = id
   AND indid <= 1
GO

-- Why it is estimated data size is 278MB instead of 499MB?
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM ProductsBig
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, RECOMPILE)
GO

-- VarChar(200) = /2 -- It consider only half of data is filled...

-- ESTIMATED Row size is:
SELECT (4 + 4 + 125) = 133
SELECT 133 * 2000000 = 266000000 bytes...
SELECT 266000000 / 1024 / 1024 = 253MB...

-- 253MB is closer to actual estimation... 
-- do not expect to see 100% precise numbers here... 
GO


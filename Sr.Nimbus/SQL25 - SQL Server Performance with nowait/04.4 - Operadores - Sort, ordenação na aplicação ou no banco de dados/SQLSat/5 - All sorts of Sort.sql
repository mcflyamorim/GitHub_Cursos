/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/


USE Northwind
GO

-- Create 1 million rows test table
-- 3 secs to run
IF OBJECT_ID('ProductsBig') IS NOT NULL
BEGIN
  DROP TABLE ProductsBig
END
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS ProductID, 
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
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL
GO
SET STATISTICS TIME ON
GO

-- Sort warning, see warning at actual execution plan!
-- Aaaa but the time is really fast (less than a sec), 
-- should I worry about the warning?
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2747
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE)
GO


-- "Fool" QO to get more memory for the query
DECLARE @i Int = 2747
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND @i
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE, OPTIMIZE FOR (@i = 5000))
GO



-- SQLQueryStress demos...





-- Note: On SQL2016 two new query hints MIN_GRANT_PERCENT and MAX_GRANT_PERCENT 
-- are added to specify memory grants in percent

-- Don't do this... unless you like RESOURCE_SEMAPHORE waits... 
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2747
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE, MIN_GRANT_PERCENT = 100)
GO


-- Performance results

-- HDD = 1 min and 9/55 seconds
-- HDD with 8 tempdb data files... (to "fix" tempdb allocation contention) = several mins
-- 1 SSD = 5/6 seconds...
-- 2 SSD -- two tempdb data files = 2/4 seconds
-- No tempdb usage, no spill = 20ms
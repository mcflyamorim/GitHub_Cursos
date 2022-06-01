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

IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1
GO
-- Table with 1 page per row...
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
                       Col1 Char(5000),
                       Col2 Char(1250),
                       Col3 Char(1250),
                       Col4 Numeric(18,2))
GO
-- 25 secs to run...
INSERT INTO TestTab1 WITH(TABLOCK) (Col1, Col2, Col3, Col4) 
SELECT TOP 1000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 30
CREATE INDEX ix_Col4 ON TestTab1(Col4)
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
CREATE INDEX ix1 ON ProductsBig (Col1)
GO

CHECKPOINT
GO


-- Why does it need 33056KB of memory grant?
-- There is no "memory consumer" operator in the plan...
SELECT TestTab1.*
  FROM TestTab1
 INNER JOIN ProductsBig
    ON ProductsBig.Col1 = TestTab1.Col1
 WHERE Col4 < 50
OPTION (RECOMPILE) 
GO














-- Answer: LoopJoin Optimized = True (BatchSort)




-- Use SQLQueryStress (5 iterations 100 threads) to run many queries on queue 6 (10-99)
-- to cause contention...
-- Query cost = 12.90
-- Query queue = 6 (cost between 10-99)
DECLARE @Top INT = 100000
DECLARE @Var1 Int, @Var2 VARCHAR(200), @Var3 VARCHAR(250)
SELECT  @Var1 = ProductID, @Var2 = ProductName, @Var3 = Col1
  FROM (SELECT TOP (@Top) * FROM ProductsBig) AS Tab1
 ORDER BY ProductName DESC
OPTION (MAXDOP 1, OPTIMIZE FOR (@Top = 150000), MIN_GRANT_PERCENT = 50)
GO

-- Query with BatchSort will wait on MemoryGrant
SELECT TestTab1.*
  FROM TestTab1
 INNER JOIN ProductsBig
    ON ProductsBig.Col1 = TestTab1.Col1
 WHERE Col4 < 50
OPTION (RECOMPILE) 
GO

-- Disable BatchSort will trigger random I/Os 
-- but will not wait on resource_semaphore
SELECT TestTab1.*
  FROM TestTab1
 INNER JOIN ProductsBig
    ON ProductsBig.Col1 = TestTab1.Col1
 WHERE Col4 < 50
OPTION (RECOMPILE ,QueryTraceON 2340) -- Disable BatchSort 
GO
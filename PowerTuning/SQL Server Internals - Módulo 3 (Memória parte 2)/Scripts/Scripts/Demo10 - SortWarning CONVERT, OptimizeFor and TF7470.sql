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

IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
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

-- ALTER TABLE ProductsBig DROP COLUMN ColTest
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL
GO

-- Runs in 0 seconds
-- No sort warning
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2000
 ORDER BY ColTest
OPTION (RECOMPILE)


-- Spill to tempdb and Sort Warning...
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2800
 ORDER BY ColTest
OPTION (RECOMPILE)

-- Is this Warning that bad?
-- Test o SQLQueryStress 



-- Fixing it by using OptimizeFor 
DECLARE @i Int = 2800
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND @i
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE, OPTIMIZE FOR (@i = 50000))
GO

-- Fixing it by using Convert 
DECLARE @i Int = 2800
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND @i
 ORDER BY CONVERT(VARCHAR(4000), ColTest)
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Fixing it by using Convert TF7470
DECLARE @i Int = 2800
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND @i
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE, QueryTraceOn 7470)
GO

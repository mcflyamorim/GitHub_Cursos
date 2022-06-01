/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/


USE Northwind
GO

-- Create 10k rows test table
IF OBJECT_ID('ProductsBig') IS NOT NULL
BEGIN
  DROP TABLE ProductsBig
END
GO
SELECT TOP 10000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(CHAR(2000), NEWID()) AS Col2
  INTO ProductsBig
  FROM master.dbo.sysobjects A
 CROSS JOIN master.dbo.sysobjects B
 CROSS JOIN master.dbo.sysobjects C
 CROSS JOIN master.dbo.sysobjects D
GO
-- ALTER TABLE ProductsBig DROP COLUMN ColTest
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL DEFAULT NEWID()
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO


-- Does not spill data to tempdb... no warning
CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 756
 ORDER BY ColTest
GO

-- Read one more row is enough to write ALL pages into tempdb...
-- :-( ...
CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 757
 ORDER BY ColTest
GO


-- Fix issue... but estimate more than necessary...
CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 757
 ORDER BY CONVERT(VARCHAR(8000), ColTest)
GO

-- There are several other options to fix it... TFs (7470),
-- hints, subqueries... 


-- What about new SQL2016 batch mode Sort? 


-- Creating a dummy ColumStore index to enable batch mode operators...

-- NIIIIIICEEEEE
DROP INDEX IF EXISTS ix1 ON ProductsBig
GO

CREATE NONCLUSTERED COLUMNSTORE INDEX ix1 ON ProductsBig(ProductID)
 WHERE ProductID = -1 AND ProductID = -2;
GO


-- Batch mode used much more memory...
-- Ok, no spill...
-- Wasting memory ? ... see warning...
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT *
  FROM ProductsBig
 WHERE 1=1 -- Avoid auto param... 
   AND ProductID BETWEEN 1 AND 757
 ORDER BY ColTest
GO

-- How many of them I can run in parallel? 

-- SQL Query Stress...

-- 200 iterations
-- 10 threads...
-- How's that possible? 

EXEC sp_whoisactive
GO

SELECT * FROM sys.dm_exec_query_memory_grants
GO


-- NOTE: On SQL2017 it only works with BATCH MODE
-- On SQL2019 it also works with RowMode :-)... 

-- Drop columnstore index...
DROP INDEX ix1 ON ProductsBig
GO


CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 757
 ORDER BY ColTest
GO
/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind
GO

EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO


-- Create 4m rows test table
IF OBJECT_ID('ProductsBig') IS NOT NULL
BEGIN
  DROP TABLE ProductsBig
END
GO
SELECT TOP 4000000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO ProductsBig
  FROM master.dbo.sysobjects A
 CROSS JOIN master.dbo.sysobjects B
 CROSS JOIN master.dbo.sysobjects C
 CROSS JOIN master.dbo.sysobjects D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO

-- Create a proc to return some data using a paging control...
DROP PROC IF EXISTS st_ReturnData 
GO
CREATE PROC st_ReturnData @PageNumber AS INT = 1, @RowsPerPage AS INT = 20
AS
SELECT *
  FROM ProductsBig
 ORDER BY Col2
OFFSET ((@PageNumber - 1) * @RowsPerPage) ROWS
 FETCH NEXT @RowsPerPage ROWS ONLY
OPTION (RECOMPILE, MAXDOP 1)
GO


-- Rodar app "Demo19 - App" --




CHECKPOINT; DBCC DROPCLEANBUFFERS(); ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
GO
SET STATISTICS TIME ON
-- Return page 1 to 5 data is fast... 
EXEC st_ReturnData @PageNumber = 1, @RowsPerPage = 20
EXEC st_ReturnData @PageNumber = 2, @RowsPerPage = 20
EXEC st_ReturnData @PageNumber = 3, @RowsPerPage = 20
EXEC st_ReturnData @PageNumber = 4, @RowsPerPage = 20
EXEC st_ReturnData @PageNumber = 5, @RowsPerPage = 20
GO
-- Return page 6 data takes 6 seconds... 
-- What happened?...
-- Tip, it is NOT a spill, look at the actual plan, no warnings
---- sort was processed in memory...
EXEC st_ReturnData @PageNumber = 6, @RowsPerPage = 20
SET STATISTICS TIME OFF
GO


-- What about new SQL2016 batch mode Sort? Would it help?

-- Creating a dummy ColumStore index to enable batch mode operators...
-- NIIIIIICEEEEE
DROP INDEX IF EXISTS ix1 ON ProductsBig
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX ix1 ON ProductsBig(ProductID)
 WHERE ProductID = -1 AND ProductID = -2;
GO

-- Run procedure again... 
-- All good, all queries taking 1 second to run...


-- But...
-- Batch mode requires LOT more query memory...
-- Wasting memory ? ... see warning...
EXEC st_ReturnData @PageNumber = 1, @RowsPerPage = 50
GO
-- Even on cases where more than 100 rows are readed
-- used memory is very small... but, granted is a lot
-- it may cause resource_semaphore waits...
EXEC st_ReturnData @PageNumber = 3, @RowsPerPage = 50
GO

-- Create a proc to return some data using a paging control...
DROP PROC IF EXISTS st_ReturnDataIgnoreColumStore 
GO
CREATE PROC st_ReturnDataIgnoreColumStore @PageNumber AS INT = 1, @RowsPerPage AS INT = 20
AS
SELECT *
  FROM ProductsBig
 ORDER BY Col2
OFFSET ((@PageNumber - 1) * @RowsPerPage) ROWS
 FETCH NEXT @RowsPerPage ROWS ONLY
OPTION (RECOMPILE, MAXDOP 1, IGNORE_NONCLUSTERED_COLUMNSTORE_INDEX)
GO

-- A lot of reserved memory is better than a lot of 
-- reserved, used memory and bad performance...
-- So, in the end it is worthy... 
-- Specially on SQL2017+ and memory grant feedback 
-- memory grant feedback (don't work with option recompile)
EXEC st_ReturnData @PageNumber = 6, @RowsPerPage = 20
GO
EXEC st_ReturnDataIgnoreColumStore @PageNumber = 6, @RowsPerPage = 20
GO

-- Drop columnstore index...
DROP INDEX ix1 ON ProductsBig
GO
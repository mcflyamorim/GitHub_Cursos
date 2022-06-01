/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

-------------------------------
-------- Prefetching ----------
-------------------------------
--USE Master
--GO
--DROP DATABASE TestPrefetch
--GO

---- 10 secs
---- 512mb DB
--CREATE DATABASE TestPrefetch ON  PRIMARY 
--( NAME = N'TestPrefetch1', FILENAME = N'E:\TestPrefetch1.mdf' , SIZE = 512000KB , FILEGROWTH = 1024KB ) 
-- LOG ON 
--( NAME = N'TestPrefetch_log', FILENAME = N'E:\TestPrefetch_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
--GO
--ALTER DATABASE TestPrefetch SET RECOVERY SIMPLE 
--GO

--USE TestPrefetch
--GO
--IF OBJECT_ID('TestTab1') IS NOT NULL
--  DROP TABLE TestTab1
--GO
---- Table with 1 page per row...
--CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
--                       Col1 Char(5000),
--                       Col2 Char(1250),
--                       Col3 Char(1250),
--                       Col4 Numeric(18,2))
--GO
---- 5 minutes to run...
--INSERT INTO TestTab1 WITH(TABLOCK) (Col1, Col2, Col3, Col4) 
--SELECT TOP 1000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
--  FROM sysobjects a
-- CROSS JOIN sysobjects b
-- CROSS JOIN sysobjects c
-- CROSS JOIN sysobjects d
--GO 30
--CREATE INDEX ix_Col4 ON TestTab1(Col4)
--GO
--CHECKPOINT
--GO



/*
   FIRST, EXPLAIN PAGE PREFETCH
   FIRST, EXPLAIN PAGE PREFETCH
   FIRST, EXPLAIN PAGE PREFETCH
   FIRST, EXPLAIN PAGE PREFETCH

   
   Outer side of loop join is pretty good, usually sequential I/O with read-ahead doing pretty good job... 
   Inner side of loop joins is random and therfore usually, slowly... 
   Page prefetch idea is to issue many asynchronous I/O for index pages that will be needed by the inner side...

   References:
   https://www.simple-talk.com/sql/performance/sql-server-prefetch-and-query-performance/
   http://sqlblog.com/blogs/paul_white/archive/2013/08/31/sql-server-internals-nested-loops-prefetching.aspx
*/









-- First test, save DB into single disk...
-- First test, save DB into single disk...
-- First test, save DB into single disk...
-- First test, save DB into single disk...

USE master
GO
ALTER DATABASE TestPrefetch SET OFFLINE 
GO

-- CREATE SIMPLE VOLUME USING 1 DISK...


-- Copy DB files single disk volume E:\ from C:\temp
-- 2 mins to run...
EXEC xp_cmdShell 'copy c:\temp\testPrefe* E:\'
GO

-- SET DB online
-- 40 secs to run
ALTER DATABASE TestPrefetch SET ONLINE
GO


USE TestPrefetch
GO


-- Test prefetch DISABLED
-- 12/15 seconds to run
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS;
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 50
OPTION (RECOMPILE,
        QueryTraceON 8744) -- Disable Prefetch
GO


-- Test prefetch ENABLED
-- 11/13 seconds to run
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 50.0
OPTION (RECOMPILE)
GO


-- Second test, save DB into striped volume using 4 "disks"...
-- Second test, save DB into striped volume using 4 "disks"...
-- Second test, save DB into striped volume using 4 "disks"...
-- Second test, save DB into striped volume using 4 "disks"...

USE master
GO
ALTER DATABASE TestPrefetch SET OFFLINE 
GO

---- If necessary Copy DB files to C:\temp
---- 35 seconds to run...
--EXEC xp_cmdShell 'copy E:\* c:\temp\'
--GO

-- Create striped volume on VM1


-- Copy DB files back to volume E:\ from C:\temp
-- 1 min and 33 seconds to run...
EXEC xp_cmdShell 'copy c:\temp\testPrefe* E:\'
GO

-- SET DB online
-- 20 secs to run
ALTER DATABASE TestPrefetch SET ONLINE
GO

USE TestPrefetch
GO

-- Test prefetch DISABLED
-- Same 12/15 seconds to run
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS;
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 50
OPTION (RECOMPILE,
        QueryTraceON 8744) -- Disable Prefetch
GO


-- Test prefetch ENABLED
-- 4/5 seconds to run
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 50.0
OPTION (RECOMPILE)
GO


-- WHEN IT BECAMES A PROBLEM? 

-- Creating a proc to the test query
IF OBJECT_ID('st_Test1') IS NOT NULL
  DROP PROC st_Test1
GO
CREATE PROC st_Test1 @i Numeric(18,2)
AS
BEGIN
  SELECT *
    FROM TestTab1
   WHERE TestTab1.Col4 < @i
END
GO

-- If less then 25 rows is being returned from the outer table
-- then don't enable prefetch (harcoded value)
-- 0 secs
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 0.05
GO

-- What now that I'm reusing the cached plan?
-- 13 secs
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 50.0
GO


-- What if I ask for a recompile?
-- 5 secs and prefetch enabled
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 50.0 WITH RECOMPILE
GO


-- Notes: 
-- Not all flowers... May require more CPUs and read rows at repeatable read isolation level...


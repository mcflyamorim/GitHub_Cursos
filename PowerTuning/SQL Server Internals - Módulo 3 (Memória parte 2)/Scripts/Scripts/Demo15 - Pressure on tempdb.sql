/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/


-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'D:\datatempdbSQL2017.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'D:\datatemplogSQL2017.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


USE Northwind
GO


-- Allocation contention...
IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL
  DROP TABLE #TMP1

SELECT TOP(10000) 
    a.* 
INTO #TMP1 
FROM 
    master..sysobjects a, 
    master..sysobjects b,
    master..sysobjects c

-- SQL Query Stress --
-- 20 threads 10 iterations...


SELECT * FROM sys.dm_os_waiting_tasks
where session_id > 50
GO

sp_WhoIsActive
GO


-- had to add 18 files to fix PFS contention... 
-- Script to add new files
USE tempdb
GO
DBCC SHRINKFILE('tempdev2', EMPTYFILE)
DBCC SHRINKFILE('tempdev3', EMPTYFILE)
DBCC SHRINKFILE('tempdev4', EMPTYFILE)
DBCC SHRINKFILE('tempdev5', EMPTYFILE)
DBCC SHRINKFILE('tempdev6', EMPTYFILE)
DBCC SHRINKFILE('tempdev7', EMPTYFILE)
DBCC SHRINKFILE('tempdev8', EMPTYFILE)
GO
USE master
GO
ALTER DATABASE tempdb REMOVE FILE tempdev2;
ALTER DATABASE tempdb REMOVE FILE tempdev3;
ALTER DATABASE tempdb REMOVE FILE tempdev4;
ALTER DATABASE tempdb REMOVE FILE tempdev5;
ALTER DATABASE tempdb REMOVE FILE tempdev6;
ALTER DATABASE tempdb REMOVE FILE tempdev7;
ALTER DATABASE tempdb REMOVE FILE tempdev8;
GO

USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'D:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'D:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'D:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'D:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'D:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'D:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'D:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO

EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO




USE Northwind
GO
-- 6 seconds to run...
IF OBJECT_ID('TesteTempdb') IS NOT NULL
  DROP TABLE TesteTempdb
GO
CREATE TABLE TesteTempdb (Col1 INT PRIMARY KEY CLUSTERED, Col2 INT, Col3 CHAR(2000)) 
GO
BEGIN TRAN
GO
DECLARE @I INT
SET @I = 1
WHILE @I <= 100000
BEGIN
  INSERT INTO TesteTempdb VALUES (@I, RAND() * 200000, REPLICATE('A', 2000))
  SET @I = @I + 1
END
COMMIT TRAN
GO



SET STATISTICS TIME ON 
GO
-- How much time to run?
-- 32/35 seconds...
DECLARE @Col1 INT, @Col2 INT, @Col3 CHAR(2000)

SELECT @Col1 = Col1, @Col2 = Col2, @Col3 = Col3
  FROM TesteTempdb
 ORDER BY Col2 
OPTION(MAXDOP 1)
GO 5
--Beginning execution loop
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 531 ms,  elapsed time = 17845 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 453 ms,  elapsed time = 18639 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 485 ms,  elapsed time = 17464 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 500 ms,  elapsed time = 19469 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 547 ms,  elapsed time = 22873 ms.
--Batch execution completed 5 times.


SELECT (17845 + 18639 + 17464 + 19469 + 22873) / 5. -- Média... 19s


-- What if we add more files? 

USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'D:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'D:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'D:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'D:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'D:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'D:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'D:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO

USE Northwind
GO

SET STATISTICS TIME ON 
GO
-- How much time to run?
DECLARE @Col1 INT, @Col2 INT, @Col3 CHAR(2000)

SELECT @Col1 = Col1, @Col2 = Col2, @Col3 = Col3
  FROM TesteTempdb
 ORDER BY Col2 
OPTION(MAXDOP 1)
GO 5
--Beginning execution loop
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 703 ms,  elapsed time = 7533 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 812 ms,  elapsed time = 8428 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 735 ms,  elapsed time = 8222 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 640 ms,  elapsed time = 7951 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 516 ms,  elapsed time = 8119 ms.
--Batch execution completed 5 times.


-- Avg
SELECT (36792 + 37122 + 36767 + 36840 + 44077) / 5. -- Avg... 38s
GO



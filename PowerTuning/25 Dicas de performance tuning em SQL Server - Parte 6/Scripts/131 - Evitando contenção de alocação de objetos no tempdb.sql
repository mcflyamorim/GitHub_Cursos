-- SET TEMPDB on SSD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'C:\DBs\datatempdbSQL2019.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'C:\DBs\datatemplogSQL2019.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


USE Northwind
GO

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
-- 50 threads 30 iterations...

SELECT * FROM sys.dm_os_waiting_tasks
where session_id > 50
GO

sp_WhoIsActive
GO


-- https://support.microsoft.com/en-us/help/2154845/recommendations-to-reduce-allocation-contention-in-sql-server-tempdb-d
-- If you have one data file for the tempdb, you only have one GAM page, 
-- and one SGAM page for each 4 GB of space.


-- Tive que criar 18 arquivos para acabar com a contenção...
-- Adicionar novos arquivos...

USE tempdb
GO
DBCC SHRINKFILE('tempdev2', EMPTYFILE)
DBCC SHRINKFILE('tempdev3', EMPTYFILE)
DBCC SHRINKFILE('tempdev4', EMPTYFILE)
DBCC SHRINKFILE('tempdev5', EMPTYFILE)
DBCC SHRINKFILE('tempdev6', EMPTYFILE)
DBCC SHRINKFILE('tempdev7', EMPTYFILE)
DBCC SHRINKFILE('tempdev8', EMPTYFILE)
DBCC SHRINKFILE('tempdev9', EMPTYFILE)
DBCC SHRINKFILE('tempdev10', EMPTYFILE)
DBCC SHRINKFILE('tempdev11', EMPTYFILE)
DBCC SHRINKFILE('tempdev12', EMPTYFILE)
DBCC SHRINKFILE('tempdev13', EMPTYFILE)
DBCC SHRINKFILE('tempdev14', EMPTYFILE)
DBCC SHRINKFILE('tempdev15', EMPTYFILE)
DBCC SHRINKFILE('tempdev16', EMPTYFILE)
DBCC SHRINKFILE('tempdev17', EMPTYFILE)
DBCC SHRINKFILE('tempdev18', EMPTYFILE)
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
ALTER DATABASE tempdb REMOVE FILE tempdev9;
ALTER DATABASE tempdb REMOVE FILE tempdev10;
ALTER DATABASE tempdb REMOVE FILE tempdev11;
ALTER DATABASE tempdb REMOVE FILE tempdev12;
ALTER DATABASE tempdb REMOVE FILE tempdev13;
ALTER DATABASE tempdb REMOVE FILE tempdev14;
ALTER DATABASE tempdb REMOVE FILE tempdev15;
ALTER DATABASE tempdb REMOVE FILE tempdev16;
ALTER DATABASE tempdb REMOVE FILE tempdev17;
ALTER DATABASE tempdb REMOVE FILE tempdev18;
GO

USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'C:\DBs\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'C:\DBs\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'C:\DBs\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'C:\DBs\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'C:\DBs\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'C:\DBs\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'C:\DBs\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev9', FILENAME =  N'C:\DBs\tempdev9.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev10', FILENAME = N'C:\DBs\tempdev10.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev11', FILENAME = N'C:\DBs\tempdev11.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev12', FILENAME = N'C:\DBs\tempdev12.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev13', FILENAME = N'C:\DBs\tempdev13.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev14', FILENAME = N'C:\DBs\tempdev14.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev15', FILENAME = N'C:\DBs\tempdev15.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev16', FILENAME = N'C:\DBs\tempdev16.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev17', FILENAME = N'C:\DBs\tempdev17.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev18', FILENAME = N'C:\DBs\tempdev18.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO

EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO
/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE [master]; 
GO 
alter database tempdb modify file (name='tempdev', size = 1GB, FILEGROWTH = 25MB);
GO



-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'D:\temp\datatempdbSQL2016.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'D:\temp\datatemplogSQL2016.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2016 && net start MSSQL$SQL2016'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO



/* Adding additional file */

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
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'D:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'D:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'D:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME = N'D:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME = N'D:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME = N'D:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME = N'D:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO

EXEC xp_cmdShell 'net stop MSSQL$SQL2016 && net start MSSQL$SQL2016'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO



-- SET TEMPDB on SSD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'E:\tempdbSQL2016.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'E:\tempdblogSQL2016.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2016 && net start MSSQL$SQL2016'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO

/* Adding additional file */

USE tempdb
GO
DBCC SHRINKFILE('tempdev2', EMPTYFILE)
GO
USE master
GO
ALTER DATABASE tempdb REMOVE FILE tempdev2;
GO

USE [master];
GO
-- ADD another file on F: drive
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'C:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2016 && net start MSSQL$SQL2016'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO



-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
-- To update the currently configured value for advanced options.
RECONFIGURE;
GO
-- To enable the feature.
EXEC sp_configure 'xp_cmdshell', 1;
GO
-- To update the currently configured value for this feature.
RECONFIGURE;
GO

SELECT * FROM sys.dm_os_waiting_tasks
where session_id > 50
GO

sp_WhoIsActive
GO


-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'D:\temp\datatempdbSQL2017.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'D:\temp\datatemplogSQL2017.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


-- Tive que criar 18 arquivos para acabar com a contenção...
-- Adicionar novos arquivos...
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'D:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'D:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'D:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'D:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'D:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'D:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'D:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev9', FILENAME =  N'D:\temp\tempdev9.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev10', FILENAME = N'D:\temp\tempdev10.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev11', FILENAME = N'D:\temp\tempdev11.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev12', FILENAME = N'D:\temp\tempdev12.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev13', FILENAME = N'D:\temp\tempdev13.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev14', FILENAME = N'D:\temp\tempdev14.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev15', FILENAME = N'D:\temp\tempdev15.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev16', FILENAME = N'D:\temp\tempdev16.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev17', FILENAME = N'D:\temp\tempdev17.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev18', FILENAME = N'D:\temp\tempdev18.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO



USE tempdb
GO
DBCC SHRINKFILE('tempdev2', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev3', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev4', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev5', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev6', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev7', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev8', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev9', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev10', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev11', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev12', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev13', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev14', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev15', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev16', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev17', EMPTYFILE)
GO
DBCC SHRINKFILE('tempdev18', EMPTYFILE)
GO

USE master
GO
ALTER DATABASE tempdb REMOVE FILE tempdev2;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev3;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev4;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev5;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev6;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev7;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev8;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev9;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev10;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev11;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev12;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev13;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev14;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev15;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev16;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev17;
GO
ALTER DATABASE tempdb REMOVE FILE tempdev18;
GO

EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


-- SET TEMPDB on SSD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'E:\temp\datatempdbSQL2017.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'E:\temp\datatemplogSQL2017.ldf')
GO
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'E:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'E:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'E:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'E:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'E:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'E:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'E:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev9', FILENAME =  N'E:\temp\tempdev9.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev10', FILENAME = N'E:\temp\tempdev10.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev11', FILENAME = N'E:\temp\tempdev11.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev12', FILENAME = N'E:\temp\tempdev12.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev13', FILENAME = N'E:\temp\tempdev13.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev14', FILENAME = N'E:\temp\tempdev14.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev15', FILENAME = N'E:\temp\tempdev15.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev16', FILENAME = N'E:\temp\tempdev16.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev17', FILENAME = N'E:\temp\tempdev17.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev18', FILENAME = N'E:\temp\tempdev18.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO

EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO

-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'F:\Temp\Data_Tempdb_SQL2017.mdf', SIZE = 1048576KB , FILEGROWTH = 1048576KB)
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'F:\Temp\Log_Tempdb_SQL2017.ldf', SIZE = 1048576KB , FILEGROWTH = 1048576KB)
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


USE Northwind
GO
-- 6 segundos para rodar...
IF OBJECT_ID('TesteTempdb') IS NOT NULL
  DROP TABLE TesteTempdb
GO
CREATE TABLE TesteTempdb (Col1 INT PRIMARY KEY CLUSTERED, Col2 INT, Col3 CHAR(2000)) 
GO
BEGIN TRAN
GO
DECLARE @I INT
SET @I = 1
WHILE @I <= 300000
BEGIN
  INSERT INTO TesteTempdb VALUES (@I, RAND() * 200000, REPLICATE('A', 2000))
  SET @I = @I + 1
END
COMMIT TRAN
GO



USE Northwind
GO
SELECT COUNT(*) FROM TesteTempdb
GO
SET STATISTICS TIME ON 
GO
-- Quanto tempo demora pra rodar?
DECLARE @Col1 INT, @Col2 INT, @Col3 CHAR(2000)

SELECT @Col1 = Col1, @Col2 = Col2, @Col3 = Col3
  FROM TesteTempdb
 ORDER BY Col2 
OPTION(MAXDOP 1)
GO
--1:43

-- Criar vários arquivos...
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME =  N'F:\temp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME =  N'F:\temp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME =  N'F:\temp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME =  N'F:\temp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME =  N'F:\temp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME =  N'F:\temp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME =  N'F:\temp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev9', FILENAME =  N'F:\temp\tempdev9.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev10', FILENAME = N'F:\temp\tempdev10.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev11', FILENAME = N'F:\temp\tempdev11.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev12', FILENAME = N'F:\temp\tempdev12.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev13', FILENAME = N'F:\temp\tempdev13.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev14', FILENAME = N'F:\temp\tempdev14.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev15', FILENAME = N'F:\temp\tempdev15.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev16', FILENAME = N'F:\temp\tempdev16.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev17', FILENAME = N'F:\temp\tempdev17.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev18', FILENAME = N'F:\temp\tempdev18.ndf' , SIZE = 1GB , FILEGROWTH = 25MB);
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


USE Northwind
GO
SELECT COUNT(*) FROM TesteTempdb
GO
SET STATISTICS TIME ON 
GO
-- Quanto tempo demora pra rodar?
DECLARE @Col1 INT, @Col2 INT, @Col3 CHAR(2000)

SELECT @Col1 = Col1, @Col2 = Col2, @Col3 = Col3
  FROM TesteTempdb
 ORDER BY Col2 
OPTION(MAXDOP 1)
GO

-- Cleanup

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


-- Rodar query novamente... e agora, como ficou o tempo? 
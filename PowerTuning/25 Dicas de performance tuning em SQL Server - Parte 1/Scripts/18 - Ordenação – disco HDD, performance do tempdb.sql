-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'F:\Temp\Data_Tempdb_SQL2017.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'F:\Temp\Log_Tempdb_SQL2017.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO

-- Restart SQL Service


USE Northwind
GO
IF OBJECT_ID('TesteTempdb') IS NOT NULL
  DROP TABLE TesteTempdb
GO
CREATE TABLE TesteTempdb (Col1 INT PRIMARY KEY CLUSTERED, Col2 INT, Col3 CHAR(2000)) 
GO
BEGIN TRAN
GO
DECLARE @I INT
SET @I = 1
WHILE @I <= 10000
BEGIN
  INSERT INTO TesteTempdb VALUES (@I, RAND() * 200000, REPLICATE('A', 2000))
  SET @I = @I + 1
END
COMMIT TRAN
GO

USE Northwind
GO

DECLARE @Col1 INT, @Col2 INT, @Col3 CHAR(2000)

SELECT @Col1 = Col1, @Col2 = Col2, @Col3 = Col3
  FROM TesteTempdb
 ORDER BY Col2 
OPTION(MAXDOP 1, MIN_GRANT_PERCENT = 100)
GO

SET STATISTICS TIME ON 
GO
-- Quanto tempo demora pra rodar?
-- 14/15 segundos pra rodar...
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
--   CPU time = 78 ms,  elapsed time = 1913 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 109 ms,  elapsed time = 2303 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 109 ms,  elapsed time = 2285 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 110 ms,  elapsed time = 2300 ms.
--SQL Server parse and compile time: 
--   CPU time = 0 ms, elapsed time = 0 ms.

-- SQL Server Execution Times:
--   CPU time = 140 ms,  elapsed time = 2177 ms.
--Batch execution completed 5 times.

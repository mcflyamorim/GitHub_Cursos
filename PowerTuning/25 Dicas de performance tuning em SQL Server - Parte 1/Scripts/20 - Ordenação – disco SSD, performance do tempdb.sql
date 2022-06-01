USE Northwind
GO

-- Create 1 million rows test table
-- 3 secs to run
IF OBJECT_ID('ProductsBig') IS NOT NULL
BEGIN
  DROP TABLE ProductsBig
END
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
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL
GO
SET STATISTICS TIME ON
GO


-- SET TEMPDB on SSD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'C:\temp\Data_Tempdb_SQL2017.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'C:\temp\Log_Tempdb_SQL2017.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


USE Northwind
GO

-- Test query...
SELECT *
  FROM Northwind.dbo.ProductsBig
 WHERE ProductID BETWEEN 1 AND 2500
 ORDER BY ColTest
GO

-- Como ficam as escritas em um SSD? ...  SSD apenas 1 arquivo de dados...


-- Rodar no SQL Query Stress
-- 20 threads 2 iterations 
-- 1 arquivo = 4/5 segundos...





SELECT * FROM sys.dm_os_waiting_tasks
where session_id > 50
GO

sp_WhoIsActive
GO


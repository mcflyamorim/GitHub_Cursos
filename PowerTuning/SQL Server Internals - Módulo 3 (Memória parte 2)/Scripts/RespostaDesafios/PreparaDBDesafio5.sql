USE master
GO
if exists (select * from sysdatabases where name='Desafio5')
BEGIN
  ALTER DATABASE Desafio5 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Desafio5
END 
GO
DECLARE @device_directory VarChar(520)
SELECT @device_directory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1
EXECUTE (N'CREATE DATABASE Desafio5
  ON PRIMARY (NAME = N''Desafio5'', FILENAME = N''' + @device_directory + N'Desafio5.mdf'')
  LOG ON (NAME = N''Desafio5_log'',  FILENAME = N''' + @device_directory + N'Desafio5.ldf'')')
GO

ALTER DATABASE Desafio5 SET RECOVERY SIMPLE
GO

USE Desafio5
GO

-- 1 minute to run...
-- Creating a 200000 rows table...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 10000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(5000), NEWID()) AS Col2
  INTO ProductsBig
  FROM Northwind.dbo.Products A
 CROSS JOIN Northwind.dbo.Products B
 CROSS JOIN Northwind.dbo.Products C
 CROSS JOIN Northwind.dbo.Products D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO

-- 81288 KB
sp_spaceused ProductsBig
GO



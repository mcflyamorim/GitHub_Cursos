/*

  Demo "A significant part of sql server process memory has been paged out. This may result in performance degradation."...



*/


--1 - Subir a VMWin2012


--2 - Conectar no VMWin2012\SQL2017


--3 - Criar os DBs para teste

-- Set BP to 4GB
CHECKPOINT; DBCC DROPCLEANBUFFERS();
GO
EXEC sys.sp_configure N'show advanced options', N'1';  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'min server memory (MB)', N'0'
GO
EXEC sys.sp_configure N'max server memory (MB)', N'4086' -- 4GB
GO
RECONFIGURE WITH OVERRIDE
GO

USE master
GO
if exists (select * from sysdatabases where name='DB_MemoryTest')
		drop database DB_MemoryTest
GO
CREATE DATABASE [DB_MemoryTest] ON  PRIMARY 
( NAME = N'DB_MemoryTest', FILENAME = N'C:\Temp\DB_MemoryTest.mdf' , SIZE = 1048576KB , FILEGROWTH = 1048576KB )
 LOG ON 
( NAME = N'DB_MemoryTest_log', FILENAME = N'C:\Temp\DB_MemoryTest_log.ldf' , SIZE = 1024KB , FILEGROWTH = 1048576KB )
GO
USE DB_MemoryTest
GO

-- 10 minutos para rodar
IF OBJECT_ID('Products1') IS NOT NULL
  DROP TABLE Products1
GO
SELECT TOP 384000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE Products1 ADD CONSTRAINT xpk_Products1 PRIMARY KEY(ProductID)
GO

-- +- 3GB -- SELECT 3077584  /1024.
EXEC sp_spaceused Products1
GO


-- 4 -  Popular BP data cache
-- Physical reads
CHECKPOINT;DBCC DROPCLEANBUFFERS()
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM Products1
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

-- Logical reads?
SET STATISTICS IO ON
SELECT COUNT(*) FROM Products1
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

-- Chamar "\\VMWin2012\c$\Temp\TestLimit\testlimit64.exe -d 6144 -c 1" para alocar 6GB de memória... 

-- Logical reads?
SET STATISTICS IO ON
SELECT COUNT(*) FROM Products1
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

-- Se for physical, é pq os dados foram removidos da memória... 
---- e se eu setar um min server memory pra 4GB ? 
-- Rodar denovo... 
EXEC sys.sp_configure N'min server memory (MB)', N'4086' -- 4GB
GO

-- Se foi logical reads, pq demorou tanto pra rodar a query? ... 


-- Alguma dica no errorlog? 
EXEC sp_readerrorlog 0, 1, 1


-- E o lock pages in memory? pode ajudar? ... 
---- Bom em teoria sim... vamos fazer o teste...
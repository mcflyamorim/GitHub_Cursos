
USE master
GO
DROP DATABASE IF EXISTS [TestDRAM]
GO
CREATE DATABASE [TestDRAM]
 ON  PRIMARY 
( NAME = N'TestDRAM', FILENAME = N'E:\Temp\TestDRAM.mdf' , SIZE = 512000KB, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'TestDRAM_log', FILENAME = N'E:\Temp\TestDRAM_log.ldf' , SIZE = 1024KB  , FILEGROWTH = 65536KB )
GO

USE TestDRAM
GO
-- Criar tablea com 18 milhoes de linhas para efetuar os testes
IF OBJECT_ID('OrdersBig_v1') IS NOT NULL
  DROP TABLE OrdersBig_v1
GO
SELECT TOP 18000000
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig_v1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
GO

sp_spaceused OrdersBig_v1 -- 446 MB
GO

DBCC DROPCLEANBUFFERS;
SELECT COUNT(*) FROM OrdersBig_v1
OPTION (MAXDOP 12)
GO

-- Testar no SQLQueryStress com 50 threads e 2 iterations... 
-- Ver perfmon counters


-- Pra efeito de comparação...
-- Como ficaria em um super SSD? 
USE master
GO
DROP DATABASE IF EXISTS [TestSSD]
GO
CREATE DATABASE [TestSSD]
 ON  PRIMARY 
( NAME = N'TestSSD', FILENAME = N'C:\Temp\TestSSD.mdf' , SIZE = 512000KB, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'TestSSD_log', FILENAME = N'C:\Temp\TestSSD_log.ldf' , SIZE = 1024KB  , FILEGROWTH = 65536KB )
GO

USE TestSSD
GO
-- Criar tablea com 18 milhoes de linhas para efetuar os testes
IF OBJECT_ID('OrdersBig_v1') IS NOT NULL
  DROP TABLE OrdersBig_v1
GO
SELECT TOP 18000000
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig_v1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
GO

sp_spaceused OrdersBig_v1 -- 446 MB
GO

DBCC DROPCLEANBUFFERS;
SELECT COUNT(*) FROM OrdersBig_v1
OPTION (MAXDOP 12)
GO

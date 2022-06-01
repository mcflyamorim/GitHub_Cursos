/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE master
GO
ALTER DATABASE [TestSSIS_D_Drive] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [TestSSIS_D_Drive]
GO

CREATE DATABASE [TestSSIS_D_Drive]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TestSSIS_D_Drive', FILENAME = N'd:\DBs\TestSSIS_D_Drive.mdf' , SIZE = 10485760KB , FILEGROWTH = 1048576KB )
 LOG ON 
( NAME = N'TestSSIS_D_Drive_log', FILENAME = N'd:\DBs\TestSSIS_D_Drive_log.ldf' , SIZE = 5283840KB , FILEGROWTH = 1048576KB )
GO


USE TestSSIS_D_Drive
GO

IF OBJECT_ID('OrdersBig_SSIS') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig_SSIS
END
GO
SELECT TOP 0 
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig_SSIS
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
GO

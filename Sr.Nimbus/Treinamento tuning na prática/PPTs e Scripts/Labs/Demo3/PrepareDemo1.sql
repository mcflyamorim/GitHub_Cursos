/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/
USE [master]
ALTER DATABASE [Northwind] SET AUTO_CREATE_STATISTICS ON

USE Northwind

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;

RECONFIGURE;
-- set the max server memory to 4GB
EXEC sp_configure 'max server memory', 4096
RECONFIGURE


IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig

SELECT TOP 3000000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(MAX), REPLICATE('ASD', 5)) AS Col1, 
       CONVERT(VarChar(MAX), REPLICATE('ASD', 5)) AS Col2,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS Col3, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS Col4, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS Col5, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS Col6
  INTO CustomersBig
  FROM Northwind.dbo.Customers A
 CROSS JOIN Northwind.dbo.Customers B
 CROSS JOIN Northwind.dbo.Customers C
 CROSS JOIN Northwind.dbo.Customers D

ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
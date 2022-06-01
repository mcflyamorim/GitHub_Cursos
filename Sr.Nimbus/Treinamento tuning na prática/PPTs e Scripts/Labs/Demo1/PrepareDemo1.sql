/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/
USE [master]
ALTER DATABASE [Northwind] SET AUTO_CREATE_STATISTICS OFF

USE Northwind

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;

RECONFIGURE;
-- set the max server memory to 2GB
EXEC sp_configure 'max server memory', 2048
RECONFIGURE

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig

CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL,
 [Col1] VarCHAR(200)
) ON [PRIMARY]

INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value, Col1) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VARCHAR(MAX), 'SomeFixedShit') AS Col1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig

SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(MAX), REPLICATE('ASD', 5)) AS Col1, 
       CONVERT(VarChar(MAX), REPLICATE('ASD', 5)) AS Col2
  INTO CustomersBig
  FROM Northwind.dbo.Customers A
 CROSS JOIN Northwind.dbo.Customers B
 CROSS JOIN Northwind.dbo.Customers C
 CROSS JOIN Northwind.dbo.Customers D

ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)

SELECT CustomersBig.ContactName, CustomersBig.Col1, CustomersBig.Col2, OrdersBig.Col1, SUM(OrdersBig.Value) FROM dbo.OrdersBig INNER JOIN dbo.CustomersBig ON CustomersBig.CustomerID = OrdersBig.CustomerID GROUP BY CustomersBig.ContactName, CustomersBig.Col1, CustomersBig.Col2, OrdersBig.Col1 
ORDER BY CustomersBig.ContactName DESC OPTION (MAXDOP 1)


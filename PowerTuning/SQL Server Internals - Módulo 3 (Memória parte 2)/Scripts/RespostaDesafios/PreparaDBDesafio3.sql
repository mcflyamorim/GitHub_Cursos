USE master
GO
if exists (select * from sysdatabases where name='Desafio3')
BEGIN
  ALTER DATABASE Desafio3 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Desafio3
END 
GO
DECLARE @device_directory VarChar(520)
SELECT @device_directory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1
EXECUTE (N'CREATE DATABASE Desafio3
  ON PRIMARY (NAME = N''Desafio3'', FILENAME = N''' + @device_directory + N'Desafio3.mdf'')
  LOG ON (NAME = N''Desafio3_log'',  FILENAME = N''' + @device_directory + N'Desafio3.ldf'')')
GO

ALTER DATABASE Desafio3 SET RECOVERY SIMPLE
ALTER DATABASE Desafio3 SET AUTO_UPDATE_STATISTICS OFF
GO

USE Desafio3
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL,
 [Col1] VarCHAR(250),
 [Col2] VarCHAR(250),
 [Col3] VarCHAR(250),
 [Col4] VarCHAR(250),
 [Col5] VarCHAR(250),
 [Col6] VarCHAR(250),
 [Col7] VarCHAR(250),
 [Col8] VarCHAR(250),
) ON [PRIMARY]

INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value, Col1, Col2, Col3, Col4, Col5, Col6, Col7, Col8) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000000.5))),0) AS Value,
       CONVERT(TEXT, 'SomeFixedShit') AS Col1,
       CONVERT(VARCHAR(250), NEWID()) AS Col2,
       CONVERT(VARCHAR(250), NEWID()) AS Col3,
       CONVERT(VARCHAR(250), NEWID()) AS Col4,
       CONVERT(VARCHAR(250), NEWID()) AS Col5,
       CONVERT(VARCHAR(250), NEWID()) AS Col6,
       CONVERT(VARCHAR(250), NEWID()) AS Col7,
       CONVERT(VARCHAR(250), NEWID()) AS Col8
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixValue ON OrdersBig (Value) INCLUDE(OrderDate, Col1)
GO

-- All values are ver likely to be > than 100
UPDATE [OrdersBig] SET Value = ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0)
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), REPLICATE('ASD', 5)) AS Col1, 
       CONVERT(VarChar(250), REPLICATE('ASD', 5)) AS Col2
  INTO CustomersBig
  FROM Northwind.dbo.Customers A
 CROSS JOIN Northwind.dbo.Customers B
 CROSS JOIN Northwind.dbo.Customers C
 CROSS JOIN Northwind.dbo.Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID) 
GO


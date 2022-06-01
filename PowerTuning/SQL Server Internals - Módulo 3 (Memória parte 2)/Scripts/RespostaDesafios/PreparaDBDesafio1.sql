USE master
GO
if exists (select * from sysdatabases where name='Desafio1')
BEGIN
  ALTER DATABASE Desafio1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Desafio1
END 
GO
DECLARE @device_directory VarChar(520)
SELECT @device_directory = SUBSTRING(filename, 1, CHARINDEX(N'master.mdf', LOWER(filename)) - 1)
FROM master.dbo.sysaltfiles WHERE dbid = 1 AND fileid = 1
EXECUTE (N'CREATE DATABASE Desafio1
  ON PRIMARY (NAME = N''Desafio1'', FILENAME = N''' + @device_directory + N'Desafio1.mdf'')
  LOG ON (NAME = N''Desafio1_log'',  FILENAME = N''' + @device_directory + N'Desafio1.ldf'')')
GO

ALTER DATABASE Desafio1 SET RECOVERY SIMPLE
GO

USE Desafio1
GO


CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL,
 [Col1] CHAR(200)
) ON [PRIMARY]

INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value, Col1) 
SELECT TOP 3000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VARCHAR(500), NEWID()) AS Col1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

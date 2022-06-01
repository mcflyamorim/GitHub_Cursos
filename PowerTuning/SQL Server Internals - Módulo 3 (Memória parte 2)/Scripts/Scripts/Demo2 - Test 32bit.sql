/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

/*
   RODAR NO razerfabiano\sql2008R2_2
   RODAR NO razerfabiano\sql2008R2_2
   RODAR NO razerfabiano\sql2008R2_2
   RODAR NO razerfabiano\sql2008R2_2
*/

USE Northwind
GO

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 10GB
EXEC sp_configure 'max server memory', 10240
RECONFIGURE
GO

-- 1 minute to run
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 20000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- So, max server memory is 10GB
-- Workspace memory grant is 7.5GB, correct? 75% of it?
-- Query memory can go up to 1.8GB (25% of workspace), correct?

-- Granted memory = 631584
-- Ideal/Desired memory = 1075320
DECLARE @i Int
SELECT @i = OrderID 
  FROM OrdersBig
 ORDER BY Value DESC
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Why granted memory is only 616?
-- Don't it has 1.8GB available?
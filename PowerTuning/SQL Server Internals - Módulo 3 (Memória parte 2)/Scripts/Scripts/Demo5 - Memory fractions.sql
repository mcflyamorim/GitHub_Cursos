/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
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


IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL,
 Col1 VARCHAR(500) NOT NULL DEFAULT NEWID()
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 100000
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

IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
  DROP TABLE CustomersBig
END
GO
SELECT TOP 100000 
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Check memory fractions on actual plan
-- Granted +- 28MB
-- Max used +- 22MB ... 
-- What? 
-- Sort is spilling... 
DECLARE @i INT = 999999999, @y INT = 999999999
SELECT TOP 1000 * 
  FROM OrdersBig
 INNER HASH JOIN CustomersBig
   ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.CustomerID <= @i
   AND OrdersBig.OrderID <= @y
 ORDER BY OrdersBig.Col1 DESC
OPTION (OPTIMIZE FOR (@i = 18000, @y = 19000))
GO


DECLARE @i INT = 999999999, @y INT = 999999999
SELECT TOP 1000 * 
  FROM OrdersBig
 INNER HASH JOIN CustomersBig
   ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.CustomerID <= @i
   AND OrdersBig.OrderID <= @y
 ORDER BY OrdersBig.Col1 DESC
OPTION (OPTIMIZE FOR (@i = 18000, @y = 19000), MIN_GRANT_PERCENT = 5)
GO
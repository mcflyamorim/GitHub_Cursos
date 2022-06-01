/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE NorthWind
GO

-- Create 10 million rows test table
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
SELECT TOP 10000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
CREATE INDEX ixCustomerID ON OrdersBig (CustomerID) 
GO
-- Create 1000 rows test table
IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
  DROP TABLE CustomersBig
END
GO
SELECT TOP 10000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2,
       1 AS NewCol
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO

IF OBJECT_ID('fn_ReturnDate', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_ReturnDate
GO
CREATE FUNCTION dbo.fn_ReturnDate()
RETURNS Date
AS
BEGIN
  DECLARE @Var1 VARCHAR(200)
  DECLARE @i INT = 0
  WHILE @i <= 20
  BEGIN
    SET @Var1 = CHECKSUM(REVERSE(REPLICATE(CONVERT(VARCHAR(200), 'Fabiano Neves Amorim' + CONVERT(VARCHAR(10), @i)), 500)))
    SET @i += 1
  END
  RETURN CONVERT(Date, GetDate())
END
GO


-- Check CPU usage on profiler...
-- function executed for each probed row...
-- Hash join
SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
  WHERE DATEADD(d, CustomersBig.NewCol, OrdersBig.OrderDate) < dbo.fn_ReturnDate()
OPTION (RECOMPILE)
GO

-- What if I give it a covered and ordered index? 

-- Including OrderDate
CREATE INDEX ixCustomerID ON OrdersBig (CustomerID) INCLUDE(OrderDate)
WITH(DROP_EXISTING=ON)
GO

-- Where is the function? ... 
-- Merge join
SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
  WHERE DATEADD(d, CustomersBig.NewCol, OrdersBig.OrderDate) < dbo.fn_ReturnDate()
OPTION (RECOMPILE)
GO



-- Function executed only once...
-- Be carefull, edge cases results may be different...
DECLARE @dt DATE
SET @dt = dbo.fn_ReturnDate()

SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
  WHERE DATEADD(d, CustomersBig.NewCol, OrdersBig.OrderDate) < @dt
OPTION (RECOMPILE, MAXDOP 1)
GO

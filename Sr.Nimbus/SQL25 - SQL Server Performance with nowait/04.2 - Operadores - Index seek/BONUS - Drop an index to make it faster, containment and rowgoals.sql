USE Northwind
GO
SET STATISTICS IO ON
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 200
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO

IF OBJECT_ID('fn_ReturnCustomersBig') IS NOT NULL
  DROP FUNCTION fn_ReturnCustomersBig
GO
CREATE FUNCTION dbo.fn_ReturnCustomersBig()
RETURNS Int
AS
BEGIN
  DECLARE @ID INT

  ;WITH CTE1
  AS
   (
    SELECT * FROM (VALUES(1, 51)) AS Tab(Val1, Val2)
   )
  SELECT @ID = Val1+ ABS(CHECKSUM(((SELECT NewID FROM vw_NewID)))) % (Val2-Val1)
    FROM CTE1

  RETURN(@ID)
END
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       dbo.fn_ReturnCustomersBig() AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- DROP INDEX "ixCustomerID_OrderDate" ON OrdersBig
CREATE INDEX "ixCustomerID_OrderDate" ON OrdersBig(CustomerID, OrderDate)
GO
-- DROP INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig
CREATE INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig(OrderDate) INCLUDE(CustomerID, Value)
GO



-- How many customers with orders?
SELECT COUNT(DISTINCT CustomerID)
  FROM OrdersBig
GO


-- Nice plan...
-- Read one customer and ask for value on ixCustomerID_OrderDate index...
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate 
                FROM OrdersBig 
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
OPTION (RECOMPILE)
GO

-- What if I say I also want the value column?
-- To use the ixCustomerID_OrderDate index It will require a lookup to grab value from cluster
-- Scan on "ixOrderDate Include(CustomerID, Value)", really ?
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate DESC) AS Tab1
OPTION (RECOMPILE)
GO


-- What if I drop index "ixOrderDate Include(CustomerID, Value)"? 
-- Wait a minute? Say again? 
-- DROP an index to make query faster? 
-- I always heard the other way...
DROP INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig
GO

-- Now I've to pay for the lookup
-- Scary 
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
GO


-- Understanding the problem... 
-- Containment assumption
-- Containment assumes that if you’re looking for something, it actually exists.
-- QO thinks at least one row will be returned from OrdersBig table...
-- Combine this behavior with ROW GOAL "optimization" and we'll have a problem...


-- Creating the index again to compare plans
-- DROP INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig
CREATE INDEX "ixOrderDate Include(CustomerID, Value)" 
ON OrdersBig(OrderDate) INCLUDE(CustomerID, Value)
GO

-- Scan
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
GO

-- Seeek (using forceseek)
-- Here is what QO is thinking: - OMG I'll need to run 200 seeks... OMG...
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig WITH(FORCESEEK)
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
OPTION(RECOMPILE)
GO


-- If you don't want to use FORCESEEK... t-sql workaround
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 o1.OrderDate, o3.Value
                FROM OrdersBig o1
               CROSS APPLY (SELECT Value 
                              FROM OrdersBig o2
                             WHERE o2.OrderID = o1.OrderID) AS o3 -- This is basically a manual KeyLookup
               WHERE o1.CustomerID = CustomersBig.CustomerID
               ORDER BY o1.OrderDate) AS Tab1
OPTION (RECOMPILE)
GO


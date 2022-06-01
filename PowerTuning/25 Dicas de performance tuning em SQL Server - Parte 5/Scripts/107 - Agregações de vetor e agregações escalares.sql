USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
 -- ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
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
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 1000000 AS CustomerID,
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
--  ALTER TABLE [dbo].[OrdersBig] DROP CONSTRAINT [fk_OrdersBig_CustomersBig]
  DROP TABLE CustomersBig
END
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       dbo.fn_ReturnCustomers() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       dbo.fn_ReturnContactName() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
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
SET IDENTITY_INSERT CustomersBig ON
INSERT INTO CustomersBig  (CustomerID, CompanyName, ContactName, Col1, Col2)
VALUES (-1, 'Emp Fabiano', 'Fabiano Amorim', NEWID(), NEWID())
SET IDENTITY_INSERT CustomersBig OFF
GO

CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO




SET STATISTICS TIME ON
SET STATISTICS IO ON

-- Return all customers with less than or equal 400 orders
-- Why this shit plan?
-- Doesn't make more sense to filter first, then join? Why join everything and then filter? 
SELECT CustomersBig.ContactName, CustomersBig.CompanyName
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 GROUP BY CustomersBig.CustomerID,
          CustomersBig.ContactName, 
          CustomersBig.CompanyName
HAVING COUNT_BIG(*) <= 400
OPTION (RECOMPILE, MAXDOP 1)
GO


-- Maybe if I try a different sintax...
-- Ok, now I've got the filter before the join
SELECT CustomersBig.ContactName, 
       CustomersBig.CompanyName 
  FROM (SELECT CustomerID, 
               COUNT_BIG(*) AS Cnt 
          FROM OrdersBig
         GROUP BY CustomerID) AS Tab1 
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = Tab1.CustomerID
 WHERE Tab1.Cnt <= 400
OPTION (RECOMPILE, MAXDOP 1)
GO


-- What if using EXISTS? 
-- Plan is fine, but results are wrong... Why?
SELECT CustomersBig.ContactName, CustomersBig.CompanyName 
  FROM CustomersBig
 WHERE EXISTS(SELECT * 
                FROM OrdersBig
               WHERE CustomersBig.CustomerID = OrdersBig.CustomerID
              HAVING COUNT_BIG(*) <= 400)
OPTION (RECOMPILE, MAXDOP 1)
GO

-- Let's check a customer that has no Order
-- There is no Order for CustomerID = -1, what is the result? 
SELECT COUNT_BIG(*) 
  FROM OrdersBig
 WHERE OrdersBig.CustomerID = -1
GO

-- What now?
SELECT COUNT_BIG(*) 
  FROM OrdersBig
 WHERE OrdersBig.CustomerID = -1
 GROUP BY CustomerID
GO


-- What about this nice and clean GROUP() (require SQL2008+)
SELECT COUNT_BIG(*) 
  FROM OrdersBig
 WHERE OrdersBig.CustomerID = -1
 GROUP BY ()
GO


-- What now? Using GROUP()
-- Correct results and good plan
SELECT CustomersBig.ContactName, CustomersBig.CompanyName 
  FROM CustomersBig
 WHERE EXISTS(SELECT * 
                FROM OrdersBig
               WHERE CustomersBig.CustomerID = OrdersBig.CustomerID
               GROUP BY()
              HAVING COUNT_BIG(*) <= 400)
GO



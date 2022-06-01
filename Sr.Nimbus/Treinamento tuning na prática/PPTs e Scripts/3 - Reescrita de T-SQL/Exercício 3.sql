USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VarChar(250), NEWID()) AS Col1,
       3 AS StatusID
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
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

IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
  DROP TABLE Order_DetailsBig
GO
SELECT OrdersBig.OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000)),0) AS ProductID,
       GetDate() -  ABS(CheckSUM(NEWID())) / 1000000 AS Shipped_Date,
       CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM OrdersBig
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID]) WITH(IGNORE_DUP_KEY=ON)
GO

SET IDENTITY_INSERT Order_DetailsBig ON
INSERT INTO Order_DetailsBig ( OrderID, 
                                ProductID,
                               Shipped_Date,
                               Quantity )
SELECT TOP 10000
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000)),0) * -1,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000)),0) AS ProductID,
       GetDate() -  ABS(CheckSUM(NEWID())) / 1000000 AS Shipped_Date,
       CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000) AS Quantity
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
SET IDENTITY_INSERT Order_DetailsBig OFF
GO 50



CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
SELECT TOP 50000
       OrdersBig.OrderID,       
       OrdersBig.Value,
       CustomersBig.ContactName,
       ISNULL(CASE 
                WHEN OrdersBig.Value < 1 THEN Order_DetailsBig.Quantity
              END, 0) AS Qt
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 LEFT OUTER JOIN Order_DetailsBig
   ON Order_DetailsBig.OrderID = OrdersBig.OrderID
ORDER BY CustomersBig.ContactName
OPTION (MAXDOP 1)
GO

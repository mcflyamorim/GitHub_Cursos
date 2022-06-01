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
       3 AS StatusID
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

IF OBJECT_ID('OrdersToIgnore1') IS NOT NULL
  DROP TABLE OrdersToIgnore1
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(1000), NEWID()) AS Col2
  INTO OrdersToIgnore1
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
ALTER TABLE OrdersToIgnore1 ADD CONSTRAINT xpk_OrdersToIgnore1 PRIMARY KEY(OrderID)
GO
DELETE FROM OrdersToIgnore1
WHERE OrderID >= 1000000
GO
IF OBJECT_ID('OrdersToIgnore2') IS NOT NULL
  DROP TABLE OrdersToIgnore2
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(1), 'a') AS Col2
  INTO OrdersToIgnore2
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
ALTER TABLE OrdersToIgnore2 ADD CONSTRAINT xpk_OrdersToIgnore2 PRIMARY KEY(OrderID)
GO
DELETE FROM OrdersToIgnore2
WHERE OrderID >= 1000000
GO




-- Qual será ordem de acesso as tabelas? 
SELECT * 
  FROM Orders
 INNER JOIN Customers
    ON Customers.CustomerID = Orders.CustomerID
 INNER JOIN Employees
    ON Employees.EmployeeID = Orders.EmployeeID
 INNER JOIN Order_Details
    ON Order_Details.OrderID = Orders.OrderID
 INNER JOIN Products
    ON Products.ProductID = Order_Details.ProductID
GO


-- Qual será ordem de acesso as tabelas? 
SELECT * 
  FROM Orders
 INNER JOIN Customers
    ON Customers.CustomerID = Orders.CustomerID
 INNER JOIN Employees
    ON Employees.EmployeeID = Orders.EmployeeID
 INNER JOIN Order_Details
    ON Order_Details.OrderID = Orders.OrderID
 INNER JOIN Products
    ON Products.ProductID = Order_Details.ProductID
OPTION (FORCE ORDER)
GO



SET STATISTICS IO, TIME ON
GO
SELECT * FROM OrdersBig
LEFT OUTER JOIN OrdersToIgnore1
ON OrdersToIgnore1.OrderID = OrdersBig.OrderID
LEFT OUTER JOIN OrdersToIgnore2
ON OrdersToIgnore2.OrderID = OrdersBig.OrderID
WHERE OrdersToIgnore1.OrderID IS NULL
AND OrdersToIgnore2.OrderID IS NULL
OPTION (RECOMPILE)
GO
SELECT * FROM OrdersBig
LEFT OUTER JOIN OrdersToIgnore2
ON OrdersToIgnore2.OrderID = OrdersBig.OrderID
LEFT OUTER JOIN OrdersToIgnore1
ON OrdersToIgnore1.OrderID = OrdersBig.OrderID
WHERE OrdersToIgnore1.OrderID IS NULL
AND OrdersToIgnore2.OrderID IS NULL
OPTION (RECOMPILE)
GO
SET STATISTICS IO, TIME OFF
GO


-- Pra garantir que a ordem será correta, podemos utilizar o force order...
SELECT * FROM OrdersBig
LEFT OUTER JOIN OrdersToIgnore2
ON OrdersToIgnore2.OrderID = OrdersBig.OrderID
LEFT OUTER JOIN OrdersToIgnore1
ON OrdersToIgnore1.OrderID = OrdersBig.OrderID
WHERE OrdersToIgnore1.OrderID IS NULL
AND OrdersToIgnore2.OrderID IS NULL
OPTION (RECOMPILE, FORCE ORDER)
GO
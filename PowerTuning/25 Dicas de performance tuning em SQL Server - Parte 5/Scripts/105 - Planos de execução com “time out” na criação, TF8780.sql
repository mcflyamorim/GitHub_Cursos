--------------------------------------------------
--------------------------------------------------
----- Nasty TF you don't want to use. Do you? ----
--------------------------------------------------
--------------------------------------------------

---------------------------- WARNING ---------------- READ -----------------------------
---------------------------- WARNING ---------------- READ -----------------------------
----------------------------------------------------------------------------------------
-- PLEASE BEAR IN MIND THAT 8780 TRACE FLAG IS UNDOCUMENTED AND UNSUPPORTED,  ----------
-- AND SHOULD NOT BE USED ON A PRODUCTION ENVIRONMENT. ---------------------------------
-- YOU CAN USE THEM AS A WAY TO EXPLORE AND UNDERSTAND HOW THE QUERY OPTIMIZER WORKS. --
----------------------------------------------------------------------------------------
---------------------------- WARNING ---------------- READ -----------------------------
---------------------------- WARNING ---------------- READ -----------------------------





-- TF 8780 -- Disable optimization timeout
-- 12 segundos
USE Northwind
GO
IF OBJECT_ID('OrdersBigTimeOut') IS NOT NULL
  DROP TABLE OrdersBigTimeOut
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBigTimeOut
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBigTimeOut ADD CONSTRAINT xpk_OrdersBigTimeOut PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBigTimeOut') IS NOT NULL
  DROP TABLE CustomersBigTimeOut
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBigTimeOut
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBigTimeOut ADD CONSTRAINT xpk_CustomersBigTimeOut PRIMARY KEY(CustomerID)
GO
IF OBJECT_ID('ProductsBigTimeOut') IS NOT NULL
  DROP TABLE ProductsBigTimeOut
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBigTimeOut
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
UPDATE ProductsBigTimeOut SET ProductName = 'Some Product'
WHERE ProductID = 1
GO
ALTER TABLE ProductsBigTimeOut ADD CONSTRAINT xpk_ProductsBigTimeOut PRIMARY KEY(ProductID)
GO
IF OBJECT_ID('Order_DetailsBigTimeOut') IS NOT NULL
  DROP TABLE Order_DetailsBigTimeOut
GO
SELECT OrdersBigTimeOut.OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000)),0) AS ProductID,
       GetDate() -  ABS(CheckSUM(NEWID())) / 1000000 AS Shipped_Date,
       CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBigTimeOut
  FROM OrdersBigTimeOut
GO
ALTER TABLE Order_DetailsBigTimeOut ADD CONSTRAINT [xpk_Order_DetailsBigTimeOut] PRIMARY KEY([OrderID], [ProductID])
GO
CREATE INDEX ixContactName ON CustomersBigTimeOut(ContactName) -- index on WHERE
CREATE INDEX ixProductName ON ProductsBigTimeOut(ProductName) -- index on WHERE
CREATE INDEX ixCustomerID ON OrdersBigTimeOut(CustomerID) INCLUDE(Value) -- index on FK
CREATE INDEX ixProductID ON Order_DetailsBigTimeOut(ProductID) INCLUDE(Quantity) -- index on FK
GO

INSERT INTO CustomersBigTimeOut (CompanyName, ContactName, Col1, Col2)
VALUES ('Emp Fabiano', 'Fabiano Amorim', NEWID(), NEWID())

INSERT INTO OrdersBigTimeOut (CustomerID, OrderDate, Value)
VALUES(SCOPE_IDENTITY(), GetDate(), 999)
SET IDENTITY_INSERT Order_DetailsBigTimeOut ON
INSERT INTO Order_DetailsBigTimeOut(OrderID, ProductID, Shipped_Date, Quantity)
VALUES (SCOPE_IDENTITY(), 1, GetDate() + 30, 999)
SET IDENTITY_INSERT Order_DetailsBigTimeOut OFF
GO

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

IF OBJECT_ID('st_ProcTF8780') IS NOT NULL DROP PROC st_ProcTF8780
GO
CREATE PROCEDURE st_ProcTF8780 @ContactName VarChar(200), @ProductName VarChar(200)
AS
SELECT OrdersBigTimeOut.OrderID, 
       OrdersBigTimeOut.Value,
       Order_DetailsBigTimeOut.Quantity,
       CustomersBigTimeOut.ContactName,
       ProductsBigTimeOut.ProductName
  FROM OrdersBigTimeOut
 INNER JOIN CustomersBigTimeOut
    ON OrdersBigTimeOut.CustomerID = CustomersBigTimeOut.CustomerID
 INNER JOIN Order_DetailsBigTimeOut
    ON OrdersBigTimeOut.OrderID = Order_DetailsBigTimeOut.OrderID
 INNER JOIN ProductsBigTimeOut
    ON Order_DetailsBigTimeOut.ProductID = ProductsBigTimeOut.ProductID
 INNER JOIN OrdersBigTimeOut AS OrdersBigTimeOut2
    ON OrdersBigTimeOut2.OrderID = OrdersBigTimeOut.Value
  LEFT OUTER JOIN ProductsBigTimeOut AS ProductsBigTimeOut2
    ON ProductsBigTimeOut2.ProductName = ProductsBigTimeOut.Col1
 WHERE CustomersBigTimeOut.ContactName = @ContactName
   AND ProductsBigTimeOut.ProductName = @ProductName
GO


DBCC TRACEOFF(8780); CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache" 
GO
-- Running proc without TF 8780
EXEC st_ProcTF8780 @ContactName = 'Fabiano Amorim', @ProductName = 'Some Product'
GO


DBCC TRACEON(8780); CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache"
GO
-- Running proc with TF 8780
EXEC st_ProcTF8780 @ContactName = 'Fabiano Amorim', @ProductName = 'Some Product'
GO
DBCC TRACEOFF(8780);
GO


------------ Bonus -------------------
-- Compile to INFINIT? ... Nope... 
-- *** Optimizer time out abort at task 3072000 *** --


-- 10 seconds to run... 
-- Check query plan... 9 secs to compile...
DECLARE @i Int
;WITH cte AS
(
  SELECT Orders.* 
    FROM Orders 
   INNER JOIN Customers 
      ON Customers.CustomerID = Orders.CustomerID
   WHERE dbo.Orders.Value > 100
)
SELECT TOP 10000000 @i = Cte7.Value 
  FROM Orders
    join cte on Orders.Value = cte.Value 
    join cte cte2 on Orders.ShipVia = cte2.ShipVia 
    join cte cte3 on Orders.ShipVia = cte3.ShipVia
    join cte cte4 on Orders.ShipVia = cte4.ShipVia  
    join cte cte5 on Orders.ShipVia = cte5.ShipVia
    join cte cte6 on Orders.ShipVia = cte6.ShipVia
    join cte cte7 on Orders.ShipVia = cte7.ShipVia  
OPTION
(
    RECOMPILE
    , QUERYTRACEON 3604
    , QUERYTRACEON 8675 -- Show stages optimization
    , QUERYTRACEON 8780 -- Disable timeout...
)
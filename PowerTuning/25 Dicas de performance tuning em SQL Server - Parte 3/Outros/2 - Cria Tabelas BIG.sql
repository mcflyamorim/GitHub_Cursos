/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
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
  ALTER TABLE [dbo].[OrdersBig] DROP CONSTRAINT [fk_OrdersBig_CustomersBig]
  DROP TABLE CustomersBig
END
GO
SELECT TOP 1000000 
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


ALTER TABLE CustomersBig ADD CNPJ VarChar(18)
GO
UPDATE CustomersBig SET CNPJ = LEFT(CONVERT(VarChar(80), ABS(CHECKSUM(NEWID()))) + '00000000000000', 14)
GO

UPDATE TOP (30) PERCENT CustomersBig SET CityID = NULL
GO

IF OBJECT_ID('ProductsBig') IS NOT NULL
BEGIN
  DROP TABLE ProductsBig
END
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS ProductID, 
       dbo.fn_ReturnProductName() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO

IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
BEGIN
  DROP TABLE Order_DetailsBig
END
GO
SELECT ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS ProductID,
       ISNULL(GetDate() -  ABS(Checksum(NEWID())) / 1000000, GetDate()) AS Shipped_Date,
       CONVERT(Integer, ABS(Checksum(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM OrdersBig
GO
;WITH CTE1
AS
(
  SELECT * FROM Order_DetailsBig
  WHERE NOT EXISTS(SELECT 1 FROM ProductsBig WHERE ProductsBig.ProductID = Order_DetailsBig.ProductID)
)
UPDATE CTE1 SET ProductID = (SELECT TOP 1 ProductID FROM ProductsBig)
GO
DELETE FROM ProductsBig
WHERE NOT EXISTS(SELECT 1 FROM Order_DetailsBig WHERE ProductsBig.ProductID = Order_DetailsBig.ProductID)
GO
DELETE FROM Order_DetailsBig
WHERE NOT EXISTS(SELECT 1 FROM OrdersBig WHERE OrdersBig.OrderID = Order_DetailsBig.OrderID)
GO
;WITH CTE_1
AS
(
SELECT DateAdd(d, CONVERT(Int, ABS(CHECKSUM(NEWID())/ 10000000)), OrdersBig.OrderDate) AS Col1, Order_DetailsBig.Shipped_Date
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
)
UPDATE CTE_1 SET Shipped_Date = Col1
GO
;WITH CTE_1
AS
(
SELECT *, ROW_NUMBER() OVER(PARTITION BY [OrderID], [ProductID] ORDER BY [OrderID], [ProductID]) AS rn
  FROM Order_DetailsBig
)
DELETE FROM CTE_1 WHERE rn <> 1
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID])
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT FK FOREIGN KEY (OrderID) REFERENCES  OrdersBig(OrderID)
GO
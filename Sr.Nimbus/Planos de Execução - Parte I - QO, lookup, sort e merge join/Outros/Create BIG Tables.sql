USE NorthWind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
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
SELECT OrdersBig.OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 1000000)),0) AS ProductID,
       GetDate() -  ABS(Checksum(NEWID())) / 1000000 AS Shipped_Date,
       CONVERT(Integer, ABS(Checksum(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM OrdersBig
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID])
GO

ALTER TABLE [dbo].[OrdersBig]  WITH CHECK ADD  CONSTRAINT [fk_OrdersBig_CustomersBig] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[CustomersBig] ([CustomerID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
----------------------------------------
------- Ignorar linhas duplicadas ------
----------------------------------------

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

-- Caso o cliente já exista apagar, senão existe insere... 
IF EXISTS(SELECT * 
            FROM OrdersBig
           WHERE OrderID = 100)
BEGIN
  DELETE OrdersBig
   WHERE OrderID = 100
END
ELSE
BEGIN
  SET IDENTITY_INSERT OrdersBig ON
  INSERT INTO OrdersBig
          (OrderID, CustomerID, OrderDate, Value)
  VALUES  (100, 
           1, -- CustomerID - int
           GETDATE(), -- OrderDate - date
           10-- Value - numeric(18, 2)
           )
  SET IDENTITY_INSERT OrdersBig OFF
END
GO

-- É mais fácil/rápido...
DELETE OrdersBig
 WHERE OrderID = 100

IF @@RowCount > 0
BEGIN
  SET IDENTITY_INSERT OrdersBig ON
  INSERT INTO OrdersBig
          (OrderID, CustomerID, OrderDate, Value)
  VALUES  (100, 
           1, -- CustomerID - int
           GETDATE(), -- OrderDate - date
           10-- Value - numeric(18, 2)
           )
  SET IDENTITY_INSERT OrdersBig OFF
END
GO

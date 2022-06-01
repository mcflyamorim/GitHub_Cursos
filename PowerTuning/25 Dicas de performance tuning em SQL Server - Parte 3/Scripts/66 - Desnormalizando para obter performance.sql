USE Northwind
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


-- Retornar o último produto entregue por pedido...
-- E se eu quiser apenas dos pedidos que tem itens?... 
SELECT OrdersBig.*, Tab1.Last_Shipped_Date
  FROM OrdersBig
 CROSS APPLY (SELECT MAX(Shipped_Date) AS Last_Shipped_Date
                FROM Order_DetailsBig AS o1
               WHERE o1.OrderID = OrdersBig.OrderID) AS Tab1
GO

-- Retornar o último produto entregue por pedido...
SELECT OrdersBig.*, Tab1.Last_Shipped_Date
  FROM OrdersBig
 CROSS APPLY (SELECT MAX(Shipped_Date) AS Last_Shipped_Date
                FROM Order_DetailsBig AS o1
               WHERE o1.OrderID = OrdersBig.OrderID
               GROUP BY ()) AS Tab1
GO

-- Adicionando a coluna em Orders...
ALTER TABLE OrdersBig ADD Last_Shipped_Date DATETIME
GO

-- Atualizando a coluna...
UPDATE OrdersBig SET Last_Shipped_Date = Tab1.Last_Shipped_Date
FROM OrdersBig
 CROSS APPLY (SELECT MAX(Shipped_Date) AS Last_Shipped_Date
                FROM Order_DetailsBig AS o1
               WHERE o1.OrderID = OrdersBig.OrderID
               GROUP BY ()) AS Tab1
GO


-- SIM vamos precisar de uma trigger em Order_DetailsBig 
-- para manter OrdersBig atualizado...
-- No big deal... só não exagera na amizade...


SELECT * 
  FROM OrdersBig
GO


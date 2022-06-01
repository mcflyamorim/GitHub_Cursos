USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Qual índice criar?... por Value ou OrderDate?
SELECT * 
  FROM OrdersBig
 WHERE Value < 1.0
    OR OrderDate = '2020-05-28'
GO

CREATE INDEX ixValue ON OrdersBig(Value)
GO
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO

-- Seek nos dois índices...
SELECT * 
  FROM OrdersBig
 WHERE Value < 1.0
    OR OrderDate = '2020-05-28'
GO


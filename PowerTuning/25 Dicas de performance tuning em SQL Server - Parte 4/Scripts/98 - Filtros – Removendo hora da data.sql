USE Northwind
GO

-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 100000) AS CustomerID,
       CONVERT(DateTime, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- Removendo a hora da data...
SELECT TOP 10 *, CONVERT(DATE, OrderDate) 
  FROM OrdersBig
GO


-- Removendo a hora da data...
SELECT TOP 10 *, CONVERT(DATETIME, CONVERT(VARCHAR(10), OrderDate, 112))
  FROM OrdersBig
GO


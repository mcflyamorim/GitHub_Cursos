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
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

SET STATISTICS IO, TIME ON
SELECT CustomerID, OrderDate, Value 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120110'
 UNION ALL
SELECT CustomerID, OrderDate, Value
  FROM OrdersBig
 WHERE Value < 5
GO
SELECT CustomerID, OrderDate, Value 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120110'
 UNION
SELECT CustomerID, OrderDate, Value
  FROM OrdersBig
 WHERE Value < 5
GO
SET STATISTICS IO, TIME OFF
GO

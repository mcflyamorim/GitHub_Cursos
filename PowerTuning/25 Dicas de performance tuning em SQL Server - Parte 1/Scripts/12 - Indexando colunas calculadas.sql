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


-- Scan... expressão no filtro...
SELECT * 
  FROM OrdersBig
 WHERE Value / 2 < 1.0
GO

ALTER TABLE OrdersBig ADD Col1 AS Value / 2
GO

CREATE INDEX ixCol1 ON OrdersBig(Col1)
GO


-- Seek
SELECT * 
  FROM OrdersBig
 WHERE Value / 2 < 1.0
OPTION (RECOMPILE)
GO

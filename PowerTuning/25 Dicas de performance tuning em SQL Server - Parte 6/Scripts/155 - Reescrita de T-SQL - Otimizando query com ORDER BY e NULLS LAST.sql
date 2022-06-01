USE Northwind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 10
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(DATE, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
INSERT INTO OrdersBig
(
    CustomerID,
    OrderDate,
    Value
)
SELECT TOP 5
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       NULL AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO

-- Retornando todas as linhas ordenando por OrderDate
SELECT *
FROM OrdersBig
ORDER BY OrderDate;
GO


-- Umm, não era bem, isso... NULLs vem primeiro, como faço pra jogar null por último?

-- Agora sim... 
SELECT *
FROM OrdersBig
ORDER BY CASE WHEN OrderDate IS NOT NULL THEN 0 ELSE 1 END, OrderDate;
GO


-- Criando um índice pra evitar o SORT
DROP INDEX IF EXISTS ix1 ON OrdersBig
CREATE INDEX ix1 ON OrdersBig(OrderDate) INCLUDE(CustomerID, Value)
GO


-- Eita... O case atrapalhou o uso do meu índice
SELECT *
FROM OrdersBig
ORDER BY CASE WHEN OrderDate IS NOT NULL THEN 0 ELSE 1 END, OrderDate;
GO


-- Merge Join (Concatenation)
; WITH CTE_1
AS
(
  SELECT OrderID, CustomerID, OrderDate, Value, 0 Col1
  FROM OrdersBig
  WHERE OrderDate IS NULL
  UNION ALL
  SELECT OrderID, CustomerID, OrderDate, Value, 1 Col1
  FROM OrdersBig
  WHERE OrderDate IS NOT NULL
)
SELECT *
FROM CTE_1
ORDER BY Col1 DESC, OrderDate
GO
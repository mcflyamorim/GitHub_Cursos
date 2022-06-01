USE Northwind
GO
-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 10000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Col1 Int, Col2 Int)
GO
INSERT INTO Tab1 VALUES(1, 1), 
(1, 1), (1, 1), (1, 2), (2, 1), (2, 1), (3, 1), (3, 1)
GO

-- Retornar COUNT DISTINCT de Col2 agrupando por Col1
SELECT Col1,
       COUNT(Col2) AS "Count", -- Palavra reservada
       COUNT(DISTINCT Col2) AS CountDistict
  FROM Tab1
 GROUP BY Col1
GO

SELECT *,
       ROW_NUMBER() OVER(PARTITION BY Col1 ORDER BY Col2) AS rn
  FROM Tab1
GO
-- Outra forma de fazer o count distinct...
WITH CTE_1
AS
(
SELECT *,
       CASE
         WHEN ROW_NUMBER() OVER(PARTITION BY Col1, Col2 ORDER BY Col2) = 1 THEN 1
         ELSE NULL
       END AS rn
  FROM Tab1
)
SELECT Col1, COUNT(Col2) AS Cnt, COUNT(rn) CntDistinct
  FROM CTE_1
 GROUP BY Col1
GO

SELECT OrderDate, 
       COUNT(CustomerID) AS QtdeClientes, 
       COUNT(DISTINCT CustomerID) AS QtdeClientesDistintos
  FROM OrdersBig
 GROUP BY OrderDate
ORDER BY OrderDate
GO

-- Índice é necessário para evitar sort...
CREATE INDEX ixOrderDate_CustomerID ON OrdersBig(OrderDate, CustomerID)
GO

-- Outra forma de fazer o count distinct...
WITH CTE_1
AS
(
SELECT *,
       CASE
         WHEN ROW_NUMBER() OVER(PARTITION BY OrderDate, CustomerID ORDER BY CustomerID) = 1 THEN 1
         ELSE NULL
       END AS rn
  FROM OrdersBig
)
SELECT OrderDate, COUNT(OrderDate) AS QtdeClientes, COUNT(rn) QtdeClientesDistintos
  FROM CTE_1
 GROUP BY OrderDate
 ORDER BY OrderDate
GO
SELECT OrderDate, 
       COUNT(CustomerID) AS QtdeClientes, 
       COUNT(DISTINCT CustomerID) AS QtdeClientesDistintos
  FROM OrdersBig
 GROUP BY OrderDate
ORDER BY OrderDate
GO
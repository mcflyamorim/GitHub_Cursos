----------------------------------------
------- Excluir linhas duplicadas ------
----------------------------------------
/*
  Escreva um comando para apagar os tres primeiros pedidos por cliente
*/
USE TempDB
GO
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP(OrderID Int, CustomerID Int, OrderDate DATE)
GO
INSERT INTO #TMP
SELECT OrderID, CustomerID, OrderDate 
  FROM NorthWind.dbo.Orders
GO
INSERT INTO #TMP
        (OrderID, CustomerID, OrderDate)
VALUES  (10248, -- OrderID - int
         85, -- CustomerID - int
         '1996-07-04'  -- OrderDate - date
         )
GO


SELECT * 
  FROM #TMP
 ORDER BY OrderID
GO

SELECT OrderID,
       CustomerID,
       OrderDate,
       ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID) AS rn
  FROM #TMP
GO

-- Resposta
WITH CTE_1
AS
(
  SELECT OrderID,
         CustomerID,
         OrderDate,
         ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID) AS rn
    FROM #TMP
)
DELETE FROM CTE_1
WHERE rn > 1
GO

SELECT OrderID,
       CustomerID,
       OrderDate,
       ROW_NUMBER() OVER(PARTITION BY OrderID ORDER BY OrderID) AS rn
  FROM #TMP
GO
/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



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
  FROM northwind.dbo.Orders
GO
SELECT * FROM #TMP
GO

-- Resposta
WITH CTE_1
AS
(
  SELECT CustomerID,
         OrderDate,
         ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS rn
    FROM #TMP
)
DELETE FROM CTE_1
WHERE rn <= 3
GO
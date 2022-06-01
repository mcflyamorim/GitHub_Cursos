/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Cardinalidade
*/

-- Utiliza a densidade para fazer a estimativa
DECLARE @ContactName VarChar(20)
SET @ContactName = 'Maria Anders'
SELECT * FROM Customers
 WHERE ContactName = @ContactName

-- DROP INDEX ix_CustomerID ON Orders 
CREATE INDEX ix_CustomerID ON Orders (CustomerID)
-- Utiliza a densidade para fazer a estimativa
SELECT * FROM Orders
 WHERE CustomerID = (SELECT CustomerID 
                       FROM Customers 
                      WHERE ContactName = 'Maria Anders')

-- Utiliza a densidade para fazer a estimativa ou 10%
DECLARE @ContactName VarChar(20)

SELECT * FROM Products
 WHERE ProductName = @ContactName

-- Comparar o valor abaixo com o valor estimado do plano
SELECT (1.0 / (COUNT (DISTINCT ProductName))) * COUNT(*) 
  FROM Products

-- 9%
DECLARE @V1 Int, @V2 Int

SELECT * FROM Orders
 WHERE CustomerID BETWEEN @V1 AND @V2
OPTION(QueryTraceON 9481) -- TF 9481 desabilita o novo cardinatlity estimator

-- Comparar o valor abaixo com o valor estimado do plano
SELECT (COUNT(*) * 9.0) / 100 FROM Orders

-- 30%
DECLARE @V1 Int
SELECT * FROM Orders
 WHERE CustomerID > @V1

-- Comparar o valor abaixo com o valor estimado do plano
SELECT (COUNT(*) * 30.0) / 100 FROM Orders
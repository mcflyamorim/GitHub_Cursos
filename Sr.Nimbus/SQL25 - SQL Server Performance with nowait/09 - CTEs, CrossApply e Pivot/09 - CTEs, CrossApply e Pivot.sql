/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE Northwind
GO

----------------------------------------
----------------- TOP ------------------
----------------------------------------
-- Teste 1
-- Resultado não deterministico (TOP sem order by)

-- Não tenho garantia nenhuma de quais serão as 5 linhas que ele irá me retornar...
SELECT TOP 5 * 
  FROM Orders

-- Mesmo especificando uma coluna no ORDER BY, o resultado pode ser não deterministico
-- Como ShipVia não é único, eu não tenho garantia nenhuma de quais linhas serão retornadas...
SELECT TOP 5 * 
  FROM Orders
 ORDER BY ShipVia

-- Uma alternativa seria incluir uma coluna de desempate, por ex a PK
SELECT TOP 5 * 
  FROM Orders
 ORDER BY ShipVia, OrderID

 -- Execicio TOP

----------------------------------------
------------- CROSS APPLY --------------
----------------------------------------


----------------------------------------
---- Ultimas 3 vendas por Empregado ----
----------------------------------------


/*
  Escreva uma consulta que retorne as últimas 3 
  vendas por empregado. O resultado deverá ser ordenado por 
  FistName

  Banco: NorthWind
  Tabela: Employees, Orders
*/

-- Resultado esperado:
/*
  FirstName  OrderID     OrderDate
  ---------- ----------- -----------------------
  Andrew     11073       1998-05-05 00:00:00.000
  Andrew     11070       1998-05-05 00:00:00.000
  Andrew     11060       1998-04-30 00:00:00.000
  Anne       11058       1998-04-29 00:00:00.000
  Anne       11022       1998-04-14 00:00:00.000
  Anne       11017       1998-04-13 00:00:00.000
  Janet      11063       1998-04-30 00:00:00.000
  Janet      11057       1998-04-29 00:00:00.000
  Janet      11052       1998-04-27 00:00:00.000
  Laura      11075       1998-05-06 00:00:00.000
  ...
*/

-- Trabalhando nas formatações...
SELECT Customers.ContactName, Customers.CompanyName, Tab3.a, Tab3.b, Tab4.a
  FROM Customers
CROSS APPLY (SELECT REPLACE(ContactName, 'A', 'X'), CompanyName) Tab1(a, b)
CROSS APPLY (SELECT REPLACE(Tab1.a, 'B', 'X'), Tab1.b) AS Tab2(a, b)
CROSS APPLY (SELECT REPLACE(Tab2.a, 'C', 'X'), Tab2.b) AS Tab3(a, b)
CROSS APPLY (SELECT CASE WHEN CustomerID < 10 THEN 0 ELSE 1 END) AS Tab4(a)


----------------------------------------
------------ PIVOT/ UNPIVOT ------------
----------------------------------------

-- Utilizando agregação...
SELECT CustomerID,
       SUM(CASE WHEN OrderYear = 1996 THEN Value END) AS [1996],
       SUM(CASE WHEN OrderYear = 1997 THEN Value END) AS [1997],
       SUM(CASE WHEN OrderYear = 1998 THEN Value END) AS [1998]
 FROM (SELECT CustomerID, YEAR(OrderDate) AS OrderYear, Value
         FROM Orders) AS Tab
GROUP BY CustomerID
ORDER BY CustomerID
GO

-- Utilizando Pivot
SELECT *
  FROM (SELECT CustomerID, YEAR(OrderDate) AS OrderYear, Value
         FROM Orders) AS Tab
 PIVOT(SUM(Value) FOR OrderYear IN([1996],[1997],[1998])) AS P
ORDER BY CustomerID
GO

-- Utilizando OrdersBig
SELECT CustomerID,
       SUM(CASE WHEN OrderYear = 2006 THEN Value END) AS [2006],
       SUM(CASE WHEN OrderYear = 2007 THEN Value END) AS [2007],
       SUM(CASE WHEN OrderYear = 2008 THEN Value END) AS [2008],
       SUM(CASE WHEN OrderYear = 2009 THEN Value END) AS [2009],
       SUM(CASE WHEN OrderYear = 2010 THEN Value END) AS [2010],
       SUM(CASE WHEN OrderYear = 2011 THEN Value END) AS [2011],
       SUM(CASE WHEN OrderYear = 2012 THEN Value END) AS [2012],
       SUM(CASE WHEN OrderYear = 2013 THEN Value END) AS [2013],
       SUM(CASE WHEN OrderYear = 2014 THEN Value END) AS [2014],
       SUM(CASE WHEN OrderYear = 2015 THEN Value END) AS [2015],
       SUM(CASE WHEN OrderYear = 2016 THEN Value END) AS [2016],
       SUM(CASE WHEN OrderYear = 2017 THEN Value END) AS [2017],
       SUM(CASE WHEN OrderYear = 2018 THEN Value END) AS [2018]
 FROM (SELECT CustomerID, YEAR(OrderDate) AS OrderYear, Value
         FROM OrdersBig) AS Tab
GROUP BY CustomerID
ORDER BY CustomerID
GO

-- Utilizando Pivot
SELECT *
  FROM (SELECT CustomerID, YEAR(OrderDate) AS OrderYear, Value
         FROM OrdersBig) AS Tab
 PIVOT(SUM(Value) FOR OrderYear IN([2006],[2007],[2008],[2009],[2010],[2011],[2012],[2013],[2014],[2015],[2016],[2017],[2018])) AS P
ORDER BY CustomerID
GO


-- Utilizando UnPivot

-- Criando tabela para testes
-- DROP TABLE ##TMPTestUnpivot
SELECT *
  INTO #TMPTestUnpivot
  FROM (SELECT CustomerID, YEAR(OrderDate) AS OrderYear, Value
         FROM Orders) AS Tab
 PIVOT(SUM(Value) FOR OrderYear IN([1996],[1997],[1998])) AS P
ORDER BY CustomerID
GO

-- Vizualizando os dados da tabela
SELECT * 
  FROM #TMPTestUnpivot

-- Simulando Unpivot com CTE + CROSS JOIN + VALUES
WITH CTE_1
AS
(
SELECT CustomerID,
       Tab1.Ano,
       CASE Tab1.Ano
         WHEN 1996 THEN [1996] 
         WHEN 1997 THEN [1997] 
         WHEN 1998 THEN [1998]
       END AS Value
  FROM #TMPTestUnpivot
 CROSS JOIN (VALUES(1996), (1997), (1998)) AS Tab1(Ano)
)
SELECT * 
  FROM CTE_1
 WHERE Value IS NOT NULL
GO

-- Utilizando UNPIVOT
SELECT CustomerID, OrderYear, Value
  FROM #TMPTestUnpivot
  UNPIVOT(Value FOR OrderYear IN([1996],[1997],[1998])) AS U;
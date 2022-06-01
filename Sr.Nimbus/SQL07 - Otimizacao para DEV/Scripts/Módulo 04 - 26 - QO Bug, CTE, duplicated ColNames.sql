/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


WITH CTE
AS
(
  SELECT ProductName AS Col1, ProductName AS Col1
    FROM Products
   UNION ALL
  SELECT CONVERT(VarChar(40), ''), CONVERT(VarChar(40), '')
    FROM CTE
   WHERE 1=0
)
SELECT * 
  FROM CTE AS Tab



-- Não posso declarar mesmo nome de coluna
WiTH T
AS 
(
  SELECT 1 AS i, 2 AS i
)
SELECT * FROM T;

-- Não posso declarar mesmo nome de coluna
WiTH T
AS 
(
  SELECT 1 AS i, 2 AS i
   UNION ALL
  SELECT 1, 2
)
SELECT * FROM T;

-- Não posso declarar mesmo nome de coluna
WiTH T
AS 
(
  SELECT 1 AS i, 2 AS i
   UNION ALL
  SELECT 1, 2 FROM T
   WHERE 1 < 0
)
SELECT * FROM T;

-- Não posso declarar mesmo nome de coluna
WiTH T (i, i)
AS 
(
  SELECT 1, 2
)
SELECT * FROM T;

-- Erro no binding mesmo nome de coluna declarada duas vezes
WiTH T 
AS 
(
  SELECT 1 AS i, 2 AS i
   UNION ALL
  SELECT 1, 2 FROM T
   WHERE 1 < 0
)
SELECT * FROM T;


https://connect.microsoft.com/SQLServer/feedback/details/712799/recursive-cte-allows-duplicate-column-names
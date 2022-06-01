USE Northwind
GO

IF OBJECT_ID('fnSequencial', 'IF') IS NOT NULL
  DROP FUNCTION dbo.fnSequencial
GO
CREATE FUNCTION dbo.fnSequencial (@i Int)
RETURNS TABLE
AS
RETURN 
(
 WITH L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
     L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
     L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
     L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
     L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
     L5   AS(SELECT 1 AS C FROM L4 AS A CROSS JOIN L4 AS B), -- 4,294,967,296 rows
     Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L5)

SELECT TOP (@i) N AS Num
  FROM Nums
)
GO
/*
  SELECT * FROM dbo.fnSequencial(10)
*/



-- Quebrar uma string em várias linhas? ... 
SELECT SUBSTRING('Fabiano Amorim', Num, 1), *
  FROM dbo.fnSequencial(LEN('Fabiano Amorim'))
GO

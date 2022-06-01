USE Northwind
GO
-- Dica do Paul White
-- https://sqlperformance.com/2020/03/sql-performance/finding-distinct-values-quickly


-- Preparar ambiente... 
-- 2 minutos pra rodar
-- Tabela com 50mi linhas
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 50000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 1000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 10000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- SQL2014
ALTER DATABASE Northwind SET COMPATIBILITY_LEVEL = 120;
GO



SET STATISTICS IO, TIME ON

-- Paga um scan na tabela...
SELECT COUNT(DISTINCT CustomerID) 
  FROM OrdersBig
GO
-- Table 'OrdersBig'. Scan count 5, logical reads 180064
-- SQL Server Execution Times:
--   CPU time = 8718 ms,  elapsed time = 3005 ms.


-- Se eu criar um índice em CustomerID, ajuda?
-- 18 segundos pra rodar
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO


-- Ajuda, mas ainda tenho que fazer o Scan no índice...
SELECT COUNT(DISTINCT CustomerID) FROM OrdersBig
GO
-- Table 'OrdersBig'. Scan count 5, logical reads 87319
-- SQL Server Execution Times:
--   CPU time = 4499 ms,  elapsed time = 1440 ms.


-- SQL2019
ALTER DATABASE Northwind SET COMPATIBILITY_LEVEL = 150;
GO

-- Batch mode over row-store... ajuda?
SELECT COUNT(DISTINCT CustomerID) FROM OrdersBig
GO
-- Table 'OrdersBig'. Scan count 5, logical reads 87319
-- SQL Server Execution Times:
--   CPU time = 2640 ms,  elapsed time = 659 ms.



-- Considerando que o índice é ordernado, eu poderia pegar o menor valor de CustomerID
-- e depois ir procurando por outros valores onde a linha for maior que o menor valor lido... 

-- Isso pode valer a pena quando o número de valores distintos for pequeno


-- Por exemplo...
DECLARE @i INT = 0, @DistinctCount INT = 1

-- Pega o menor valor de CustomerID
SELECT TOP 1
       @i = CustomerID
  FROM OrdersBig
 WHERE CustomerID > @i
 ORDER BY CustomerID ASC

-- Verifica se algo foi retornado
IF @@RowCount = 0
  SET @i = 0

-- Enquanto @i for maior que zero, ou seja, achou um CustomerID, 
-- continua o loop
WHILE @i > 0
BEGIN
  SET @DistinctCount += 1;

  -- Lê o menor valor onde CustomerID for maior que 
  -- o último valor lido
  SELECT TOP 1
         @i = CustomerID
    FROM OrdersBig
   WHERE CustomerID > @i
   ORDER BY CustomerID ASC
  -- Se não achou nada, seta @i pra zero pra parar o loop
  IF @@RowCount = 0
    SET @i = 0
END;

-- Retornando o número de valores distintos...
SELECT @DistinctCount AS DistinctCount
GO


-- Versão set-based com CTE recursiva...
-- Usando ROW_NUMBER pra ler apenas o TOP 1 (rn = 1)
-- Pra evitar limitação da recursividade com TOP/OFFSEET e 
-- GROUP BY, HAVING ou aggregate functions que não são permitidos 
-- em CTEs recursivas
;WITH CTE_1 AS
(
    -- Anchor
    SELECT TOP 1
           CustomerID
      FROM OrdersBig
     ORDER BY CustomerID ASC
     UNION ALL
    -- Recursive
    SELECT tmp1.CustomerID
    FROM
    (
        SELECT 
            o1.CustomerID,
            rn = ROW_NUMBER() OVER (ORDER BY o1.CustomerID ASC)
         FROM CTE_1
        INNER JOIN OrdersBig AS o1
           ON o1.CustomerID > ISNULL(CTE_1.CustomerID, -1)
    ) AS tmp1
    WHERE tmp1.rn = 1
)
SELECT COUNT(CTE_1.CustomerID)
  FROM CTE_1
OPTION (MAXRECURSION 0);
GO

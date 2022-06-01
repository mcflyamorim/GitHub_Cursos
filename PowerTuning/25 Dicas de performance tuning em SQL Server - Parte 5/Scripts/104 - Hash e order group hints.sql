USE NorthWind
GO

IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
  DROP TABLE Order_DetailsBig
GO
SELECT TOP 50000
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS ProductID,
       ISNULL(GetDate() -  ABS(Checksum(NEWID())) / 1000000, GetDate()) AS Shipped_Date,
       CONVERT(Integer, ABS(Checksum(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
GO
;WITH CTE_1
AS
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY [OrderID], [ProductID] ORDER BY [OrderID], [ProductID]) AS rn
    FROM Order_DetailsBig
)
DELETE FROM CTE_1 WHERE rn <> 1
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID])
GO
-- Order Group | Hash Group


-- Criando procedure
IF OBJECT_ID('st_TesteGroupHints') IS NOT NULL DROP PROC st_TesteGroupHints
GO
CREATE PROCEDURE st_TesteGroupHints @ProductID Int
AS
SELECT Order_DetailsBig.ProductID,
       SUM(Order_DetailsBig.Quantity) AS Sum_Quantity
  FROM Order_DetailsBig
 WHERE (Order_DetailsBig.ProductID = @ProductID OR @ProductID IS NULL)
 GROUP BY Order_DetailsBig.ProductID
OPTION (MAXDOP 1)
GO


-- "cold cache"
CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS;
GO
-- Para retornar dados de 1 produto, um Sort+StreamAggregate funciona bem...
EXEC st_TesteGroupHints @ProductID = 1
GO

-- E pra retornar várias linhas? Sort warning na certa...
-- Query roda em 1.5 segundos...
EXEC st_TesteGroupHints @ProductID = NULL
GO


-- Recriando a procedure com "hash group"
IF OBJECT_ID('st_TesteGroupHints') IS NOT NULL DROP PROC st_TesteGroupHints
GO
CREATE PROCEDURE st_TesteGroupHints @ProductID Int
AS
SELECT Order_DetailsBig.ProductID,
       SUM(Order_DetailsBig.Quantity) AS Sum_Quantity
  FROM Order_DetailsBig
 WHERE (Order_DetailsBig.ProductID = @ProductID OR @ProductID IS NULL)
 GROUP BY Order_DetailsBig.ProductID
OPTION (MAXDOP 1, HASH GROUP)
GO

-- "cold cache"
CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS;
GO
-- Para retornar dados de 1 produto, funciona bem, porem utiliza mais recursos de 
-- CPU e memória
EXEC st_TesteGroupHints @ProductID = 1
GO

-- E pra retornar várias linhas? Muito melhor que o sort+stream ...
-- Query roda em 0 segundos
EXEC st_TesteGroupHints @ProductID = NULL
GO

/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
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

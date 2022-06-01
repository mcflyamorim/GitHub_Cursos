/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE NorthWind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO



-- DROP INDEX ixOrderDate ON OrdersBig 
CREATE INDEX ixOrderDate ON OrdersBig (OrderDate)
GO


-- Seek predicate é utilizado para navegar pela árvore do índice
SELECT * 
  FROM OrdersBig
 WHERE OrderID = 100
GO

-- Predicate é aplicado como filtro depois da navegação pela árvore
SELECT * 
  FROM OrdersBig WITH(INDEX=1)
 WHERE OrderDate BETWEEN '20500101' AND '20500101'
   AND OrderID < 1000000
OPTION (RECOMPILE)

-- Predicate como filter operator... TF 9130
SELECT * 
  FROM OrdersBig WITH(INDEX=1)
 WHERE OrderDate BETWEEN '20500101' AND '20500101'
   AND OrderID < 1000000
OPTION (RECOMPILE, QueryTraceON 9130)
GO

/*
  Pergunta... temos 2 índices na tabela OrdersBig, um por OrderID (PK)
  e outro por OrderDate

  Qual é a melhor forma de acesso? Qual índice?
*/

-- Exemplo, filtro seletivo por OrderDate
-- Faz seek predicate por OrderDate e aplica predicate por OrderID
SELECT * 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20500101' AND '20500101'
   AND OrderID < 1000
GO

-- Exemplo, filtro seletivo por OrderID
-- Faz seek predicate por OrderID e aplica predicate por OrderDate
SELECT * 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120101'
   AND OrderID < 1000
GO
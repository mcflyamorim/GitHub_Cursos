/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Index seek - Seek predicate, predicate
*/

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
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120110'
   AND OrderID < 100000

/*
  Pergunta... temos 2 índices na tabela OrdersBig, um por OrderID (PK)
  e outro por OrderDate

  Qual é a melhor forma de acesso? Qual índice?

  Depende da seletividade dos filtros.

  Se o filtro por OrderID for mais seletivo, usa o índice por OrderID
  Se o filtro por OrderDate for mais seletivo, usa o índice por OrderDate
*/

-- Exemplo, filtro seletivo por OrderID
-- Faz seek predicate por OrderID e aplica predicate por OrderDate
SELECT * 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120110'
   AND OrderID < 1000
GO

-- Exemplo, filtro seletivo por OrderID
-- Faz seek predicate por OrderDate e aplica predicate por OrderID
SELECT * 
  FROM OrdersBig
 WHERE OrderDate BETWEEN '20120101' AND '20120101'
   AND OrderID < 1000
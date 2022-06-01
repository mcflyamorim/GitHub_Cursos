/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

/*
  Hint - ForceSeek
*/

USE NorthWind
GO
-- Apagar os índices atuais
-- DROP INDEX CustomersBig.ixContactName
-- DROP INDEX OrdersBig.ixCustomerID
-- DROP INDEX OrdersBig.ixOrderDate
-- DROP INDEX OrdersBig.ixCustomerID_Value


-- Exemplo 1

-- Criar índices para melhorar a consulta abaixo
CREATE INDEX ixContactName ON CustomersBig(ContactName)
CREATE INDEX ixCustomerID_Value ON OrdersBig(CustomerID, Value)
GO

-- Identificar um cliente com poucas vendas (novos clientes)
SELECT CustomerID,
       (SELECT ContactName FROM CustomersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID),
       COUNT(*)
  FROM OrdersBig
 GROUP BY CustomerID
 ORDER BY 2 DESC
GO

CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
-- Índice por OrdersBig não é utilizado
-- porque o lookup é muito caro (devido a estimativa incorreta)
SELECT CustomersBig.ContactName,
       OrdersBig.*
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Patricio Simpson D8197CE1'
   AND OrdersBig.Value < (SELECT AVG(a.Value) 
                            FROM OrdersBig a 
                           WHERE a.CustomerID = OrdersBig.CustomerID)
OPTION (MAXDOP 1)
GO


CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SELECT CustomersBig.ContactName,
       OrdersBig.*
  FROM OrdersBig WITH(FORCESEEK)
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Patricio Simpson D8197CE1'
   AND OrdersBig.Value < (SELECT AVG(a.Value) 
                            FROM OrdersBig a 
                           WHERE a.CustomerID = OrdersBig.CustomerID)
OPTION (MAXDOP 1)
GO

-- Exemplo 2
USE AdventureWorks2012
GO
-- DROP INDEX ix_OrderDate ON Sales.SalesOrderHeader
CREATE INDEX ix_OrderDate ON Sales.SalesOrderHeader(OrderDate)
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON;
GO
-- Scan é FORWARD por SalesOrderID e Ordered=True, ou seja, 
-- a primeira linha que for retornada do scan (aplicando predicate) 
-- será a menor linha, neste caso o scan pode parar
-- Operador de TOP pede uma linha de cada vez (Top Expression (1))
SELECT MIN(SalesOrderID)
  FROM Sales.SalesOrderHeader
 WHERE OrderDate > '2005-07-01 00:00:00.000'
OPTION (RECOMPILE)
GO
SET STATISTICS IO OFF;
GO
SELECT * FROM Sales.SalesOrderHeader

-- Query 2
CHECKPOINT; DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON;
GO
SELECT MIN(SalesOrderID)
  FROM Sales.SalesOrderHeader
 WHERE OrderDate > '2008-06-25 00:00:00.000'
OPTION (RECOMPILE)
GO
SET STATISTICS IO OFF;
GO

-- Query 3 (forceseek)
CHECKPOINT; DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON;
GO
SELECT MIN(SalesOrderID)
  FROM Sales.SalesOrderHeader WITH(FORCESEEK)
 WHERE OrderDate > '2008-06-25 00:00:00.000'
OPTION (RECOMPILE)
GO
SET STATISTICS IO OFF;
GO

-- Query 4
-- Desabilitando exploration rule que faz a "otimização"
-- ScalarGbAggToTop -- Scalar Group By Aggregation to Top
CHECKPOINT; DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON;
GO
SELECT MIN(SalesOrderID)
  FROM Sales.SalesOrderHeader
 WHERE OrderDate > '2008-06-25 00:00:00.000'
OPTION (RECOMPILE, QueryRuleOff ScalarGbAggToTop)
GO
SET STATISTICS IO OFF;
GO

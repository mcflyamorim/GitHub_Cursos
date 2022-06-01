/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/


/*
  Hint - ForceSeek
*/

-- Exemplo 1
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

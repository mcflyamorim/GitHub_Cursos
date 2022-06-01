/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE [master]
RESTORE DATABASE [AdventureWorks2012] FROM  DISK = N'D:\Fabiano\Trabalho\FabricioLima\Cursos\25 Dicas de performance tuning em SQL Server - Parte 2\Outros\AdventureWorks2012.bak' 
WITH  FILE = 1,  MOVE N'AdventureWorks2012' TO N'd:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019CTP2_4\MSSQL\DATA\AdventureWorks2012.mdf',  
MOVE N'AdventureWorks2012_log' TO N'd:\Program Files\Microsoft SQL Server\MSSQL15.SQL2019CTP2_4\MSSQL\DATA\AdventureWorks2012_log.ldf',  
NOUNLOAD,  REPLACE,  STATS = 5
GO


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
 WHERE OrderDate >= '2011-06-01 00:00:00.000'
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
 WHERE OrderDate >= '2014-01-01 00:00:00.000'
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
 WHERE OrderDate >= '2014-01-01 00:00:00.000'
OPTION (RECOMPILE)
GO
SET STATISTICS IO OFF;
GO

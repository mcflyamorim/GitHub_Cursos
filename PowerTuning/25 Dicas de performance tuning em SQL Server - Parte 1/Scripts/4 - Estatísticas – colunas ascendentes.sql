USE Northwind
GO
IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
-- Criar tablea de 1 milhão para efetuar os testes
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 100000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       DATEADD(year, -1, CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 10000000))) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
DELETE FROM OrdersBig WHERE OrderDate > GetDate()
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
-- DELETE FROM OrdersBig WHERE OrderDate > GetDate()
-- DROP INDEX OrdersBig.ix_OrderDate
CREATE INDEX ix_OrderDate on OrdersBig(OrderDate)
GO


-- Visualizar fim do histograma
DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate]) WITH HISTOGRAM
GO

-- Consultar últimos pedidos inseridos
-- seek + lookup para retornar poucas linhas, melhor plano
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = DATEADD(DAY, 1, CONVERT(Date, GetDate()))
OPTION(RECOMPILE, QueryTraceOn 9481)
GO

-- Exibindo o problema
-- Inserir 5 mil linhas ascendentes
INSERT INTO OrdersBig WITH(TABLOCK) (CustomerID, OrderDate, Value) 
SELECT TOP 5000
       ISNULL(ABS(CONVERT(Int, (CheckSUM(NEWID()) / 1000000))),0) CustomerID,
       DATEADD(DAY, 1, CONVERT(Date, GetDate())) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
 FROM sysobjects a, sysobjects b, sysobjects c
GO

-- Consultar últimos pedidos inseridos
-- Não disparou o auto update statistics... porém, sabemos que a coluna é ascendente...
-- Precisamos fazer algo para "corrigir" isso
SET STATISTICS IO ON
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = DATEADD(DAY, 1, CONVERT(Date, GetDate()))
OPTION(RECOMPILE, QueryTraceOn 9481)
SET STATISTICS IO OFF
GO

-- Scan era a melhor opção...
SET STATISTICS IO ON
SELECT OrderID, OrderDate, Value
  FROM OrdersBig WITH(FORCESCAN)
 WHERE OrderDate = DATEADD(DAY, 1, CONVERT(Date, GetDate()))
OPTION(RECOMPILE, QueryTraceOn 9481)
SET STATISTICS IO OFF
GO


-- Default no SQL2014+
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = DATEADD(DAY, 2, CONVERT(Date, GetDate()))
OPTION(RECOMPILE)
GO


DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate]) 
GO

SELECT (0.002331002 * 100000) 
GO


-- Antes do SQL2014, precisavamos utilizar os TFs 2389 e 2390
-- https://www.red-gate.com/simple-talk/sql/database-administration/statistics-on-ascending-columns/
-- Precisamos fazer algo para "corrigir" isso
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = DATEADD(DAY, 1, CONVERT(Date, GetDate()))
OPTION(RECOMPILE, QueryTraceOn 2389, QueryTraceOn 2390)
GO

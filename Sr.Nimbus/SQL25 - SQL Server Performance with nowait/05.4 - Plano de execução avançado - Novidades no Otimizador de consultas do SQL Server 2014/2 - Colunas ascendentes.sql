/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



-- Alternativa
-- https://www.simple-talk.com/sql/database-administration/statistics-on-ascending-columns/
-- TFs 2389 e 2390


USE Northwind
GO

-- Colunas ascendentes


-- Criar tablea de 1 milhão para efetuar os testes
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       DATEADD(year, -1, CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 10000000))) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
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
 WHERE OrderDate = CONVERT(Date, GetDate())
OPTION(RECOMPILE, QueryTraceON 9481) -- TF 9481 desabilita o novo cardinatlity estimator
GO

-- Exibindo o problema

-- Inserir 50 mil linhas ascendentes
INSERT INTO OrdersBig WITH(TABLOCK) (CustomerID, OrderDate, Value) 
SELECT TOP 50000
       ISNULL(ABS(CONVERT(Int, (CheckSUM(NEWID()) / 1000000))),0) CustomerID,
       GetDate() AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
 FROM sysobjects a, sysobjects b, sysobjects c
GO




-- Estimativa incorreta pois as estatísticas estão desatualizadas
-- e não atingiram o número suficiente de alterações para disparar 
-- o auto update 
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = CONVERT(Date, GetDate())
OPTION(RECOMPILE, QueryTraceON 9481) -- TF 9481 desabilita o novo cardinatlity estimator
GO

-- Por que errou na estimativa? 
-- Porque não tem no histograma vendas com data maior que hoje
DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate]) WITH HISTOGRAM
GO

-- Com o novo cardinality estimator sempre estima que os valores existem
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = CONVERT(Date, GetDate())
OPTION(RECOMPILE, QueryTraceON 2312) -- TF 2312 habilita o novo cardinality estimator
GO


-- E com os TFs 2389 e 2390?
SELECT OrderID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = CONVERT(Date, GetDate())
OPTION(RECOMPILE, QUERYTRACEON 2389, QUERYTRACEON 2390, QueryTraceON 9481)



-- Bônus

-- Atualizar apenas dados "do fim" da estatística
UPDATE STATISTICS OrdersBig ix_Orderdate WITH FULLSCAN, INCREMENTAL = ON
GO

Msg 9108, Level 16, State 2, Line 88
This type of statistics is not supported to be incremental.


CREATE INDEX ix_OrderDate on OrdersBig(OrderDate) WITH (STATISTICS_INCREMENTAL = ON)
GO

 INCREMENTAL = { ON | OFF }
    When ON, the statistics created are per partition statistics. When OFF, stats are combined for all partitions. The default is OFF.
    If per partition statistics are not supported an error is generated. Incremental stats are not supported for following statistics types:
        Statistics created with indexes that are not partition-aligned with the base table.
        Statistics created on AlwaysOn readable secondary databases.
        Statistics created on read-only databases.
        Statistics created on filtered indexes.
        Statistics created on views.
        Statistics created on internal tables.
        Statistics created with spatial indexes or XML indexes.
GO
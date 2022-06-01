/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

------------------------------------
-- AutoCreated – Computed columns --
------------------------------------

USE Northwind
GO

-- Preparando banco
ALTER TABLE Order_DetailsBig DROP COLUMN Quantity
-- Aprox. 15 segundos
ALTER TABLE Order_DetailsBig ADD Quantity Int NOT NULL DEFAULT ABS(CHECKSUM(NEwID())) / 100000000
GO
UPDATE Order_DetailsBig SET Quantity = ABS(CHECKSUM(NEwID())) / 100000000
WHERE Quantity = 0
GO
-- ALTER TABLE Order_DetailsBig DROP COLUMN UnitPrice
ALTER TABLE Order_DetailsBig ADD UnitPrice Numeric(18,2) NULL
GO
-- Aprox. 16 segundos
UPDATE TOP (90) PERCENT Order_DetailsBig SET UnitPrice = ABS(CHECKSUM(NEwID())) / 10000000.
GO

-- Consulta simples para retornar clientes com
-- pedidos e itens com valor total menor que 0.5
-- SQL chuta estimativa de 30% por causa da expressão (UnitPrice * Quantity)
-- Demora 8 segundos e gera plano com scan nas 3 tabelas
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON
SELECT CustomersBig.ContactName,
       OrdersBig.OrderID, 
       UnitPrice * Quantity AS Total
  FROM Order_DetailsBig
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE Order_DetailsBig.UnitPrice * Order_DetailsBig.Quantity < 0.5
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO
/*
  Table 'Order_DetailsBig'. Scan count 5, logical reads 7267, physical reads 1
  Table 'OrdersBig'. Scan count 5, logical reads 3627, physical reads 1
  Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0
  Table 'CustomersBig'. Scan count 5, logical reads 14119, physical reads 2
*/

-- Adicionar coluna calculada com o total
-- ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn 
ALTER TABLE Order_DetailsBig ADD ComputedColumn AS UnitPrice * Quantity
GO

-- Dispara auto create statistics para a coluna calculada
-- Demora 5 segundos e gera plano muito melhor
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SET STATISTICS IO ON
SELECT CustomersBig.ContactName,
       OrdersBig.OrderID, 
       UnitPrice * Quantity AS Total
  FROM Order_DetailsBig
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE Order_DetailsBig.UnitPrice * Order_DetailsBig.Quantity < 0.5
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO
/*
  Table 'CustomersBig'. Scan count 0, logical reads 7825, physical reads 1
  Table 'OrdersBig'. Scan count 0, logical reads 7832, physical reads 1
  Table 'Order_DetailsBig'. Scan count 1, logical reads 7197, physical reads 2
*/

-- Verifica estatística por ComputedColumn criada automaticamente
sp_helpstats Order_DetailsBig
GO


-- IMPORTANTE --
-- Expressão da coluna calculada tem que fazer match com a expressão do filtro


-- Faz estimativa correta usando a estatística
SELECT * FROM Order_DetailsBig
 WHERE UnitPrice * Quantity < 10.0
GO

-- Não consegue fazer estimativa
-- mesmo que seja lógicamente possível já que 
-- (Quantity * UnitPrice) é igual a (UnitPrice * Quantity)
SELECT * FROM Order_DetailsBig
 WHERE Quantity * UnitPrice < 10.0
GO


-- EDGE Cases
-- Caso mais interessante (leia-se geek)

-- Apagando a coluna calculada
ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn
GO

-- Estimativa incorreta, 30%
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Vamos criar uma estatística calculada com fullscan
-- DROP STATISTICS Order_DetailsBig.Stats1
-- ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn1
ALTER TABLE Order_DetailsBig ADD ComputedColumn1 AS ISNULL(Quantity,0) * ISNULL(UnitPrice, 0)
GO
CREATE STATISTICS Stats1 ON Order_DetailsBig(ComputedColumn1) WITH FULLSCAN
GO

-- Agora vai?
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- DROP STATISTICS Order_DetailsBig.Stats2
-- ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn2
ALTER TABLE Order_DetailsBig ADD ComputedColumn2 AS Quantity * ISNULL(UnitPrice, 0)
GO
CREATE STATISTICS Stats2 ON Order_DetailsBig(ComputedColumn2) WITH FULLSCAN
GO

-- Coluna Quantity não aceita NULL
-- O SQL Server sabe disso e o que ele faz? 
-- Troca o ISNULL(Quantity, 0) por Quantity
-- Dai a expressão não faz match com a coluna calculada...
-- Ver o predicate aplicado no scan
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE Quantity * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Mesmo usando a funcion funciona porque o QO a ignora
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO
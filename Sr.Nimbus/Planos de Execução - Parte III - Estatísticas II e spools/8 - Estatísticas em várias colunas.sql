/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-----------------------------
-- Multi column statistics --
-----------------------------

USE Northwind
GO

ALTER TABLE CustomersBig ADD Ativo Char(1)
ALTER TABLE CustomersBig ADD Estado_Civil VarChar(200)
GO

UPDATE CustomersBig SET Ativo = NULL, Estado_Civil = NULL
UPDATE TOP (50) PERCENT CustomersBig SET Ativo = 'S', Estado_Civil = 'Casado'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
UPDATE TOP (250000) CustomersBig SET Ativo = 'N', Estado_Civil = 'Casado'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
UPDATE TOP (250000) CustomersBig SET Ativo = 'S', Estado_Civil = 'Solteiro'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
GO

UPDATE STATISTICS CustomersBig WITH FULLSCAN
GO

-- Plano com estimativa incorreta por causa do filtro em 
-- Ativo e Estado_Civil
SELECT CustomersBig.ContactName, COUNT_BIG(*) AS Qtde
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE CustomersBig.Ativo = 'N'
   AND CustomersBig.Estado_Civil = 'Casado'
   AND Order_DetailsBig.Quantity < 300
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1)


-- Criando estatística nas colunas para ajudar a estimativa
-- DROP STATISTICS CustomersBig.Stats1
CREATE STATISTICS Stats1 ON CustomersBig(Ativo, Estado_Civil) WITH FULLSCAN
GO

-- Plano com estimativa correta
SELECT CustomersBig.ContactName, COUNT_BIG(*) AS Qtde
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE CustomersBig.Ativo = 'N'
   AND CustomersBig.Estado_Civil = 'Casado'
   AND Order_DetailsBig.Quantity < 300
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1)

-- Se o SQL errar na estimativa varios problemas podem ocorrer:

-- Falta de memoria (memory grant)
-- Algoritmos de join errado
-- Ordem de acesso as tabelas errado
-- ...
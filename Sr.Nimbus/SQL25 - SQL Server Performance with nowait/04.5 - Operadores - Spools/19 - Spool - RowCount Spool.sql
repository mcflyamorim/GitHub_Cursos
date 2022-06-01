/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

------------------------------
--- Spool - RowCount Spool ---
------------------------------

USE Northwind
GO


/*
  Row Count Spool
*/

-- Preparando o ambiente
UPDATE OrdersBig SET OrderDate = '20500101'
  WHERE OrderID = 999

/*
  Exemplo Row Count Spool, 
  armazena o resultado da SubQuery em um Cache e depois 
  consulta o valor em cache e não na tabela Orders
*/
SET STATISTICS IO ON
SELECT OrderID,
       Value
  FROM OrdersBig Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM OrdersBig Ped2
                   WHERE Ped2.OrderDate = '20500101'
                     AND Ped2.Value > 100)
OPTION(RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF
GO

/*
  Simulando o não uso do Row Count Spool
*/
SET STATISTICS IO ON
SELECT OrderID,
       Value
  FROM OrdersBig Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM OrdersBig Ped2
                   WHERE Ped2.OrderDate = '20500101'
                     AND Ped2.Value > 100)
OPTION(RECOMPILE, MAXDOP 1, QueryRuleOff BuildSpool)
SET STATISTICS IO OFF
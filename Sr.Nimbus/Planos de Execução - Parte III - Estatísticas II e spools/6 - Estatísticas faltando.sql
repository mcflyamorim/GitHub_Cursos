/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-------------------------------
---- Estatísticas faltando ----
-------------------------------

USE Northwind
GO


-- Apagar as estatísticas e índices atuais
SELECT * 
  FROM sys.stats
 WHERE object_id = object_id ('OrdersBig')
GO
DROP STATISTICS OrdersBig._WA_Sys_00000004_2AA05119
DROP STATISTICS OrdersBig._WA_Sys_00000003_2AA05119
DROP STATISTICS OrdersBig._WA_Sys_00000002_2AA05119
GO
DROP INDEX OrdersBig.ixOrdersBig_CustomerID
GO
SELECT * 
  FROM sys.stats
 WHERE object_id = object_id ('CustomersBig')
GO
DROP STATISTICS CustomersBig._WA_Sys_00000004_5B438874
GO
DROP INDEX CustomersBig.ContactName
GO


-- Auto create statistics desligado
ALTER DATABASE Northwind SET AUTO_CREATE_STATISTICS OFF
GO

-- Consulta que precisa de estatística para decidir qual 
-- melhor plano
DBCC DROPCLEANBUFFERS
SELECT CustomersBig.ContactName,
       COUNT(DISTINCT OrdersBig.OrderDate) DatasDistintas,
       SUM(OrdersBig.Value) SumValue
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'F%'
   AND OrdersBig.Value < 1.0
 GROUP BY CustomersBig.ContactName
GO

ALTER DATABASE Northwind SET AUTO_CREATE_STATISTICS ON
GO

-- Plano muito mais eficiente
DBCC DROPCLEANBUFFERS
SELECT CustomersBig.ContactName, 
       COUNT(DISTINCT OrdersBig.OrderDate) DatasDistintas,
       SUM(OrdersBig.Value) SumValue
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'F%'
   AND OrdersBig.Value < 1.0
 GROUP BY CustomersBig.ContactName
GO
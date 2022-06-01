/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE NorthWind
GO

/*
  Scan direction e paralelismo
*/


-- Dependendo da ordem que a tabela será lida, o scan será paralelisado ou não
-- Plano da consulta abaixo mostra que o scan na CustomersBig esta em uma "zona não paralela"
DBCC DROPCLEANBUFFERS;
GO
SELECT OrdersBig.OrderID,
       OrdersBig.OrderDate, 
       OrdersBig.CustomerID,
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= '20200101'
 ORDER BY CustomersBig.CustomerID DESC
GO

-- Trocando para ASC temos o Scan na CustomersBig em paralelo
DBCC DROPCLEANBUFFERS;
GO
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate,
       OrdersBig.CustomerID,
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= '20200101'
 ORDER BY CustomersBig.CustomerID ASC
GO

-- Alternativa, criar índice com order desc para conseguir fazer a leitura forward
-- DROP INDEX ixCustomerID ON CustomersBig 
CREATE INDEX ixCustomerID ON CustomersBig (CustomerID DESC) INCLUDE(ContactName)
USE Northwind
GO

-- Preparar ambiente... Criar tabelas com 1 milhão de linhas...
-- 10 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Dependendo da ordem que a tabela será lida, o scan será paralelisado ou não
-- Plano da consulta abaixo mostra que o scan na CustomersBig esta em uma "zona não paralela"
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SELECT OrdersBig.OrderID,
       OrdersBig.OrderDate, 
       OrdersBig.CustomerID,
       CustomersBig.ContactName
  FROM OrdersBig
 INNER MERGE JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= '20200101'
 ORDER BY CustomersBig.CustomerID DESC
GO

-- Trocando para ASC temos o Scan na CustomersBig em paralelo
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate,
       OrdersBig.CustomerID,
       CustomersBig.ContactName
  FROM OrdersBig
 INNER MERGE JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= '20200101'
 ORDER BY CustomersBig.CustomerID ASC
GO

-- Alternativa, criar índice com order desc para conseguir fazer a leitura forward
-- DROP INDEX ixCustomerID ON CustomersBig 
CREATE INDEX ixCustomerID ON CustomersBig (CustomerID DESC) INCLUDE(ContactName)
GO


CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SELECT OrdersBig.OrderID,
       OrdersBig.OrderDate, 
       OrdersBig.CustomerID,
       CustomersBig.ContactName
  FROM OrdersBig
 INNER MERGE JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= '20200101'
 ORDER BY CustomersBig.CustomerID DESC
GO
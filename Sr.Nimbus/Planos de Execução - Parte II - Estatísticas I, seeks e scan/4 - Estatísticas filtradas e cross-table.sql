/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Estatísticas filtradas e cross-table
*/

-- Preparando demo

-- DROP INDEX ixContactName ON CustomersBig
-- DROP INDEX ixCustomerID ON OrdersBig
CREATE INDEX ixContactName ON CustomersBig(ContactName) -- indexing WHERE
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(Value) -- indexing FK
GO

-- Apagar estatísticas já existentes
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('CustomersBig')
GO
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('CustomersBig')
GO

/*
  DROP STATISTICS CustomersBig._WA_Sys_00000002_6383C8BA
*/

-- Criar novo cliente
INSERT INTO CustomersBig (CompanyName, ContactName, Col1, Col2)
VALUES ('Emp Fabiano', 'Fabiano Amorim', NEWID(), NEWID())
GO
-- Inserir novo pedido
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES(SCOPE_IDENTITY(), GetDate(), 999)
SET IDENTITY_INSERT Order_DetailsBig ON
INSERT INTO Order_DetailsBig(OrderID, ProductID, Shipped_Date, Quantity)
VALUES (SCOPE_IDENTITY(), 1, GetDate() + 30, 999)
SET IDENTITY_INSERT Order_DetailsBig OFF
GO

-- Estimativa incorreta
SELECT OrdersBig.OrderID, OrdersBig.Value, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)


-- Alternativa 1
DECLARE @CustomerID Int, @ContactName VarChar(250)

SELECT @CustomerID = CustomerID, @ContactName = ContactName
  FROM CustomersBig
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'

SELECT OrdersBig.OrderID, @ContactName AS ContactName 
  FROM OrdersBig
 WHERE OrdersBig.CustomerID = @CustomerID
OPTION (RECOMPILE)


-- Alternativa 2

-- DROP STATISTICS CustomersBig.Stats1
CREATE STATISTICS Stats1 ON CustomersBig(CustomerID)
WHERE ContactName = 'Fabiano Amorim' WITH FULLSCAN
GO

-- Estimativa correta
SELECT OrdersBig.OrderID, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)

DBCC SHOW_STATISTICS (CustomersBig, Stats1) -- Retorna RANGE_HI_KEY = 1000001

DBCC SHOW_STATISTICS (OrdersBig, ixCustomerID) -- Retorna EQ_ROWS 1 baseado no KEY 1000001

DROP STATISTICS CustomersBig.Stats1

-- Outro exemplo


-- DROP STATISTICS CustomersBig.Stats2
CREATE STATISTICS Stats2 ON CustomersBig(CustomerID)
WHERE ContactName = 'Simon Crowther EEA18037' WITH FULLSCAN
GO

-- Estimativa incorreta
SELECT OrdersBig.OrderID, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Simon Crowther EEA18037'
OPTION (RECOMPILE)

DBCC SHOW_STATISTICS (CustomersBig, Stats2) -- Retorna RANGE_HI_KEY = 48

DBCC SHOW_STATISTICS (OrdersBig, ixCustomerID) -- Retorna EQ_ROWS 361250 baseado no KEY 48

DROP STATISTICS CustomersBig.Stats2


-- Not so good: O filtro da consulta tem que "bater" com o filtro da estatística



-- Alternativa 3 (mais sobre isso no próximo Modulo do on-demand(parte III))
-- DROP VIEW vw_test1

CREATE VIEW vw_test1
WITH SCHEMABINDING
AS
SELECT OrdersBig.OrderID, CustomersBig.ContactName 
  FROM dbo.OrdersBig
 INNER JOIN dbo.CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
GO

CREATE UNIQUE CLUSTERED INDEX ix1 ON vw_Test1(OrderID)
GO

-- Estimativa incorreta
SELECT OrdersBig.OrderID, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)


SELECT OrderID, ContactName 
  FROM vw_Test1 WITH(noexpand)
 WHERE ContactName = 'Fabiano Amorim'

SELECT OrderID, ContactName 
  FROM vw_Test1 WITH(noexpand)
 WHERE ContactName = 'Simon Crowther EEA18037'

-- Consultar estatísticas da view
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('vw_Test1')
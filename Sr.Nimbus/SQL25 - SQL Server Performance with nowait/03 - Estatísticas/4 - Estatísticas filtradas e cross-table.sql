/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Estatísticas filtradas e cross-table
*/

-- Preparando demo

-- Preparar ambiente... Criar tabelas com 5 milhões de linhas...
-- 2 mins para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
  DROP TABLE OrdersBig
END
GO
SELECT TOP 5000000
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

-- DROP INDEX ixContactName ON CustomersBig
-- DROP INDEX ixCustomerID ON OrdersBig
CREATE INDEX ixContactName ON CustomersBig(ContactName) -- indexing WHERE
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) -- indexing FK
GO

-- Criar novo cliente
SET IDENTITY_INSERT CustomersBig ON
INSERT INTO CustomersBig (CustomerID, CompanyName, ContactName, Col1, Col2)
VALUES (-1 ,'Emp Fabiano', 'Fabiano Amorim', NEWID(), NEWID())
SET IDENTITY_INSERT CustomersBig OFF
GO

-- Inserir novo pedido
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES(-1, GetDate(), 999)


-- Consulta pedido do cliente novo
SELECT * FROM OrdersBig
WHERE CustomerID = -1



-- Estimativa incorreta
-- Não usa índice em OrdersBig.CustomerID... Prefere fazer scan
SET STATISTICS IO ON
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

SELECT OrdersBig.OrderID, OrdersBig.Value, @ContactName AS ContactName 
  FROM OrdersBig
 WHERE OrdersBig.CustomerID = @CustomerID
OPTION (RECOMPILE)


-- Alternativa 2

-- DROP STATISTICS CustomersBig.Stats1
CREATE STATISTICS Stats1 ON CustomersBig(CustomerID)
WHERE ContactName = 'Fabiano Amorim' WITH FULLSCAN
GO

-- Estimativa correta
SELECT OrdersBig.OrderID, OrdersBig.Value, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)


DBCC SHOW_STATISTICS (CustomersBig, Stats1) -- Retorna RANGE_HI_KEY = -1

DBCC SHOW_STATISTICS (OrdersBig, ixCustomerID) -- Retorna EQ_ROWS 1 baseado no KEY -1

DROP STATISTICS CustomersBig.Stats1


-- Alternativa 3
-- DROP VIEW vw_test1

CREATE VIEW vw_test1
WITH SCHEMABINDING
AS
SELECT OrdersBig.OrderID, OrdersBig.Value, CustomersBig.ContactName 
  FROM dbo.OrdersBig
 INNER JOIN dbo.CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
GO

CREATE UNIQUE CLUSTERED INDEX ix1 ON vw_Test1(OrderID)
GO

-- Estimativa incorreta... O ideal seria o SQL já identificar a view 
SELECT OrdersBig.OrderID, OrdersBig.Value, CustomersBig.ContactName 
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)
GO

-- Estimativa correta
-- Somente utiliza estatística com noexpand... :-(
SELECT OrderID, Value, ContactName 
  FROM vw_Test1 WITH(noexpand)
 WHERE ContactName = 'Fabiano Amorim'
OPTION (RECOMPILE)


-- Podemos observar que o QO criou uma estatística por ContactName na view
sp_helpstats vw_test1
GO

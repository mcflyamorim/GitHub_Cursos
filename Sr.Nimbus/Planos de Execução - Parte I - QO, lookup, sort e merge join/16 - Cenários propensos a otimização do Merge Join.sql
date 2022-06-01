/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

------------------------------------
------- Otimizando Merge Join ------
------------------------------------

USE Northwind
GO
-- Preparando demo
-- Limpar vendas para cliente 999999
DELETE FROM OrdersBig
WHERE CustomerID = 999999
GO
-- Inserir Venda para o cliente 999999 com data de 2020
INSERT INTO OrdersBig
        ( CustomerID, OrderDate, Value )
VALUES  (999999, -- CustomerID - int
         '20200101', -- OrderDate - date
         99.99  -- Value - numeric
         )
GO

-- Consulta que gera MergeJoin por causa da variável local... 
-- (estimativa de 30% para sinal de >=)
-- Merge join faz scan a partir do cliente 1 e termina no cliente 1000000
-- Filtro na OrdersBig retorna CustomerID 999999...

DBCC DROPCLEANBUFFERS;

DECLARE @dt Date = '20200101'
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
 ORDER BY OrdersBig.CustomerID ASC
OPTION (MAXDOP 1)
GO

-- DROP INDEX ixOrderDate ON OrdersBig
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate) INCLUDE(CustomerID)
GO




-- Alternativa 1
-- Ajudar o SQL dizendo onde o Scan na CustomersBig deve começar
DBCC DROPCLEANBUFFERS;
DECLARE @dt Date = '20200101', @MinCustomerID Int

-- Pegar menor CustomerID com base no filtro da data
SELECT @MinCustomerID = MIN(CustomerID)
  FROM OrdersBig
 WHERE OrdersBig.OrderDate >= @dt
-- Passar o menor CustomerID como filtro
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
   AND CustomersBig.CustomerID >= @MinCustomerID
 ORDER BY OrdersBig.CustomerID ASC
OPTION (MAXDOP 1, MERGE JOIN)
GO

-- Alternativa 2
-- Se o join começar o scan do Fim (DESC) este problema pontual seria resolvido
-- Basta alterar ASC para DESC que a ordem dos SCANs são invertidos para garantir
-- a ordem e evitar novo sort
-- ScanDirection no Scan da CustomersBig é BACKWARD
DBCC DROPCLEANBUFFERS;
DECLARE @dt Date = '20200101'
SELECT OrdersBig.OrderID, OrdersBig.OrderDate, CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
 ORDER BY OrdersBig.CustomerID DESC
OPTION (MAXDOP 1)
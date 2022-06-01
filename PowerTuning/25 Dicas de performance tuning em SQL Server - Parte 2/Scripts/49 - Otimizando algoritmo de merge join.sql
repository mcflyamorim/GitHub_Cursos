/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

-- Preparar ambiente... 
-- 11 segundos para rodar
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


-- Preparando demo
-- Inserir Venda para o cliente 999999 com data de 2090
INSERT INTO OrdersBig
        ( CustomerID, OrderDate, Value )
VALUES  (999999, -- CustomerID - int
         '20900101', -- OrderDate - date
         99.99  -- Value - numeric
         )
GO



SELECT * FROM OrdersBig
WHERE CustomerID = 999999


-- Consulta que gera MergeJoin por causa da variável local... 
-- (estimativa de 30% para sinal de >=)
-- Merge join faz scan a partir do cliente 1 e termina no cliente 1000000
-- Filtro na OrdersBig retorna CustomerID 999999...

CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO ON
DECLARE @dt Date = '20900101'
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
 ORDER BY OrdersBig.CustomerID ASC
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

-- Alternativa 1
-- Alterar a ordenação do SCAN em CustomersBig... 
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO ON
DECLARE @dt Date = '20900101'
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       CustomersBig.ContactName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
 ORDER BY OrdersBig.CustomerID DESC
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

-- Alternativa 2
-- Ajudar o SQL dizendo onde o Scan na CustomersBig deve começar
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO ON
DECLARE @dt Date = '20900101', @MinCustomerID Int

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
SET STATISTICS IO OFF
GO


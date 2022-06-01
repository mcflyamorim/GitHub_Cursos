/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE FabianoDica38
GO

-- Preparar ambiente... 
-- 25 segundos para rodar...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VARCHAR(500),  NEWID()) AS Col1 
  INTO OrdersBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- Criando alguns índices pra teste...
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(Col1)
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate) INCLUDE(Col1)
CREATE INDEX ixValue ON OrdersBig(Value) INCLUDE(Col1)
CREATE INDEX ix1 ON OrdersBig(Col1)
GO

-- Narrow plan
UPDATE OrdersBig SET Col1 = NEWID()
FROM OrdersBig
WHERE OrderID <= 10
OPTION (MIN_GRANT_PERCENT = 50)
GO

-- Wide plan
UPDATE OrdersBig SET Col1 = NEWID()
FROM OrdersBig
WHERE OrderID <= 500000
OPTION (MIN_GRANT_PERCENT = 50)
GO

-- Forçando o plano narrow, evitamos o custo do sort/spool
-- porém aumentamos o custo devido ao random I/O... 
-- pode valer a pena em um SSD/FlashStorage
DECLARE @OrderID INT = 500000
UPDATE OrdersBig SET Col1 = NEWID()
FROM OrdersBig
WHERE OrderID <= @OrderID
OPTION (MAXDOP 1, MIN_GRANT_PERCENT = 50, OPTIMIZE FOR (@OrderID = 10))
GO


-- Poucas linhas = narrow plan ... Consigo forçar com TOP + OPTIMZE FOR... 
-- Muitas linhas = wide plan ... Consigo forçar com TOP + OPTIMIZE FOR ou TF 8790

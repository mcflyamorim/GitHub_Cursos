-- Variável do tipo table pode gerar plano ruim até com 1 linha
USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Apagar todos os índices de OrdersBig
-- DROP INDEX OrdersBig.ixCustomerID
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO


-- Pode optar por um Scan em OrdersBig
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();

-- Declarando a variável...
DECLARE @Tab1 TABLE(ID Int, Col1 VarChar(500) DEFAULT NEWID())

-- Inserindo uma linhazinha...
INSERT INTO @Tab1(ID) VALUES(1)

SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 INNER JOIN @Tab1
    ON [@Tab1].ID = OrdersBig.CustomerID
SET STATISTICS IO OFF
GO

-- E option recompile ajuda? 
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();

-- Declarando a variável...
DECLARE @Tab1 TABLE(ID Int, Col1 VarChar(500) DEFAULT NEWID())

-- Inserindo uma linhazinha...
INSERT INTO @Tab1(ID) VALUES(1)

SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 INNER JOIN @Tab1
    ON [@Tab1].ID = OrdersBig.CustomerID
OPTION (RECOMPILE)
SET STATISTICS IO OFF
GO


-- Seek + Lookup em OrdersBig
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
IF OBJECT_ID('tempdb.dbo.#Tab1') IS NOT NULL
  DROP TABLE #Tab1
GO
CREATE TABLE #Tab1 (ID Int, Col1 VarChar(500) DEFAULT NEWID())
INSERT INTO #Tab1(ID) VALUES(1)

SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 INNER JOIN #Tab1
    ON [#Tab1].ID = OrdersBig.CustomerID
SET STATISTICS IO OFF
GO



-- NOTA
-- SQL2012SP2 ou SQL2014CU3 adicionaram TF 2453 que 
-- faz mesma coisa que o OPTION(RECOMPILE)
-- http://support.microsoft.com/kb/2952444
/*
Note this trace flag must be ON at runtime. You cannot use this trace flag with QUERYTRACEON. 
This trace flag must be used with caution because it can increase number of query recompiles which 
could cost more than savings from better query optimization.
*/
USE Northwind
GO
-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 100000
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
SELECT TOP 100000
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
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(OrderDate)
GO


--SubQueries ou Cross outer apply
-- As consultas abaixo são equivalentes?
-- Qual é mais rápida?
SET STATISTICS IO, TIME ON
CHECKPOINT; DBCC DROPCLEANBUFFERS(); 
GO
SELECT TOP 50000 *, (SELECT COUNT(*) 
                      FROM OrdersBig 
                     WHERE CustomersBig.CustomerID = OrdersBig.CustomerID) 
  FROM CustomersBig
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS(); 
GO
SELECT TOP 50000 CustomersBig.*, Tab1.Cnt
  FROM CustomersBig
OUTER APPLY (SELECT COUNT(*) FROM OrdersBig 
                     WHERE CustomersBig.CustomerID = OrdersBig.CustomerID) AS Tab1(Cnt)
GO

SET STATISTICS IO, TIME OFF
GO



-- Outer apply parece ser um pouco mais rápido... 
---- Me parece que isso vai depender muito da quantidade de 
---- leituras lógicas efetuadas no inner loop (seek em OrdersBig)
-- eu não esperava ver diferença nos planos... 
-- mais uma pra lista de... vale o teste...

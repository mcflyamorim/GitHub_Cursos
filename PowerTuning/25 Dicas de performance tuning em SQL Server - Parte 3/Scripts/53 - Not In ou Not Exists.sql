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


--NOT IN versus NOT EXISTS
-- As consultas abaixo são equivalentes?
SET STATISTICS IO, TIME ON
GO
SELECT TOP 1000 * FROM CustomersBig
WHERE CustomerID NOT IN (SELECT CustomerID FROM OrdersBig)
GO
SELECT TOP 1000 * FROM CustomersBig
WHERE NOT EXISTS(SELECT * 
                   FROM OrdersBig 
                  WHERE OrdersBig.CustomerID = CustomersBig.CustomerID)
SET STATISTICS IO, TIME OFF
GO








-- E agora?...
SET STATISTICS IO, TIME ON
GO
SELECT TOP 1000 * FROM CustomersBig
WHERE CustomerID NOT IN (SELECT ISNULL(CustomerID, 0) FROM OrdersBig)
GO
SELECT TOP 1000 * FROM CustomersBig
WHERE NOT EXISTS(SELECT * 
                   FROM OrdersBig 
                  WHERE OrdersBig.CustomerID = CustomersBig.CustomerID)
GO
SET STATISTICS IO, TIME OFF
GO
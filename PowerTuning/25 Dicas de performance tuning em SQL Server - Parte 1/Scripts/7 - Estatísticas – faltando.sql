USE Northwind
GO

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


-- Auto create statistics desligado
ALTER DATABASE Northwind SET AUTO_CREATE_STATISTICS OFF
GO

-- Consulta que precisa de estatística para decidir qual 
-- melhor plano
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
SELECT CustomersBig.ContactName,
       COUNT(DISTINCT OrdersBig.OrderDate) DatasDistintas,
       SUM(OrdersBig.Value) SumValue
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'F%'
   AND OrdersBig.Value < 1.0
 GROUP BY CustomersBig.ContactName
GO

ALTER DATABASE Northwind SET AUTO_CREATE_STATISTICS ON
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
-- Plano parece melhor pra você?
DBCC DROPCLEANBUFFERS
SELECT CustomersBig.ContactName, 
       COUNT(DISTINCT OrdersBig.OrderDate) DatasDistintas,
       SUM(OrdersBig.Value) SumValue
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'F%'
   AND OrdersBig.Value < 1.0
 GROUP BY CustomersBig.ContactName
GO
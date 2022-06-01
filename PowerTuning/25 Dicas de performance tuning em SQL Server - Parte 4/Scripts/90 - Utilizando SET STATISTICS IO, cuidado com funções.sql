USE Northwind
GO

-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000) AS CustomerID,
       CONVERT(DateTime, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) 
INCLUDE(OrderDate)
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


-- Scalar Functions com SubQuery
IF OBJECT_ID('fn_DataUltimaVenda', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_DataUltimaVenda
GO
CREATE FUNCTION dbo.fn_DataUltimaVenda(@CustomerID Int)
RETURNS DateTime
AS
BEGIN
  DECLARE @DtUltimaVenda DateTime
 
  SELECT @DtUltimaVenda = MAX(OrderDate)
    FROM OrdersBig
   WHERE CustomerID = @CustomerID

  RETURN @DtUltimaVenda
END
GO

SELECT TOP 1000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO

SELECT TOP 1000
       (SELECT MAX(OrderDate)
          FROM OrdersBig
         WHERE CustomerID = CustomersBig.CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO

-- E o STATISTICS IO? Ta certo?...
SET STATISTICS IO ON
GO
SELECT TOP 1000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SELECT TOP 1000
       (SELECT MAX(OrderDate)
          FROM OrdersBig
         WHERE CustomerID = CustomersBig.CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SET STATISTICS IO OFF

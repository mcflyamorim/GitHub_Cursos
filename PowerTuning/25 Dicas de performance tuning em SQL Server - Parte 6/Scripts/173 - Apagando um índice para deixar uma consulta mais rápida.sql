USE Northwind
GO
SET STATISTICS IO ON
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 200
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

IF OBJECT_ID('fn_ReturnCustomersBig') IS NOT NULL
  DROP FUNCTION fn_ReturnCustomersBig
GO
CREATE FUNCTION dbo.fn_ReturnCustomersBig()
RETURNS Int
AS
BEGIN
  DECLARE @ID INT

  ;WITH CTE1
  AS
   (
    SELECT * FROM (VALUES(1, 51)) AS Tab(Val1, Val2)
   )
  SELECT @ID = Val1+ ABS(CHECKSUM(((SELECT NewID FROM vw_NewID)))) % (Val2-Val1)
    FROM CTE1

  RETURN(@ID)
END
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       dbo.fn_ReturnCustomersBig() AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
-- DROP INDEX "ixCustomerID_OrderDate" ON OrdersBig
CREATE INDEX "ixCustomerID_OrderDate" ON OrdersBig(CustomerID, OrderDate)
GO
-- DROP INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig
CREATE INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig(OrderDate) INCLUDE(CustomerID, Value)
GO





-- Nice plan...
-- Pra cada cliente retornado de CustomersBig, faz um Seek em OrdersBig
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate 
                FROM OrdersBig 
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
OPTION (RECOMPILE)
GO

-- E se eu precisar retornar OrderDate e Value de OrdersBig?
-- Muda algo?
-- Absurdos 7 segundos pra rodar...
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate DESC) AS Tab1
OPTION (RECOMPILE)
GO

-- E se eu apagar esse índice "ixOrderDate Include(CustomerID, Value)" ? 
-- Como fica o plano?
DROP INDEX "ixOrderDate Include(CustomerID, Value)" ON OrdersBig
GO

-- Seek + Lookup pra ler a coluna Value...
SELECT * 
  FROM CustomersBig
 CROSS APPLY (SELECT TOP 1 OrderDate, Value
                FROM OrdersBig
               WHERE OrdersBig.CustomerID = CustomersBig.CustomerID
               ORDER BY OrderDate) AS Tab1
GO

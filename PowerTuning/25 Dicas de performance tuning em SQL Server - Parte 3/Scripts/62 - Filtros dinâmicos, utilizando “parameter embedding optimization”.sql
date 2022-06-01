USE Northwind
GO

-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 100000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- DROP INDEX ixCustomerID ON OrdersBig
-- DROP INDEX ixOrderDate ON OrdersBig
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO

-- Stored Procedure st_RetornaOrders
IF OBJECT_ID('st_RetornaOrders') IS NOT NULL 
  DROP PROC st_RetornaOrders
GO
CREATE PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                             @CustomerID  AS Int      = NULL,
                             @OrderDate   AS DateTime = NULL
AS
BEGIN
  SELECT OrderID, CustomerID, OrderDate, Value
    FROM OrdersBig
   WHERE (OrderID    = @OrderID    OR @OrderID    IS NULL)
     AND (CustomerID = @CustomerID OR @CustomerID IS NULL)
     AND (OrderDate  = @OrderDate  OR @OrderDate  IS NULL)
END
GO

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO


-- Stored Procedure st_RetornaOrders
IF OBJECT_ID('st_RetornaOrders') IS NOT NULL 
  DROP PROC st_RetornaOrders
GO
CREATE PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                             @CustomerID  AS Int      = NULL,
                             @OrderDate   AS DateTime = NULL
AS
BEGIN
  SELECT OrderID, CustomerID, OrderDate, Value
    FROM OrdersBig
   WHERE (OrderID    = @OrderID    OR @OrderID    IS NULL)
     AND (CustomerID = @CustomerID OR @CustomerID IS NULL)
     AND (OrderDate  = @OrderDate  OR @OrderDate  IS NULL)
  OPTION (RECOMPILE)
END
GO

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO
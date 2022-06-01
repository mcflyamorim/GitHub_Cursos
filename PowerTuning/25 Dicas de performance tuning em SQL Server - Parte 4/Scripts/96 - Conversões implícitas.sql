USE Northwind
GO
-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 10000
       ISNULL(CONVERT(NVARCHAR(20), ABS(CheckSUM(NEWID()) / 10000)),0) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
;WITH CTE_1
AS
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY [OrderID] ORDER BY [OrderID]) AS rn
    FROM OrdersBig
)
DELETE FROM CTE_1 WHERE rn <> 1
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID) WITH(IGNORE_DUP_KEY=ON)
GO
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO

-- Faz seek ou scan?
SELECT * FROM OrdersBig
 WHERE CONVERT(DATE, OrderDate) = GETDATE()
GO

-- Faz seek ou scan?
DECLARE @Tab TABLE(ID BIGINT)
INSERT INTO @Tab VALUES(10)

SELECT * FROM OrdersBig
 WHERE CustomerID IN (SELECT * FROM @Tab) -- * funciona? 
GO
-- Cuidado com casos onde o SQL decide converter CustomerID ao inves de @Tab.ID

-- Data Type Precedence (Transact-SQL)
https://msdn.microsoft.com/en-us/library/ms190309.aspx
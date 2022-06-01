USE NorthWind
GO

-- Create 1m rows test table
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


IF OBJECT_ID('ReturnLast', 'FN') IS NOT NULL
  DROP FUNCTION dbo.ReturnLast
GO
CREATE FUNCTION dbo.ReturnLast(@Val VarChar(100), @Len Int)
RETURNS Int
AS
BEGIN
  RETURN RIGHT(@Val, @Len)
END
GO

-- Quantas vezes a função é chamada??...
SELECT SUM(CONVERT(NUMERIC(18,2), dbo.ReturnLast(Value, 2))),
       CASE 
          WHEN SUM(dbo.ReturnLast(Value, 2)) BETWEEN 0 AND 100 THEN 'Entre 0 e 100'
          ELSE ''
       END          
  FROM OrdersBig
 WHERE Value < 10000 * CONVERT(NUMERIC(18,2), dbo.ReturnLast(Value, 2))
 ORDER BY SUM(CONVERT(NUMERIC(18,2), dbo.ReturnLast(Value, 2)))
GO


-- Utilizando a CTE + Cross Apply... 
;WITH CTE_1
AS
(
  SELECT SUM(Tab1.Col1) AS ReturnLast
    FROM OrdersBig
   CROSS APPLY (SELECT CONVERT(NUMERIC(18,2), dbo.ReturnLast(OrdersBig.Value, 2))) AS Tab1(Col1)
   WHERE Value < 10000 * Col1
)
-- Quantas vezes a função é chamada??...
SELECT ReturnLast,
       CASE 
          WHEN ReturnLast BETWEEN 0 AND 100 THEN 'Entre 0 e 100'
          ELSE ''
       END
  FROM CTE_1
 ORDER BY 1
GO

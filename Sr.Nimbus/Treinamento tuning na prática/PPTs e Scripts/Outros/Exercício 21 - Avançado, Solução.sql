USE Northwind
GO
-- ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 50000000
       ABS(CHECKSUM(NEWID())) / 1000000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX CCC_OrdersBig ON OrdersBig (CustomerID, Value);
GO


SELECT OrdersBig.CustomerID, Customers.ContactName, SUM(Value) AS vSum
  FROM OrdersBig
  LEFT OUTER JOIN Customers
    ON Customers.CustomerID = OrdersBig.CustomerID
 GROUP BY OrdersBig.CustomerID, Customers.ContactName
 ORDER BY OrdersBig.CustomerID
OPTION (RECOMPILE)
GO




DROP TABLE IF EXISTS #tmp

SELECT OrdersBig.CustomerID, CONVERT(VARCHAR(30), NULL) AS ContactName, SUM(Value) AS vSum
  INTO #tmp
  FROM OrdersBig
 GROUP BY OrdersBig.CustomerID
OPTION (RECOMPILE)
GO

UPDATE #tmp SET ContactName = Customers.ContactName
  FROM #tmp
  INNER JOIN Customers
    ON Customers.CustomerID = #tmp.CustomerID

SELECT * FROM #tmp
 ORDER BY CustomerID
GO

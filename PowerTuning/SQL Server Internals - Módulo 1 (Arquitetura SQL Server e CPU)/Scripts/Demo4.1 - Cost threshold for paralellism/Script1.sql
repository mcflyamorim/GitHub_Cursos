USE NorthWind
GO

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
SELECT TOP 1500000
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


-- Query rodando em paralelo...
-- Query cost = 27.86, >5, portanto considera paralelismo
SELECT TOP 5000 * FROM OrdersBig
ORDER BY Value
OPTION (RECOMPILE)
GO


EXEC sys.sp_configure N'cost threshold for parallelism', N'50'
GO
RECONFIGURE WITH OVERRIDE
GO



-- Query rodando em paralelo...
-- Query cost = 27.86
-- Por que está rodando em paralelo se eu mudei o CTP pra 50?
SELECT TOP 5000 * FROM OrdersBig
ORDER BY Value
OPTION (RECOMPILE)
GO



-- Cleanup
EXEC sys.sp_configure N'cost threshold for parallelism', N'5'
GO
RECONFIGURE WITH OVERRIDE
GO

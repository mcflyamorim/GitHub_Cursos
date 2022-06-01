USE NorthWind
GO

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
SELECT TOP 2000000
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
CHECKPOINT;DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
SELECT * FROM OrdersBig
WHERE Value < 1000
GO


-- Problema 1...
-- Abrir outra sessão
BEGIN TRAN

UPDATE OrdersBig SET CustomerID = 10
WHERE OrderID = (SELECT MAX(OrderID) FROM OrdersBig)

ROLLBACK TRAN
GO

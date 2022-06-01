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
SELECT TOP 1000
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



-- Query para ler dados da OrdersBig
SELECT * FROM OrdersBig
WHERE Value < 10
GO

-- Em uma nova sessão
BEGIN TRAN
GO

UPDATE TOP (1) OrdersBig SET Value = 10
WHERE Value < 10
GO

ROLLBACK TRAN
GO


-- All good
-- Rodar no SQLQueryStress
-- 200 threads
-- 1 iterations

-- Todas as threads ficarão bloqueadas... 

-- Como ficam as DMVs? 

-- dm_os_waiting_tasks vai mostrar 201 sessões esperando...

-- Abrir outro SQLQueryStress
-- 200 threads
-- 1 iterations

-- E agora, como ficam as DMVs?

-- dm_os_waiting_tasks vai mostrar 201 sessões esperando...

-- Abrir mais 2 SQLQueryStress
-- 200 threads
-- 1 iterations

-- E se rodarmos a query com MAXDOP (2) ?
-- Ainda tenho timeouts no SQLQuery stress ? ...
DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
SELECT TOP 100 * FROM OrdersBig
ORDER BY Value
OPTION (MAXDOP 2)
GO
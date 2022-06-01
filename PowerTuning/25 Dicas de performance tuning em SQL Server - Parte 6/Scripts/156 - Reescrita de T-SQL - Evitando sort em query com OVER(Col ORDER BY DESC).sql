USE Northwind
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
SELECT TOP 100000
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


-- Gera um sort por CustomerID, OrderDate e OrderID... Esperado... 
SELECT CustomerID, OrderDate, OrderID,
  ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS rownum
FROM OrdersBig
GO

-- Criando um índice pra ajudar com o Sort
DROP INDEX IF EXISTS ix1 ON OrdersBig
CREATE INDEX ix1 ON OrdersBig(CustomerID, OrderDate, OrderID)
GO

-- Continua gerando Sort... :-( ... Ué...
SELECT CustomerID, OrderDate, OrderID,
  ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS rn
FROM OrdersBig
GO

-- Recriando o índice na ordem do Sort
DROP INDEX IF EXISTS ix1 ON OrdersBig
CREATE INDEX ix1 ON OrdersBig(CustomerID ASC, OrderDate DESC, OrderID DESC)
GO

-- Agora sim...
SELECT CustomerID, OrderDate, OrderID,
  ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS rn
FROM OrdersBig
GO

-- Recriando o índice "normal" com tudo ASC
DROP INDEX IF EXISTS ix1 ON OrdersBig
CREATE INDEX ix1 ON OrdersBig(CustomerID, OrderDate, OrderID)
GO


-- Outra alternativa mais fácil... Mas daí os dados vem em uma ordem diferente...
SELECT CustomerID, OrderDate, OrderID,
  ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS rownum
FROM OrdersBig
ORDER BY CustomerID DESC
GO

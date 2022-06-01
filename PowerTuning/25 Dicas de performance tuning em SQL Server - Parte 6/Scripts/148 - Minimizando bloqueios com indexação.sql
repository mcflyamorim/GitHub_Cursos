USE Northwind
GO
-- Criando tabela para testes...
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
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       CONVERT(Date, '20180630') AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       CONVERT(Date, '20500101') AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO



-- Rodar em nova sessão
BEGIN TRAN
GO
-- Remover dados de 1 a 10 de Janeiro de 2018... +- 2328 linhas atualizadas...
DELETE OrdersBig
WHERE OrderDate BETWEEN '20180101' AND '20180110'
GO

--ROLLBACK TRAN
--GO




-- Se eu tentar ler dados de 20500101, vou conseguir?
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO


-- Criando um índice pra ajudar...
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO


-- Rodar delete novamente...


-- E agora, se eu tentar ler dados de 20500101, vou conseguir? 
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO

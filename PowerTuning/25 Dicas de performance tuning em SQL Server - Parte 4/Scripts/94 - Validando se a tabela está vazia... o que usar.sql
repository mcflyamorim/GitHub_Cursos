USE NorthWind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Pode ser assim?
DECLARE @i INT
SELECT @i = COUNT(*) 
  FROM OrdersBig

IF @i > 0
  SELECT 'Tabela não está vazia'
ELSE
  SELECT 'Tabela vazia...'
GO

-- Assim é melhor?
IF (SELECT COUNT(*) 
      FROM OrdersBig) > 0
  SELECT 'Tabela não está vazia'
ELSE
  SELECT 'Tabela vazia...'
GO

-- Assim é menos ruim...
IF EXISTS(SELECT * -- oh meu Deus, posso usar * aqui? 
            FROM OrdersBig)
  SELECT 'Tabela não está vazia'
ELSE
  SELECT 'Tabela vazia...'
GO

-- Pode ser assim tbm
IF EXISTS(SELECT * -- oh meu Deus, posso usar * aqui? 
            FROM sysindexes
           WHERE id = OBJECT_ID('OrdersBig') 
             AND indid <= 1
             AND rowcnt > 0)
  SELECT 'Tabela não está vazia'
ELSE
  SELECT 'Tabela vazia...'
GO
-- Cuidado com bancos recem atualizados...
USE Northwind
GO

-- 15 segundos para rodar...
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 3000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO

DBCC FREEPROCCACHE()
GO
-- Demora 2/3 segundos...
DECLARE @i INT = 10
SELECT TOP (@i)
       CustomerID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
GO

-- Mas e se eu recompilar?...
DECLARE @i INT = 10
SELECT TOP (@i)
       CustomerID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (RECOMPILE)
GO

-- O que é melhor? pagar o recompile? ou deixar a query que roda 3 segundos? ... 
-- Como simular um stress de 20 usuários rodando a query ao mesmo tempo?

-- SQLQUERYSTRESS -- 
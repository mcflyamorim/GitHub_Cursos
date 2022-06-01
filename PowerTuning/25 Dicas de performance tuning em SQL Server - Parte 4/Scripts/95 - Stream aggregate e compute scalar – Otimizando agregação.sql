USE Northwind
GO

-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 100000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Function para retornar último caracter...
IF OBJECT_ID('RetornaUltimoCarac', 'FN') IS NOT NULL
  DROP FUNCTION dbo.RetornaUltimoCarac
GO
CREATE FUNCTION dbo.RetornaUltimoCarac(@Val VarChar(100), @Len Int)
RETURNS Int
AS
BEGIN
  RETURN RIGHT(@Val, @Len)
END
GO


SELECT SUM(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO

-- Quantas vezes executa a function?
-- Ver stream aggregate
-- 5/6 segundos para rodar...
SELECT SUM(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO


-- E com MAX que executa apenas 1 vez? Quanto tempo?
SELECT MAX(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO

-- Alternativa...
-- What, now?
SELECT SUM(Tab1.Col1)
  FROM OrdersBig
 CROSS APPLY (SELECT Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2))) AS Tab1(Col1)
GO
-- Yep, a vida não é fácil...

-- Related Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/636382/scalar-expression-evaluated-twice-with-sum-aggregate
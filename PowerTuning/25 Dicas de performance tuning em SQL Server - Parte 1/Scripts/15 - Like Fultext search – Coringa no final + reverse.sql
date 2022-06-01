USE Northwind
GO

IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 10000 IDENTITY(Int, 1,1) AS ProductID, 
       dbo.fn_ReturnProductName() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
INSERT INTO ProductsBig (ProductName, Col1)
VALUES  ('Produto TV 50 com nome e código - 98872167', 'Alguma coisa'), 
        ('SAMSUNG UN50JS7200GXZD LED 50" UHD SMART 4X HDMI', 'TVs SAMSUNG'), 
        ('SAMSUNG UN32J4300AGXZD TV LED 32" HD SMART 2HDMI 1USB', 'TVs SAMSUNG')
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO

CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
GO
CREATE FULLTEXT INDEX ON ProductsBig(ProductName, Col1) KEY INDEX xpk_ProductsBig;
GO


-- Como buscar tudo que termina com *SUNG?


-- Termina com SUNG
-- Não funciona...
SELECT * FROM ProductsBig
WHERE CONTAINS(ProductName , '"*SUNG"')
GO

-- Adicionando coluna calculada...
ALTER TABLE ProductsBig 
ADD ProductNameReverse 
AS REVERSE(ProductName)
GO

-- Como fica a coluna REVERSE?
SELECT * FROM ProductsBig
WHERE ProductName LIKE '%SUNG%'
GO

-- É isso que queremos procurar
SELECT REVERSE('SUNG')
GO

-- Recriando o índice...
DROP FULLTEXT INDEX ON ProductsBig
CREATE FULLTEXT INDEX ON ProductsBig(ProductName, Col1, ProductNameReverse) KEY INDEX xpk_ProductsBig;
GO


-- Buscando o valor invertido...
DECLARE @ValorProcurado VARCHAR(200), @ValorInvertido VARCHAR(200)
SET @ValorProcurado = '"SUNG*"' 
SET @ValorInvertido = '"' + REVERSE('SUNG') + '*' + '"'
--SELECT @ValorInvertido

SELECT * FROM ProductsBig
WHERE CONTAINS((ProductName, ProductNameReverse), @ValorProcurado)
   OR CONTAINS((ProductName, ProductNameReverse), @ValorInvertido)
GO


--Limpa Banco
DROP FULLTEXT INDEX ON ProductsBig
DROP FULLTEXT CATALOG ftCatalog
GO

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


-- Query gera scan... mesmo que você tenha índice em ProductName
SELECT * FROM ProductsBig
WHERE ProductName like '%SMART%'
GO


CREATE FULLTEXT CATALOG ftCatalog AS DEFAULT;
GO
CREATE FULLTEXT INDEX ON ProductsBig(ProductName, Col1) KEY INDEX xpk_ProductsBig;
GO


-- Clausula CONTAINS pode ser utilizada para buscar as palavras...
-- Índice fulltext irá "cobrir" a query...
-- FulltextMath fazendo a mágica...
SELECT * FROM ProductsBig
WHERE CONTAINS(ProductName , '"LED"')
GO

-- Coringa... Começa com SAM... 
SELECT * FROM ProductsBig
WHERE CONTAINS(ProductName , '"SAM*"')
GO

-- Buscando em mais de uma coluna...
SELECT * FROM ProductsBig
WHERE CONTAINS((ProductName, Col1), '"TV*"')
GO


--Limpa Banco
DROP FULLTEXT INDEX ON ProductsBig
DROP FULLTEXT CATALOG ftCatalog
GO

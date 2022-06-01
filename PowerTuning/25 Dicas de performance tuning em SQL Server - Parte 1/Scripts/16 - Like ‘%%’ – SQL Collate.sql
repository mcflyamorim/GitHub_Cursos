USE Northwind
GO

-- 40 segundos para rodar...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 10000000 IDENTITY(Int, 1,1) AS ProductID, 
       CONVERT(VarChar(250),SubString(CONVERT(VarChar(250),NEWID()),1,8)) COLLATE Latin1_General_CI_AI AS ProductName, 
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


-- Collate do Windows Latin1_General_CI_AI 
-- Quando utilizando collate do windows, comparações de string utilizarão "Unicode sorting rules", 
---- mesmo que a coluna seja non-unicode (varchar, char, text e etc)
SET STATISTICS TIME ON
SELECT * FROM ProductsBig
WHERE ProductName like '%SMART%'
OPTION (MAXDOP 1)
SET STATISTICS TIME OFF
GO

-- Collate do SQL SQL_Latin1_General_CP1_CI_AS
-- Quando utilizando collate do SQL, comparações de string utilizarão um "Non-Unicode sorting rules"
SET STATISTICS TIME ON
SELECT * FROM ProductsBig
WHERE ProductName COLLATE SQL_Latin1_General_CP1_CI_AS like '%SMART%'
OPTION (MAXDOP 1)
SET STATISTICS TIME OFF
GO

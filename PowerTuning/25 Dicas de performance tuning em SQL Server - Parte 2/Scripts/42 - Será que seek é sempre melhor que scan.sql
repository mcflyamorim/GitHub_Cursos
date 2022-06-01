/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

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
CREATE INDEX ixProductName ON ProductsBig (ProductName)
GO
SET STATISTICS IO ON
GO


-- Aqui o SQL utiliza o índice corretamente
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE 'Guaraná Fantástica 0%'
OPTION (RECOMPILE, MAXDOP 1)
GO

-- SCAN... Porque? Seek é melhor !!!
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE 'Gua%'
OPTION (RECOMPILE, MAXDOP 1)
GO

-- ISSO... vamos FORÇAR... FAZ ISSO!!!!
SELECT * 
  FROM ProductsBig WITH(FORCESEEK)
 WHERE ProductName LIKE 'Gua%'
OPTION (RECOMPILE, MAXDOP 1)
GO

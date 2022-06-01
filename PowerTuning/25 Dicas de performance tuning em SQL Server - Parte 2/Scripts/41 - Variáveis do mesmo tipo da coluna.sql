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
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO


-- DROP INDEX ix_ProductName ON ProductsBig
CREATE INDEX ix_ProductName ON ProductsBig(ProductName)
GO

DECLARE @Nome NVarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO

DECLARE @Nome VarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO
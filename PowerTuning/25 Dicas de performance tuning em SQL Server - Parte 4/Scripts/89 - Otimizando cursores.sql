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
--------------------------------------
------------- Cursores ---------------
--------------------------------------

-- Teste 1
-- Exemplo cursor

-- Cursor padrão 
SET NOCOUNT ON
DECLARE cCursor CURSOR
    FOR SELECT ProductName
   FROM ProductsBig

DECLARE @Nome VARCHAR(200)
   OPEN cCursor
  FETCH NEXT FROM cCursor INTO @Nome

WHILE @@FETCH_STATUS = 0
BEGIN
  FETCH NEXT FROM cCursor INTO @Nome
END

CLOSE cCursor
DEALLOCATE cCursor
GO
GO


-- Lembre-se de utilizar a clausula FAST_FORWARD
SET NOCOUNT ON
DECLARE cCursor CURSOR FAST_FORWARD
    FOR SELECT ProductName
   FROM ProductsBig

DECLARE @Nome VARCHAR(200)
   OPEN cCursor
  FETCH NEXT FROM cCursor INTO @Nome

WHILE @@FETCH_STATUS = 0
BEGIN
  FETCH NEXT FROM cCursor INTO @Nome
END

CLOSE cCursor
DEALLOCATE cCursor
GO

/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO
/*
  Index Seek
*/

/*
  Seek é utilizado quando é possível navegar pela árvore
  balanceada do índice
*/
IF EXISTS(SELECT * FROM sysindexes WHERE name = 'ix_ProductName' and id = OBJECT_ID('ProductsBig'))
  DROP INDEX ix_ProductName ON ProductsBig
GO
CREATE INDEX ix_ProductName ON ProductsBig(ProductName) INCLUDE(Col1)
GO

-- Ex: Non-Clustered Index Seek
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE 'Guaraná Fantástica 073E0D7E'
OPTION (RECOMPILE, MAXDOP 1)

/*
  Quando um Index Seek é na verdade um Index Scan
*/


-- Aqui o SQL utiliza o índice corretamente
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE 'Guaraná Fantástica 07%'
OPTION (RECOMPILE, MAXDOP 1)
GO

-- Já quando utilizamos o % no começo da strig o 
-- SQL não faz o seek
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE '%Guaraná Fantástica 07%'
OPTION (RECOMPILE, MAXDOP 1)
GO

IF OBJECT_ID('st_RetornaProductsBig', 'P') IS NOT NULL
  DROP PROC st_RetornaProductsBig
GO
CREATE PROC st_RetornaProductsBig @vProductName VarChar(250)
WITH RECOMPILE
AS
BEGIN
  SELECT * 
    FROM ProductsBig
   WHERE ProductName LIKE @vProductName
END
GO

-- Utiliza o índice
EXEC dbo.st_RetornaProductsBig '%Guaraná Fantástica 07%'


-- Continua usando índice e fazendo o seek
-- Mas está fazendo um scan nas páginas do índice, compare a quantidade de 
-- páginas para fazer o scan vs o seek do comando abaixo
SET STATISTICS IO ON
EXEC dbo.st_RetornaProductsBig '%Guaraná Fantástica 07%'
GO
SELECT * 
  FROM ProductsBig
 WHERE ProductName LIKE '%Guaraná Fantástica 07%'
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF
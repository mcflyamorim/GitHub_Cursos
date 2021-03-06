/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/


-- Pode isso Arnaldo?

-- 1.
-- Funciona!
SELECT * FROM Products
GO
-- E esse funciona?
SELECT * FROM Products
G


-- 2.
-- Qual é o resultado desta consulta?
SELECT d.c-d.b+d.a 
  FROM (SELECT 1 c,2 b,5 a) AS d(a,b,c)


-- 3.
-- Porque o código abaixo não funciona?
-- Retorna "1"
SELECT 1
 WHERE 'TesteCódigo' LIKE '%' + 

-- Não retorna nada
DECLARE @Str VarChar
SET @Str = 'TesteCódigo'
SELECT 1
 WHERE 'TesteCódigo' LIKE '%' + @Str
GO


-- 4. Rodada dupla. Comando do create table roda ou gera um erro?
 CREATE TABLE Tab1(Col1 Int, Col2 Int,)
CREATE TABLE Tab2asd(Col1 Int, Col2 Int,)
-- Drop table com , ?
DROP TABLE Tab1, Tab2

--5.
-- Roda ou gera um erro?
SELECT * FROM dbo    .   Products

--6. Funciona?
SELECT 1.NomeDaColuna
-- E esse?
SELECT 'UmValor'.NomeDaColuna

--7. WTF?
DECLARE @Tab TABLE ("SELECT" Int, "*" Int, "FROM" Int, "@Tab" Int, "WHERE" Int, "ORDER BY" Int)

SELECT "SELECT", "*", *, 
 "FROM", "@Tab" 
  FROM @Tab
 WHERE "WHERE" = "ORDER BY"
 ORDER BY "ORDER BY"

-- 8.
-- Rodada dupla, Qual é o nome da variável? Qual vai ser o resultado, Sim ou Não?
DECLARE @ int
SET @ = 10
PRINT @@ROWCOUNT
IF @@ROWCOUNT = 1
  PRINT 'Sim'
ELSE
  PRINT 'Não'
PRINT @@ROWCOUNT
GO

-- Print seta rowcount para zero
SELECT '1 row';
SELECT @@ROWCOUNT;
PRINT 'Set rowcount to zero';
SELECT @@ROWCOUNT;


-- 9
-- Qual é o resultado dos selects abaixo? 
SELECT LEN('A')
SELECT DATALENGTH('A')
GO
SELECT LEN(N'黄')
SELECT DATALENGTH(N'黄')
GO
SELECT LEN(N'𠮷')
SELECT DATALENGTH(N'𠮷')
GO
SELECT LEFT(N'𠮷', 1)
GO
SELECT LEFT(N'𠮷' COLLATE Latin1_General_100_CS_AS_SC, 1) -- SQL2012
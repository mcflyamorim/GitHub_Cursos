-- Dicas do mestre Itzik em 
-- https://sqlperformance.com/2019/10/t-sql-queries/overlooked-t-sql-gems

USE Northwind
GO

-- TRIM no SQL2017, é muito mais que apenas remover espaço em branco do começo e do fim... 
-- :-) 

-- O uso básico, de fato é esse...
DECLARE @i AS VARCHAR(200) = '   Alguma coisa    ';
SELECT '[' + TRIM(@i) + ']'
GO


-- Porém, é possível, especificar o que você quer remover no começo e fim...
-- Sintax = TRIM ( [ characters FROM ] string )

DECLARE @i AS VARCHAR(200) = '*****Alguma coisa*****';
SELECT '[' + TRIM('*' FROM @i) + ']'
GO
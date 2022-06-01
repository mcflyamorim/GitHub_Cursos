-- Dicas do mestre Itzik em 
-- https://sqlperformance.com/2019/10/t-sql-queries/overlooked-t-sql-gems

USE Northwind
GO

-- Digamos que eu tenha uma fórmula com a seguinte expressão:
-- 2 * [3+4] / {7-2} 
-- Preciso trocar o [] pra () e {} pra ()

-- Eu poderia fazer assim:
DECLARE @i AS VARCHAR(200) = '2 * [3+4] / {7-2}';
SELECT REPLACE(REPLACE(REPLACE(REPLACE(@i,'[','('),']',')'),'{','('),'}',')');
GO


-- Ou desde o SQL2017 da pra usar a função TRANSLATE ( inputString, characters, translations )
DECLARE @i AS VARCHAR(200) = '2 * [3+4] / {7-2}';
SELECT TRANSLATE(@i, '[]{}', '()()');
GO

-- Ou seja, se eu quiser trocar A por 1, B por 2, C por 3 e D por 4, posso fazer assim: 
DECLARE @i AS VARCHAR(200) = 'a.b.c.d';
SELECT TRANSLATE(@i, 'abcd', '1234');
GO
/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Densidade
*/

/*
  Criando base para testes
*/
IF OBJECT_ID('Test') IS NOT NULL
  DROP TABLE Test
GO
CREATE TABLE Test(Col1 INT)
GO
DECLARE @i INT
SET @I = 0

WHILE @i < 5000
BEGIN
  INSERT INTO Test VALUES(@i)
  INSERT INTO Test VALUES(@i)
  INSERT INTO Test VALUES(@i)
  INSERT INTO Test VALUES(@i)
  INSERT INTO Test VALUES(@i)
  SET @i = @i + 1
END
GO

CREATE STATISTICS Stat ON Test(Col1)
GO

-- Tabela com 25 mil linhas e 5 mil valores distintos
-- Cada valor repete 5 vezes
SELECT * FROM Test

/*
  Calculando a densidade da coluna
  1.0 / 5000 = 0.0002
*/ 
SELECT 1. / COUNT(DISTINCT Col1) 
  FROM Test
-- Resultado: 0.00020000000

/*
  Com este valor quais as informações podemos responder?
  
  1 - Quantos valores distintos temos na coluna Col1?
  R: Fácil. 1.0 / 0.0002 = 5000
  
  2 - Qual é a média de valores duplicados na coluna Col1?
  R: Fácil. 0.0002 * 25000 = 5
  
  Onde o SQL utiliza isso?
*/

/*
  Caso eu utiize uma variável o SQL Não consegue utilizar o 
  histograma para estimar quantas linhas serão retornadas.
  Neste caso ele utiliza densidade para calcular a média 
  de valores distintos como estimativa.
  O que neste caso foi perfeito.
*/
DECLARE @i Integer
SET @i = 2000
SELECT *
  FROM Test
 WHERE Col1 = @i


/*
  Quantas linhas existem para cada grupo?
  
  Abaixo o SQL usa a informação da densidade para estimar
  quantas linhas distintas serão retornadas para cada grupo
*/
SELECT Col1, COUNT(*)
  FROM Test
 GROUP BY Col1
 ORDER BY Col1
 
/*
  Abaixo em uma consulta mais simples o SQL também utiliza
  a densidade para analisar quantas linhas distintas serão 
  retornadas após a agregação
*/
SELECT DISTINCT Col1
  FROM Test
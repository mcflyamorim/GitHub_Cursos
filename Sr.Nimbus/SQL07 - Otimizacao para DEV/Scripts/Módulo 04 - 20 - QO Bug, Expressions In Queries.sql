/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE tempdb
GO
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
BEGIN
  DROP TABLE #TMP
END
GO

-- Criar uma tabela para teste com uma coluna VarChar
CREATE TABLE #TMP (ID   Integer PRIMARY KEY,
                   Col1 VarChar(25),
                   Col2 VarChar(500) DEFAULT NEWID())
GO

-- Inserir alguns Valuees Inteiros e uma String
INSERT INTO #TMP (ID, Col1) VALUES (1, 1),(2,2),(3,3),(4,4),(5,5),(7,7), (8,8), (9,9), (10,10)

-- Preciso incluir a string separado pois o row constructor 
-- nao consegue inserir os dados de tipos diferentes na mesma instrucao
INSERT INTO #TMP (ID, Col1) VALUES (6, 'X Erro')
GO

/*
  Se eu quiser pegar somente as linhas que contem número
  e somente as linhas com Col1 menor que 10
  Posso usar a IsNumeric = 1 no where
  O código abaixo esta perfeito
*/
SELECT * 
  FROM #TMP
 WHERE IsNumeric(Col1) = 1
   AND Col1 <= 10
/*
  Cuidado com IsNumeric:
  SELECT IsNumeric(Char(9)), 
         IsNumeric('$'),
         IsNumeric('.'),
         IsNumeric(',')
*/

/*
  Mas e seu eu somente inverter a ordem das colunas no where?
  
  Resultado:
  Msg 245, Level 16, State 1, Line 1
  Conversion failed when converting the varchar value 'X Erro' to data type int.
  
  O SQL Server não garante que a ordem das expressões será 
  efetuada corretamente. Na verdade ele não garante que o
  filtro será efetuado em nenhuma ordem, ele decide em
  qual ordem o filtro será efetuado.  
*/
SELECT Col1
  FROM #TMP
 WHERE Col1 <= 10
   AND IsNumeric(Col1) = 1
GO

/* 
  Mesmo que você passe o filtro do IsNumeric em uma subquery
  e depois faça outro filtro por Col1, isso não garante a ordem
  da execução.
*/
SELECT * 
  FROM (SELECT * 
          FROM #TMP 
         WHERE IsNumeric(Col1) = 1) Tab 
 WHERE Col1 <= 10

/*
  Uma das maneiras de forçar a ordem dos filtros é
  utilizando CASE.
  Neste caso a ordem das expressões no case será 
  a ordem de execução do filtro
  Por ex: a consulta abaixo esta correta
*/
SELECT * 
  FROM #TMP
 WHERE CASE 
         WHEN (IsNumeric(Col1) = 1) AND (Col1 <= 10) THEN 1
         ELSE 0 
       END = 1

/* 
  Já a consulta abaixo não esta correta, pois primeiro o SQL irá 
  avaliar o Col1 <=10 e depois o IsNumeric, o que gera o erro de
  conversão.
*/
SELECT * 
  FROM #TMP
 WHERE CASE 
         WHEN (Col1 <= 10) AND (IsNumeric(Col1) = 1) THEN 1
         ELSE 0 
       END = 1
       
/*
  Case nem sempre garante a ordem das consultas
  http://bartduncansql.wordpress.com/2011/03/03/dont-depend-on-expression-short-circuiting-in-t-sql-not-even-with-case/
*/

/*
  Outra alternativa seria quebrar as consultas, 
  fazer o Filtro por IsNumeric, jogar em uma temp
  E depois fazer o filtro por Col1 <= 10
*/


/*
  Para demostrar outro exemplo vamos criar 
  um novo cenário
*/

USE tempdb
GO
IF OBJECT_ID('#Tab1','U') IS NOT NULL
  DROP TABLE #Tab1
GO
IF OBJECT_ID('#Tab2','U') IS NOT NULL
  DROP TABLE #Tab2
GO
CREATE TABLE #Tab1(Col1 Int, Col2 VarChar(30))
CREATE TABLE #Tab2(Col1 Int)
GO
INSERT INTO #Tab1 VALUES (0, '0')
INSERT INTO #Tab1 VALUES (1, '1')
INSERT INTO #Tab1 VALUES (99, 'X Erro')
GO
INSERT INTO #Tab2 VALUES (1)
INSERT INTO #Tab2 VALUES (2)
INSERT INTO #Tab2 VALUES (3)
INSERT INTO #Tab2 VALUES (4)
INSERT INTO #Tab2 VALUES (5)
GO

/*
  No código abaixo a conversão da coluna #Tab1.Col2 é executada 
  antes do Join, o que gera um erro no ID 99.
  O grande problema é que este código não gera erro no SQL Server 2000
  Nota: Rodar no SQL 2000
*/
SELECT #Tab1.Col1,
       CONVERT(Integer, #Tab1.Col2) AS Col2
  FROM #Tab1
 INNER JOIN #Tab2
    ON #Tab1.Col1 = #Tab2.Col1


-- Neste caso, incluir a validação pelo IsNumeric já resolveria o problema
SELECT #Tab1.Col1,
       CONVERT(Integer, #Tab1.Col2) AS Col2
  FROM #Tab1
 INNER JOIN #Tab2
    ON #Tab1.Col1 = #Tab2.Col1
 WHERE IsNumeric(#Tab1.Col2) = 1

-- Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/125880/where-clauses-are-evaluated-in-wrong-order-with-subqueries-or-view-as-source#details
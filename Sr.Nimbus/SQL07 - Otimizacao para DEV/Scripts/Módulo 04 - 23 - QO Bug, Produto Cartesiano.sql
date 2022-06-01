/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE tempdb
GO
IF OBJECT_ID('tempdb.dbo.#tab1') IS NOT NULL
  DROP TABLE #tab1
GO
CREATE TABLE #tab1 (a INT)
GO

-- Script para incluir 1000 linhas com um Value único "1"
INSERT INTO #tab1
SELECT TOP 1000 1
  FROM sysobjects b, sysobjects a
GO

SET STATISTICS IO ON
GO
-- Faz um join com a tabela #tab1 para retornar 1 milhão de linhas
SELECT * 
  FROM #tab1 a
 INNER JOIN #tab1 b
    ON a.a = b.a
/*

Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table '#tab1__000000000002'. Scan count 2, logical reads 4, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

Execution Plan:
|--Hash Match(Inner Join, HASH:([a].[a])=([b].[a]), RESIDUAL:([tempdb].[dbo].[#tab1].[a] as [b].[a]=[tempdb].[dbo].[#tab1].[a] as [a].[a]))
     |--Table Scan(OBJECT:([tempdb].[dbo].[#tab1] AS [a]))
     |--Table Scan(OBJECT:([tempdb].[dbo].[#tab1] AS [b]))
*/

/*
  Mesma consulta, mas agora gerando um plano BEM pior.
  O que aconteceu aqui é que o SQL fez um produto cartesiano.
  Por conta própria. Ele achou que deveria fazer isso e fez. :-)
  Mas temos um problema, um produto carteziano só pode ser feito
  via loop join. 
  E processar esta consulta via Loop Join é MUITO pior do que 
  fazer o hash join.
  A lógia é a seguinte: se a.a é igual a b.a e, a.a é igual a "1"
  então b.a também é igual a "1". Certo?.
  Com esta informação ele não faz o join, mas simplesmente aplica
  dois o filtro de a.a=1 e b.a=1.
*/ 
SELECT * 
  FROM #tab1 a
 INNER JOIN #tab1 b
    ON a.a = b.a
 WHERE a.a = 1
/*
Table 'Worktable'. Scan count 1, logical reads 6006, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table '#tab1_000000000002'. Scan count 2, logical reads 4, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

Execution Plan:
|--Nested Loops(Inner Join)
     |--Table Scan(OBJECT:([tempdb].[dbo].[#tab1] AS [a]), WHERE:([tempdb].[dbo].[#tab1].[a] as [a].[a]=(1)))
     |--Table Spool
          |--Table Scan(OBJECT:([tempdb].[dbo].[#tab1] AS [b]), WHERE:([tempdb].[dbo].[#tab1].[a] as [b].[a]=(1)))
*/

-- E seu eu for mais esperto e forçar o HASH JOIN?
SELECT *
  FROM #tab1 a
 INNER JOIN #tab1 b
    ON a.a = b.a
 WHERE a.a = 1
OPTION (HASH JOIN)
/*
Msg 8622, Level 16, State 1, Line 1
Query processor could not produce a query plan because of the hints defined in this query. 
Resubmit the query without specifying any hints and without using SET FORCEPLAN.
*/

SET STATISTICS IO OFF

-- Oracle tem um parâmetro pra isso :-(
-- http://jonathanlewis.wordpress.com/2006/12/13/cartesian-merge-join/

-- Related Connect Item: https://connect.microsoft.com/SQLServer/feedback/ViewFeedback.aspx?FeedbackID=420856&wa=wsignin1.0
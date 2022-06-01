/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO
/*
  Optimizer Rules
*/

/*
  Nota Geek:
  DBCC Originalmente significava, Database Consistency Check
  Agora significa DBCC Database Console Commands
*/

/*
  Nota do Books Online
  Note: The sys.dm_exec_query_transformation_stats dynamic management view is 
  identified for informational purposes only. Not supported. 
  Future compatibility is not guaranteed.
*/

SELECT * FROM sys.dm_exec_query_transformation_stats;
GO

/*
name: ContactName interno da regra aplicada no plano
promise_total: Soma de todos os valores prometidos
promise_avg: promise_total dividido por promised
promised: Quantas vezes a regra foi solicitada para prover um Value para o optimizer
built_substitute: Quantas vezes uma regra foi utilizada como possível alternativa 
                  para implementar alguma função.
succeeded: Quantidade de vezes em que uma regra gerou uma transformação 
           que foi utilizada com successo.
*/


/*
  Utilizando a DMV sys.dm_exec_query_transformation_stats;
*/
IF OBJECT_ID('tempdb.dbo.#Snapshot') IS NOT NULL
  DROP TABLE #Snapshot
GO
SELECT *
  INTO #Snapshot
  FROM sys.dm_exec_query_transformation_stats
GO

/* COMANDO SQL */
SELECT OrderID,
       Value
  FROM Orders Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM Orders Ped2
                   WHERE Ped2.OrderDate = '20090101'
                     AND Ped2.Value > 100)
OPTION (RECOMPILE)
GO
-- Results
SELECT QTS.name,
       QTS.promised - S.promised AS promised,
       CASE 
         WHEN QTS.promised = S.promised THEN 0
         ELSE (QTS.promise_total - S.promise_total)/(QTS.promised - S.promised)
       END promise_value_avg,
       QTS.built_substitute - S.built_substitute AS built_substitute,
       QTS.succeeded - S.succeeded AS succeeded
  FROM #Snapshot S
 INNER JOIN sys.dm_exec_query_transformation_stats QTS
    ON QTS.name = S.name
 WHERE QTS.succeeded <> S.succeeded
 ORDER BY promise_value_avg DESC
OPTION  (KEEPFIXED PLAN);
GO

-- Comandos não documentados para trabalhar com as regras
DBCC TRACEON (2588)
DBCC HELP ('RULEON')
DBCC HELP ('RULEOFF')
DBCC HELP ('SHOWONRULES')
DBCC HELP ('SHOWOFFRULES')
DBCC TRACEOFF (2588)

-- Mostra todas as regras ativas
DBCC TRACEON (3604)
DBCC SHOWONRULES

-- Mostra todas as regras inativas
DBCC SHOWOFFRULES

-- Habilita alguma regra
DBCC RULEON('')

-- Desabilita alguma regra
DBCC RULEOFF('')

/*
  Teste dos Comandos
*/

IF OBJECT_ID('tempdb.dbo.#Snapshot') IS NOT NULL
  DROP TABLE #Snapshot
GO
SELECT *
  INTO #Snapshot
  FROM sys.dm_exec_query_transformation_stats
GO
-- Desabilitar o uso do Spool
DBCC RULEOFF('BuildSpool')

/* COMANDO SQL */
SELECT OrderID,
       Value
  FROM Orders Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM Orders Ped2
                   WHERE Ped2.OrderDate = '20090101'
                     AND Ped2.Value > 100)
OPTION (RECOMPILE)

-- Habilitar o uso do Spool
DBCC RULEON('BuildSpool')
GO
-- Results
SELECT QTS.name,
       QTS.promised - S.promised AS promised,
       CASE 
         WHEN QTS.promised = S.promised THEN 0
         ELSE (QTS.promise_total - S.promise_total)/(QTS.promised - S.promised)
       END promise_value_avg,
       QTS.built_substitute - S.built_substitute AS built_substitute,
       QTS.succeeded - S.succeeded AS succeeded
  FROM #Snapshot S
 INNER JOIN sys.dm_exec_query_transformation_stats QTS
    ON QTS.name = S.name
 WHERE QTS.succeeded <> S.succeeded
 ORDER BY promise_value_avg DESC
GO


-- Exemplo 2

-- Mais de 64 valores no IN rule ConstGetToConstScan gera join com ConstantScan
SELECT *
  FROM CustomersBig
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,
                      11,12,13,14,15,16,17,18,19,20,
                      21,22,23,24,25,26,27,28,29,30,
                      31,32,33,34,35,36,37,38,39,40,
                      41,42,43,44,45,46,47,48,49,50,
                      51,52,53,54,55,56,57,58,59,60,
                      61,62,63,64, 65)
GO

-- Desabilitar a regra de envio de valores do in para constant scan
DBCC RULEOFF('ConstGetToConstScan')

SELECT * 
  FROM CustomersBig
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,
                      11,12,13,14,15,16,17,18,19,20,
                      21,22,23,24,25,26,27,28,29,30,
                      31,32,33,34,35,36,37,38,39,40,
                      41,42,43,44,45,46,47,48,49,50,
                      51,52,53,54,55,56,57,58,59,60,
                      61,62,63,64, 65)
OPTION (RECOMPILE)

DBCC RULEON('ConstGetToConstScan')


-- Update 24-10-2012
-- Novo Hint QueryRuleOff = http://somewheresomehow.ru/

SELECT OrderID,
       Value
  FROM Orders Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM Orders Ped2
                   WHERE Ped2.OrderDate = '20090101'
                     AND Ped2.Value > 100)
OPTION (RECOMPILE, QueryRuleOff BuildSpool)
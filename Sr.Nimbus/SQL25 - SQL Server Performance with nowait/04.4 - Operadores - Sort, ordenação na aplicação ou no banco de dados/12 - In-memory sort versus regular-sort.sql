/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-----------------------------------
-- In-memory sort / regular-sort --
-----------------------------------

-- Top N Sort
-- Até 100 linhas algoritmo otimizado para retornar n linhas rapidamente
SELECT TOP 100
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Variável não utiliza "Top N SORT"
-- TOP N Sort SEMPRE utiliza algoritmo não otimizado para poucas linhas (algoritmo padrao)
-- Plano abaixo gera SortWarning
DECLARE @i Int = 100
SELECT TOP (@i)
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1)
GO

-- "Top N SORT"
-- TOP N Sort utilizando algoritmo padrao, query abaixo gera sort warning
SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO



-- Resposta: Algoritmo de TOP N Sort é diferente para valores
-- maiores que 100.

-- Alternativa 1
-- Minimizar a quantidade de bytes que serão processados pelo operador de sort
SELECT TOP 101
       Tab1.CustomerID,
       CustomersBig.CityID,
       CustomersBig.CompanyName,
       CustomersBig.ContactName,
       Tab1.Col1,
       CustomersBig.Col2
  FROM CustomersBig
 INNER JOIN (SELECT TOP 101 CustomerID, Col1 
               FROM CustomersBig 
              ORDER BY Col1) AS Tab1
    ON CustomersBig.CustomerID = Tab1.CustomerID
 ORDER BY CustomersBig.Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Alternativa 2, criando um índice para evitar o Sort
-- DROP INDEX ix1 ON CustomersBig
CREATE INDEX ix1 ON CustomersBig (Col1)
GO
SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO
DROP INDEX ix1 ON CustomersBig
GO

-- Alternativa 3, alterar tamanho do Memory Grant Workspace
-- utilizando Resource Governor
ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=50)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Voltar ao normal
ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=25)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

/*
  Memory Grant insuficiente
*/

-- ALTER TABLE ProductsBig DROP COLUMN ColTest
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL
GO

-- Consulta roda em 0 segundos
-- Não gera sort warning
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2000
 ORDER BY ColTest
OPTION (RECOMPILE)

-- Consulta roda em 0 segundos
-- Grant de memória para execução da consulta não foi suficiente
-- Gera sort warning
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2800
 ORDER BY ColTest
OPTION (RECOMPILE)

-- Esse sort warning é tão ruim assim?
-- Teste com SQLQueryStress

-- Como fazer para aumentar a quantidade de memória reservada para o plano?
-- Mentir sobre o tamanho da coluna
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2800
 ORDER BY CONVERT(VarChar(5000), ColTest)
OPTION (RECOMPILE)

-- Como fica com OptimizeFor? 
DECLARE @i Int = 2800
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND @i
 ORDER BY ColTest
OPTION (MAXDOP 1, RECOMPILE, OPTIMIZE FOR (@i = 50000))


-- Qual é o problema em mentir sobre a quantidade de memória utilizada pelos planos ?

-- SQLQueryStress + sp_whoisactive para ver os waits por RESOURCE_SEMAPHORE
-- Perfmon: SQL Server:Memory Manager/Memory Grants Pending


-- TF 7470
-- SQL2014 SP1 CU3 - Released on October 19, 2015 https://support.microsoft.com/kb/3094221
-- SQL2012 SP2 CU8 https://support.microsoft.com/en-us/kb/3082561
-- FIX: Sort operator spills to tempdb in SQL Server 2012 or SQL Server 2014 
-- when estimated number of rows and row size are correct
-- https://support.microsoft.com/en-us/kb/3088480 -- Fix3088480
SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2800
 ORDER BY ColTest
OPTION (RECOMPILE, QueryTraceOn 7470)


/*
  Mais detalhes sobre Memory Grant WorksSpace no "Internals On-Demand"
*/


/*
  Notas: 
  2746 = Bom
  2747 = Ruim
*/
/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

use TestBatchSort
GO

-- Usar AsusLogics Disk Defrag para ver os fragmentos

-- Perfmon: 
--   Colectar contador de leitura do disco: 
--   Disk Reads Bytes/Sec

-- Usar ProcessMonitor para ver informações sobre requisições de I/O enviadas pelo SQL Server


/*
    ------------------------------------------------------
    ------------------------------------------------------
     Primeiro exemplo, QO cria um plano com um operador 
     de SORT explícito pela coluna ID para evitar leituras 
     aleatórias no índice cluster
    ------------------------------------------------------
    ------------------------------------------------------
*/

-- Query 1 - Plano com Sort explícito
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC TRACEON(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- Média de 6 segundos para rodar
-- Utiliza Optimize for para simular leitura de várias linhas... 
-- e forçar estimativa incorreta pelo QO
DECLARE @i Int = 1000
SELECT TOP (@i) 
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, OPTIMIZE FOR (@i = 1000000))
GO
DBCC TRACEOFF(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO

-- Query 2 -  Plano sem Sort explícito e sem Batch Sort...
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC TRACEON(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- Média de 21 segundos para rodar
DECLARE @i Int = 1000
SELECT TOP (@i) 
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, OPTIMIZE FOR (@i = 0))
GO
DBCC TRACEOFF(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO


/*
    ------------------------------------------------------
    ------------------------------------------------------
      Teste de performance... 
      Comparando um plano OTIMIZED (com batch sort) contra 
      um plano non-OPTIMIZED.
    ------------------------------------------------------
    ------------------------------------------------------
*/

-- Query 1 - Non-Optimized query plan
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC RULEOFF('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
DBCC TRACEON(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- Média de 1:00 mins para rodar
DECLARE @i Int = 2000
SELECT TOP (@i) 
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN, OPTIMIZE FOR (@i = 10000))
GO
DBCC TRACEOFF(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
DBCC RULEON('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
GO

-- Query 2 - Optimized query plan
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC RULEOFF('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- Média de 18 segundos para rodar
DECLARE @i Int = 2000
SELECT TOP (@i)
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN, OPTIMIZE FOR (@i = 10000))
GO
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
DBCC RULEON('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
GO


-- Query 3 - Non-Optimized query plan lendo todas as linhas da tabela (3200000 linhas)
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC RULEOFF('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
DBCC TRACEON(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- 12:31 mins to run
DECLARE @i Int = 3200000
SELECT TOP (@i) 
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN, OPTIMIZE FOR (@i = 3200000))
GO
DBCC TRACEOFF(2340) WITH NO_INFOMSGS -- disable BatchSort (TF 2340) (optimized = false) 
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
DBCC RULEON('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
GO

-- Query 4 - Optimized query plan reading 3200000 rows
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DBCC RULEOFF('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
DBCC TRACEON(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
GO
-- 1:03 mins to run
DECLARE @i Int = 3200000
SELECT TOP (@i)
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN, OPTIMIZE FOR (@i = 3200000))
GO
DBCC TRACEOFF(8744) WITH NO_INFOMSGS -- disable Prefetch (TF 8744)
DBCC RULEON('EnforceSort') WITH NO_INFOMSGS -- Avoid explicity sort otimization in the plan
GO

/*
    ------------------------------------------------------
    ------------------------------------------------------
      Se a tabela for pequena não habilita batch sort
      Usa memória disponível para servidor para medir o
      que é uma "tabela pequena"
      Tem que ser 1% maior que a memória disponível para
      o servidor.
    ------------------------------------------------------
    ------------------------------------------------------
*/

-- Digamos que o serivdor tenha 1GB de memória disponível

EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO

-- 1% de 1048576KB (1GB) é igual a 10485KB
-- Ou seja, apenas tabelas maiores que 10485KB terão planos Optimized = True (com BatchSort)
-- Em outras palavras, apenas tabelas com mais de 1310 páginas de dados (SELECT ((1048576 * 1) / 100) / 8)

-- Retorna quantidade de páginas da tabela
DBCC SHOW_STATISTICS (TestTab1) WITH STATS_STREAM
/*
  Stats_Stream	Rows	   Data Pages
  NULL	        3200000	3200000
*/

-- Finge que a tabela tem apenas 1309 páginas (1 página a menos que os 1% de memória)
UPDATE STATISTICS TestTab1 WITH PAGECOUNT = 1309
GO
DBCC OPTIMIZER_WHATIF(2, 1024);

-- Tenta gerar plano com Optimized = True
SELECT *
  FROM TestTab1 WITH(index=ix_Col4)
 WHERE ID < 100
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Aumentar o tamanho da tabela para 1311 páginas (exatamente 1 página a mais que 1% da memória disponível)
UPDATE STATISTICS TestTab1 WITH PAGECOUNT = 1311
GO

-- Tenta gerar plano com Optimized = True
SELECT *
  FROM TestTab1 WITH(index=ix_Col4)
 WHERE ID < 100
OPTION (MAXDOP 1, RECOMPILE)


-- OPTIMIZER_WHATIF podemos alterar a quantidade de memória disponível para
-- o SQL Server (altera apenas o que o QO enxerga)
DBCC OPTIMIZER_WHATIF(2, 1024);


-- Scripts util
/*
  DBCC TRACEON(652) WITH NO_INFOMSGS -- TF to disable read a-head
  DBCC TRACEON(2340) WITH NO_INFOMSGS -- TF to disable batch sort
  DBCC TRACEON(8744) WITH NO_INFOMSGS -- TF to disable prefetching

  --SQLIO 
  sqlio.exe -kR -t16 -dC -s1200 -b64

  EXEC sys.sp_configure N'max server memory (MB)', N'256'
  GO
  RECONFIGURE WITH OVERRIDE
  GO


  EXEC sys.sp_configure N'max server memory (MB)', N'1024'
  GO
  RECONFIGURE WITH OVERRIDE
  GO


  WHILE 1=1
    DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS

*/

  http://blogs.msdn.com/b/psssql/archive/2010/01/11/high-cpu-after-upgrading-to-sql-server-2005-from-2000-due.aspx 
  http://blogs.msdn.com/b/craigfr/archive/2009/03/18/optimized-nested-loops-joins.aspx
  http://blogs.msdn.com/b/craigfr/archive/2009/02/25/optimizing-i-o-performance-by-sorting-part-1.aspx
  http://blogs.msdn.com/b/craigfr/archive/2009/03/04/optimizing-i-o-performance-by-sorting-part-2.aspx
*/
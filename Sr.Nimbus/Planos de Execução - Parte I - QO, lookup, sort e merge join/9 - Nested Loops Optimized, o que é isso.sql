/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-------------------------------
--------- Batch Sort ----------
-------------------------------
USE TestBatchSort
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
-- Média de 4 segundos para rodar
-- Utiliza Optimize para forçar estimativa incorreta
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DECLARE @i Int = 1000
SELECT TOP (@i) *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, 
        OPTIMIZE FOR (@i = 5000000),
        QueryTraceON 2340) -- Desabilitar BatchSort
GO

-- Query 2 -  Plano sem Sort explícito e sem Batch Sort...
-- Média de 23 segundos para rodar
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DECLARE @i Int = 1000
SELECT TOP (@i)
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, 
        OPTIMIZE FOR (@i = 0),
        QueryTraceON 2340) -- Desabilitar BatchSort
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
-- Média de 26 segundos para rodar
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DECLARE @i Int = 1000
SELECT TOP (@i) 
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, 
        OPTIMIZE FOR (@i = 100000),
        QueryTraceON 2340) -- Desabilitar BatchSort
GO

-- Query 2 - Optimized query plan
-- Média de 7 segundos para rodar
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
DECLARE @i Int = 1000
SELECT TOP (@i)
       *
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (RECOMPILE, 
        OPTIMIZE FOR (@i = 100000))
GO



-- Query 3 - Optimized query plan lendo todas as linhas da tabela (2900000 linhas)
-- 43 minutos para rodar
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT COUNT(Col3)
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, 
        QueryRuleOff EnforceSort, -- Evitar sort explicito no plano
        QueryTraceON 8744) -- Desabilitar Prefetch
GO

-- Query 4 - Non-Optimized query plan lendo todas as linhas da tabela (2900000 linhas)
-- 11 horas e 52 minutos para rodar...
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT COUNT(Col3)
  FROM TestTab1 WITH(index=ix_Col4)
OPTION (MAXDOP 1, RECOMPILE, 
        QueryRuleOff EnforceSort, -- Evitar sort explicito no plano
        QueryTraceON 8744, -- Desabilitar Prefetch
        QueryTraceON 2340) -- Desabilitar BatchSort
GO

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
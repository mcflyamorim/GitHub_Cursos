/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Preparar ambiente... Criar tabelas com 5 milhões de linhas...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 5000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Query para teste
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL 
  DROP TABLE #TMP
GO
SELECT *
  INTO #TMP 
  FROM OrdersBig
OPTION (MAXDOP 1)
GO


-- Rodar um nova sessão
-- Ver status das operações do plano
SELECT * FROM sys.dm_exec_query_profiles
GO

-- Porque não funciona? 


-- Porque a query precisa estar com plano de execução ATUAL ligado!
SET STATISTICS XML ON;
GO
-- Query para teste
-- Detalhe do SCAN e INSERT sendo executados ao mesmo tempo...
-- conforme linhas são retornadas do scan, insert já acontece...
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL 
  DROP TABLE #TMP
GO
SELECT *
  INTO #TMP 
  FROM OrdersBig
OPTION (MAXDOP 1)
GO
SET STATISTICS XML OFF;
GO

-- Mais e se eu não posso alterar a query?

-- xEvents... (com precaução!)
IF EXISTS (SELECT 1 FROM sys.server_event_sessions 
            WHERE name = 'xEvent_CapturaPlano')
BEGIN
  DROP EVENT SESSION xEvent_CapturaPlano ON SERVER
END
GO
CREATE EVENT SESSION xEvent_CapturaPlano ON SERVER 
ADD EVENT sqlserver.query_post_execution_showplan 
ADD TARGET package0.ring_buffer
WITH (STARTUP_STATE=OFF)
GO
-- Inicia evento...
ALTER EVENT SESSION xEvent_CapturaPlano
ON SERVER
STATE=START;
GO


-- Query para teste
-- Inserir operador de "blocking" para ver query "parando no operador"...
-- Agora sort precisa de todas as linhas pro processo continuar...
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL 
  DROP TABLE #TMP
GO
SELECT *
  INTO #TMP 
  FROM (SELECT TOP 10000000 * FROM OrdersBig ORDER BY Value) AS Tab1 
OPTION (MAXDOP 8) -- Ver plano em paralelo




-- Exemplo de respostas...
-- Quanto tempo vai demorar pra criar um índice?
-- Já comecou a inserir na tabela? ... posso cancelar ? ou vai começar um rollback? ...


-- Exemplo estimativa para criar índice...
IF EXISTS(SELECT 1 FROM sysindexes WHERE name = 'ix1' and id = OBJECT_ID('OrdersBig'))
  DROP INDEX ix1 ON OrdersBig
GO
CREATE INDEX ix1 ON OrdersBig(Value) WITH(DATA_COMPRESSION = PAGE, MAXDOP = 1)
GO

-- Quanto de CPU eu gastei com esse hash join, 
-- considerando apenas o custo do hash?
SELECT *
  FROM Alunos_Hash
 INNER JOIN Cursos_Hash
    ON Alunos_Hash.ID_Cursos = Cursos_Hash.ID_Cursos
OPTION (HASH JOIN, MAXDOP 1)
GO


-- Parar evento...
ALTER EVENT SESSION xEvent_CapturaPlano
ON SERVER
STATE=STOP;
GO
DROP EVENT SESSION xEvent_CapturaPlano ON SERVER
GO



-- Rodar um nova sessão
-- Ver status das operações do plano
SELECT * FROM sys.dm_exec_query_profiles
GO

-- Retorna dados agrupados
SELECT node_id,
       physical_operator_name,
       SUM(row_count) AS row_count, 
       SUM(estimate_row_count) AS estimate_row_count,
       CAST(SUM(row_count)*100 AS float) / SUM(estimate_row_count) AS percent_complete
  FROM sys.dm_exec_query_profiles
 WHERE session_id = 55 --spid que está rodando comando
 GROUP BY node_id,
          physical_operator_name
 ORDER BY node_id;
GO

-- Retorna detalhes
SELECT dm_exec_query_profiles.node_id,
       dm_exec_query_profiles.physical_operator_name,
       CONVERT(VarChar(max), dm_exec_sql_text.text) as "TSQL",
       dm_exec_query_plan.query_plan,
       dm_exec_query_profiles.row_count,
       dm_exec_query_profiles.estimate_row_count,
       dm_exec_query_profiles.session_id,
       dm_exec_query_profiles.physical_operator_name,
       dm_exec_query_profiles.node_id,
       dm_exec_query_profiles.thread_id,
       dm_exec_query_profiles.row_count,
       dm_exec_query_profiles.rewind_count,
       dm_exec_query_profiles.rebind_count,
       dm_exec_query_profiles.elapsed_time_ms,
       dm_exec_query_profiles.cpu_time_ms,
       OBJECT_NAME(dm_exec_query_profiles.object_id) AS ObjName,
       dm_exec_query_profiles.index_id,
       dm_exec_query_profiles.scan_count,
       dm_exec_query_profiles.logical_read_count,
       dm_exec_query_profiles.physical_read_count,
       dm_exec_query_profiles.read_ahead_count,
       dm_exec_query_profiles.write_page_count
  FROM sys.dm_exec_query_profiles
 CROSS apply sys.dm_exec_sql_text(dm_exec_query_profiles.sql_handle)
 CROSS apply sys.dm_exec_query_plan(dm_exec_query_profiles.plan_handle)
 WHERE dm_exec_query_profiles.session_id = 53 --spid que está rodando comando
 ORDER BY dm_exec_query_profiles.node_id;
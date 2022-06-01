/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-------------------------------------------------------------------------
-- TraceFlags - 2388, 2389, 2390, 2371 (SQL2008SP1), 9292, 9204 e 8666 --
-------------------------------------------------------------------------

USE Northwind
GO

-- **********************************************************
-- * Atenção comandos não documentados devem ser utilizados *
-- * com extrema precaução e devem ser observados durante   *
-- * atualização de versões do SQL Server                   *
-- **********************************************************

/*
  DBCC TRACEON(2388)
  Muda o resultado do DBCC SHOW_STATISTICS para exibir 
  se a estatística é "ascendente"
  Requer que um índice pela coluna ascendente exista
  -- http://support.microsoft.com/?kbid=922063

  DBCC TRACEON(2389)  
  Caso a estatística esteja marcada como ascendente adiciona 
  um novo passo no histograma com o maior valor da tabela.
  Requer que um índice pela coluna ascendente exista
  -- http://support.microsoft.com/?kbid=922063
  
  DBCC TRACEON(2390)
  Mesmo comportamento do trace flag 2389 porém não requer que a 
  estatística esteja marcada como ascendente

  DBCC TRACEON(2371) 
  Novo trace flag do SQL Server 2008 R2 SP1
  Muda threshould de modificações para disparar auto_update_statistics
  dependendo do número de linhas da tabela
  http://blogs.msdn.com/b/saponsqlserver/archive/2011/09/07/changes-to-automatic-update-statistics-in-sql-server-traceflag-2371.aspx

-- = Threshould atual, fixo em aprox. 20%
\  = Threshould dinâmico com TF 2371

25 | 
   |
20 |----------------------------------------------------------------------
   |                              \
15 |                                  \
   |                                      \
10 |                                         \
   |                                              \
05 |                                                  \
   |                                                       \
00 |___________________________________________________________\__________
   0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
      0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
      5  5  0  0  0  5  0  5  0  0  0  0  0  0  0  0  0  0  0  0  0  0  0
         2  5  7  0  2  5  7  0  5  0  0  0  5  0  0  0  0  0  0  0  0  0
                  1  1  1  1  2  2  3  4  5  7  0  0  0  0  0  0  0  0  0
                                                1  2  5  0  0  0  0  0  0
                                                         1  5  0  0  0  0
                                                               1  5  0  0
                                                                     1  2

  DBCC TRACEON(9292)
  Reporta as estatísticas que foram consideradas "interessantes" pelo QO
  quando compilando o plano.
  Para estatísticas potencialmente uteis, apenas o cabeçalho da é lido.
  

  DBCC TRACEON(9204)
  Reporta quais estatísticas foram lidas e utilizadas para criar
  um plano de execução.

  DBCC TRACEON(8666)
  Retorna varias informações internas sobre um plano de execução, 
  inclusive as estatísicas utilizadas na criação do plano
*/


-- Exemplo TFs, 2388, 2389 e 2390

-- DELETE FROM OrdersBig WHERE OrderDate > GetDate()
-- DROP INDEX OrdersBig.ix_OrderDate
CREATE INDEX ix_OrderDate on OrdersBig(OrderDate)
GO

DBCC TRACEON(2388)
DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate])
DBCC TRACEOFF(2388)
GO

-- A partir do terceiro UPDATE com dados ascendentes a estatística é marcada como 
-- "Ascending"

-- Inserir 10 linhas ascendentes
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES  (106,
         (SELECT DATEADD(d, 1, MAX(OrderDate)) FROM OrdersBig),
         ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))))
GO 10
-- Atualizar a estatística
UPDATE STATISTICS OrdersBig [ix_OrderDate] WITH FULLSCAN
GO
-- Verificar se a estatística é "ascendente"
DBCC TRACEON(2388)
DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate])
DBCC TRACEOFF(2388)
GO


-- Exibindo o problema

-- Inserir 10 mil linhas ascendentes para testar o traceflag
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
SELECT 10,
       GetDate(),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
GO
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES  (10,
         (SELECT DateAdd(d, 1, MAX(OrderDate)) FROM OrdersBig),
         ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))))
GO 10000


-- Estimativa incorreta pois as estatísticas estão desatualizadas
-- e não atingiram o número suficiente de alterações para disparar 
-- o auto update
SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 WHERE OrderDate > '20200101'
OPTION(RECOMPILE)
SET STATISTICS IO OFF
GO

-- Por que errou na estimativa? 
-- Porque não tem no histograma vendas com data maior que 2020
DBCC SHOW_STATISTICS (OrdersBig, [ix_OrderDate])
GO


-- O ideal seria fazer um Scan
SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig WITH(index=0)
 WHERE OrderDate > '20200101'
OPTION(RECOMPILE)
SET STATISTICS IO OFF
GO



-- Utilizando os TraceFlags o SQL Server gera um select para pegar o maior valor
-- e adicione este valor no histograma para fazer a estimativa
SET STATISTICS IO ON
SELECT *
  FROM OrdersBig
 WHERE OrderDate > '20200101'
OPTION(QueryTraceON 2389, QueryTraceON 2390, RECOMPILE)
SET STATISTICS IO OFF
GO


-- Exemplo TFs 9292 e 9204

SELECT CustomersBig.ContactName, 
       SUM(OrdersBig.Value)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName LIKE 'Manuel%'
 GROUP BY CustomersBig.ContactName
OPTION(QueryTraceON 3604, QueryTraceON 9292, QueryTraceON 9204, 
       RECOMPILE,
       MAXDOP 1)
GO

-- DROP INDEX ixOrdersBig_CustomerID ON OrdersBig
CREATE INDEX ixOrdersBig_CustomerID ON OrdersBig(CustomerID) INCLUDE(Value)
GO

-- Exemplo TFs 8666
DBCC FREEPROCCACHE()
DBCC TRACEON(8666)
GO
SELECT CustomersBig.ContactName, 
       SUM(OrdersBig.Value)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName LIKE 'Manuel%'
 GROUP BY CustomersBig.ContactName
OPTION(MAXDOP 1)
GO
DBCC TRACEOFF(8666)
GO

-- Consultando informação de planos em cache
DBCC TRACEON(8666)
GO
WITH XMLNAMESPACES ('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as p)
SELECT qt.text AS SQLCommand,
       qp.query_plan,
       StatsUsed.XMLCol.value('@FieldValue','NVarChar(500)') AS StatsName
  FROM sys.dm_exec_cached_plans cp
 CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
 CROSS APPLY sys.dm_exec_sql_text (cp.plan_handle) qt
 CROSS APPLY query_plan.nodes('//p:Field[@FieldName="wszStatName"]') StatsUsed(XMLCol)
 WHERE qt.text LIKE '%Manuel%'
   AND qt.text NOT LIKE '%sys.%'
GO
DBCC TRACEOFF(8666)
GO

-- Traceflag extra, correlated columns
-- TraceFlag 4137
-- http://support.microsoft.com/kb/2658214
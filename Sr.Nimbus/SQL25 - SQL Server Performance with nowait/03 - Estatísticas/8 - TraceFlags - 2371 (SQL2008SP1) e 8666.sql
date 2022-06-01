/*
  SQL25 - SQL Server Performance with nowait
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

  DBCC TRACEON(8666)
  Retorna varias informações internas sobre um plano de execução, 
  inclusive as estatísicas utilizadas na criação do plano
*/



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
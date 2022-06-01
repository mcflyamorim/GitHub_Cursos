/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-----------------------------------------------------
-- Simulando um GAP nas 200 amostras do histograma --
-----------------------------------------------------

USE Northwind
GO

/*
  Setando a coluna Quantity em 500 grupos de 1 a 500
  com 2000 linhas em cada grupo.
*/
;WITH CTE
AS
(
SELECT NTILE(500) OVER(ORDER BY OrderID, ProductID) Qtd,
       *
  FROM Order_DetailsBig
)
UPDATE CTE SET Quantity = Qtd;
GO
-- Deixar um GAP no grupo 444
UPDATE Order_DetailsBig SET Quantity = -1
WHERE Quantity = 444
GO


CREATE STATISTICS Stats_Quantity ON Order_DetailsBig (Quantity)
GO

-- Atualizando as estatísticas
UPDATE STATISTICS Order_DetailsBig Stats_Quantity WITH FULLSCAN
GO
-- Visualizando o GAP do valor 444
DBCC SHOW_STATISTICS (Order_DetailsBig, Stats_Quantity) WITH HISTOGRAM
GO

/*
  Como o valor 444 não esta no histograma ele usa a média de 
  distribuição dos valores (AVG_RANGE_ROWS) entre o range
  
  Neste caso ele estima que 2000 linhas serão retornadas o que é errado
*/
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
GO

/*
  DROP INDEX ix_Quantity ON Order_DetailsBig (Quantity)
  Se eu tiver um índice por Quantity será 
  que não compensa usar o índice?
*/
CREATE INDEX ix_Quantity ON Order_DetailsBig (Quantity)
GO

-- SQL Continua não utilizando o índice
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF

-- Vejamos a Quantity de IOs forçando o SEEK
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig WITH(FORCESEEK)
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF

/*
  Criando estatísticas filtradas para resolver o problema
*/

IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_0_a_200' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_0_a_200
IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_201_a_400' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_201_a_400
IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_Maior_401' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_Maior_401
GO
CREATE STATISTICS Stats_Quantity_0_a_200 ON Order_DetailsBig(Quantity) WHERE Quantity >= 0 AND Quantity <= 200 WITH FULLSCAN
CREATE STATISTICS Stats_Quantity_201_a_400 ON Order_DetailsBig(Quantity) WHERE Quantity >= 201 AND Quantity <= 400 WITH FULLSCAN
CREATE STATISTICS Stats_Quantity_Maior_401 ON Order_DetailsBig(Quantity) WHERE Quantity >= 401 WITH FULLSCAN
GO

-- Apenas 51 amostras foram analisadas, e o problema do GAP foi corrigido
DBCC SHOW_STATISTICS (Order_DetailsBig, Stats_Quantity_Maior_401)
GO

-- Com a estimativa correta o SQL utiliza corretamente o índice
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF


-- E em procs como fica?
IF OBJECT_ID('st_TestGAPStatistics') IS NOT NULL
  DROP PROC st_TestGAPStatistics
GO
CREATE PROC st_TestGAPStatistics @i Int
AS
BEGIN
  SELECT * 
    FROM Order_DetailsBig
   WHERE Quantity = @i
  OPTION (RECOMPILE) -- Necessário para poder usar a estatística associada ao valor
END
GO
 
EXEC st_TestGAPStatistics @i = 444
GO

-- Consultando informação sobre estatística utilizada
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
 WHERE qt.text LIKE '%st_TestGAPStatistics%'
   AND qt.text NOT LIKE '%sys.%'
GO
DBCC TRACEOFF(8666)
GO
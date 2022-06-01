/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/* 
  Manutenção das Estatísticas
*/

-- Problema com estatísticas desatualizadas
-- AUTO_UPDATE_STATISTICS

ALTER DATABASE NorthWind SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
GO

UPDATE TOP (50) PERCENT Order_DetailsBig SET Quantity = CHECKSUM(NEWID()) / 10000
GO

-- Estimativa incorreta, pois as estatisticas estão desatualizadas
SELECT * FROM Order_DetailsBig
WHERE Quantity = 100
OPTION (RECOMPILE)
GO

ALTER DATABASE NorthWind SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT
GO

-- Estimativa correta, pois o AUTO_UPDATE_STATISTICS é disparado
-- automaticamente
SELECT * FROM Order_DetailsBig
WHERE Quantity = 100
OPTION (RECOMPILE)

/*
  Quando um auto update statistics é disparado?
  AUTO_UPDATE_STATISTICS
  RowModCtr
  
  - Se a cardinalidade da tabela é menor que seis e a tabela esta no 
  banco de dados tempdb, auto atualiza a cada seis modificações na tabela

  - Se a cardinalidade da tabela é maior que seis e menor ou igual a 500,
  então atualiza as estatísticas a cada 500 modificações na tabela
  
  - Se a cardinalidade da tabela é maior que 500,
  atualiza as estatísticas quando 500 + 20% da tabela for alterada.
  
  No Profiler visualizar os evento SP:StmtCompleted e SP:StmtStarting
*/



-- Exemplo sp_updatestats
-- Runs UPDATE STATISTICS against all user-defined and internal tables in 
-- the current database
EXEC sp_updatestats
GO


-- Linhas modificadas por coluna, antiga rowmodctr
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Int, Col2 Int, Col3 Int, Col4 Int, Col5 Int)
GO
CREATE STATISTICS StatsCol1 ON Tab1(Col1)
CREATE STATISTICS StatsCol2 ON Tab1(Col2)
CREATE STATISTICS StatsCol3 ON Tab1(Col3)
CREATE STATISTICS StatsCol4 ON Tab1(Col4)
CREATE STATISTICS StatsCol5 ON Tab1(Col5)
GO
INSERT INTO Tab1(Col1, Col2, Col3, Col4, Col5) VALUES(1, 1, 1, 1, 1)
GO 100
CHECKPOINT
GO
SELECT * FROM Tab1
GO

-- Quantidade de modificações na tabela
SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

-- Zerando rowmodctr
UPDATE STATISTICS Tab1 WITH FULLSCAN
GO

SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

-- Atualizando 5 linhas
UPDATE TOP (5) Tab1 SET Col1 = 2
GO

SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

-- E as estatísticas com 2 colunas?
CREATE STATISTICS StatsCol1_Col2 ON Tab1(Col1, Col2)
GO

SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

UPDATE TOP (5) Tab1 SET Col2 = 2
GO

-- Update na "segunda" coluna não atualiza rowmodctr
SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

-- Apagando 5 linhas
DELETE TOP (5) FROM Tab1
GO

SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('Tab1')
GO

-- Zerar rowmodctr para seguir os testes
UPDATE STATISTICS Tab1 WITH FULLSCAN
GO

/*
"From BOL"
In SQL Server 2000 and earlier, the Database Engine maintained row-level 
modification counters. 
Such counters are now maintained at the column level. 
Therefore, the rowmodctr column is calculated and produces results that 
are similar to the results in earlier versions, but are not exact. 
*/

-- Consultando modificações por coluna
-- DMV sys.system_internals_partition_columns mostra modificações por coluna, 
-- independente de terem índice ou estatística
CHECKPOINT
SELECT partitions.object_id,
       partitions.index_id,
       columns.name,
       system_internals_partition_columns.partition_column_id,
       system_internals_partition_columns.modified_count
  FROM sys.system_internals_partition_columns
 INNER JOIN sys.partitions
    ON system_internals_partition_columns.partition_id = partitions.partition_id
 INNER JOIN sys.columns
    ON partitions.object_id = columns.object_id
   AND system_internals_partition_columns.partition_column_id = columns.column_id 
 WHERE partitions.object_id = OBJECT_ID('Tab1')
GO
-- system_internals_partition_columns só é atualizada depois do checkpoint


-- Atualizando algumas colunas
UPDATE TOP (10) Tab1 SET Col4 = 5, Col5 = 5
GO

CHECKPOINT
SELECT OBJECT_NAME(partitions.object_id) AS objName,
       partitions.object_id,
       partitions.index_id,
       columns.name,
       system_internals_partition_columns.partition_column_id,
       system_internals_partition_columns.modified_count
  FROM sys.system_internals_partition_columns
 INNER JOIN sys.partitions
    ON system_internals_partition_columns.partition_id = partitions.partition_id
 INNER JOIN sys.columns
    ON partitions.object_id = columns.object_id
   AND system_internals_partition_columns.partition_column_id = columns.column_id 
 WHERE partitions.object_id = OBJECT_ID('Tab1')
GO

-- Apagando 10 linhas
DELETE TOP (10) FROM Tab1
GO

CHECKPOINT
SELECT OBJECT_NAME(partitions.object_id) AS objName,
       partitions.object_id,
       partitions.index_id,
       columns.name,
       system_internals_partition_columns.partition_column_id,
       system_internals_partition_columns.modified_count
  FROM sys.system_internals_partition_columns
 INNER JOIN sys.partitions
    ON system_internals_partition_columns.partition_id = partitions.partition_id
 INNER JOIN sys.columns
    ON partitions.object_id = columns.object_id
   AND system_internals_partition_columns.partition_column_id = columns.column_id 
 WHERE partitions.object_id = OBJECT_ID('Tab1')
GO

-- AUTO_UPDATE_STATISTICS
-- Quanto tempo demora para disparar um auto_update em uma tabela grande?

ALTER DATABASE NorthWind SET AUTO_UPDATE_STATISTICS ON
GO

-- Criando índice para testes
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO
-- Consultando quantidade de modificações no índice desde sua criação/update
SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('OrdersBig')
GO

-- Gerando update de várias linhas para disparar auto_update_statistics
-- 15 segundos
UPDATE TOP (50) PERCENT OrdersBig SET OrderDate = CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 100000))
GO

-- Consultando quantidade de modificações no índice desde sua criação/update
SELECT name, id, rowmodctr
  FROM sysindexes
 WHERE id = OBJECT_ID('OrdersBig')
GO

-- Disparando auto update statsitics
SELECT *
  FROM OrdersBig
 WHERE OrderDate = '20121221' -- Maias estavam errados!
GO


-- Mas quanto tempo demorou?

-- Profiler SP:StmtCompleted e SP:StmtStarting
-- Ou TraceFlags 3604/3605 e 8721
DBCC TRACEON(3605)
/*
  Error Log:
  Message
  AUTOSTATS: Tbl: OrdersBig Objid:1637580872 Rows: 1000070.000000 Threshold: 200514 Duration: 1055ms
  Message
  AUTOSTATS: UPDATED Stats: OrdersBig..ixOrderDate Dbid = 5 Indid = 3 Rows: 315415 Duration: 1061ms
*/

DBCC TRACEON(3605)
DBCC TRACEON(8721)

-- Gerando update de várias linhas para disparar auto_update_statistics
-- 15 segundos
UPDATE TOP (50) PERCENT OrdersBig SET OrderDate = CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 100000))
GO

-- Disparando auto update statsitics - VER ERROR LOG
SELECT *
  FROM OrdersBig
 WHERE OrderDate = '20121221' -- Maias estavam errados!
GO



-- AUTO_UPDATE_STATISTICS_ASYNC
-- E se eu não quiser esperar pelo update?

ALTER DATABASE Northwind SET AUTO_UPDATE_STATISTICS_ASYNC ON
GO

-- Gerando update de várias linhas para disparar auto_update_statistics
-- 15 segundos
UPDATE TOP (50) PERCENT OrdersBig SET OrderDate = CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 100000))
GO

-- Disparando auto update statsitics
SELECT *
  FROM OrdersBig
 WHERE OrderDate = '20121221' -- Maias estavam errados!
GO

-- Consultando tempo gasto... 
SELECT * FROM sys.dm_exec_background_job_queue_stats
GO

ALTER DATABASE Northwind SET AUTO_UPDATE_STATISTICS_ASYNC OFF
GO

-- Ou desabilita o auto update/create statistics para a tabela 
EXEC sp_autostats 'OrdersBig', 'OFF' 
GO


-- AUTO_CREATE_STATISTICS
-- Quanto tempo demora para disparar um auto_create em uma tabela grande?
-- Criando tabela com 5 milhões de linhas
-- DROP TABLE TestAutoUpdateStatistics
SELECT TOP 5000000 a.*
  INTO TestAutoUpdateStatistics
  FROM OrdersBig  a, OrdersBig b
GO

-- Gera auto create statistics pois estatística ainda não existe
SELECT COUNT(*)
  FROM TestAutoUpdateStatistics
 WHERE Value BETWEEN 1000 AND 1100
GO
-- Message
-- AUTOSTATS: CREATED Dbid = 5 Tbl: TestAutoUpdateStatistics(Value) Rows: 315481  Dur: 1591ms

-- TFs para verificar tempo gasto
DBCC TRACEON(3605)
DBCC TRACEON(8721)


-- EDGE Cases
-- E colunas blob ?

IF OBJECT_ID('TestBlobTab') IS NOT NULL
  DROP TABLE TestBlobTab
GO
CREATE TABLE TestBlobTab (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Int, Foto VarBinary(MAX))
GO

-- 51 mins e 39 segundos para rodar
INSERT INTO TestBlobTab (Col1, Foto)
SELECT TOP 10000
       CheckSUM(NEWID()) / 1000000, 
       CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000))
FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d 
GO

INSERT INTO TestBlobTab (Col1, Foto)
SELECT CheckSUM(NEWID()) / 1000000, 
       NULL
GO 100


-- Consulta quantidade de páginas LOB
SELECT t.name, au.*
  FROM sys.system_internals_allocation_units au
 INNER JOIN sys.partitions p
    ON au.container_id = p.partition_id
 INNER JOIN sys.tables t
    ON p.object_id = t.object_id
 WHERE t.name = 'TestBlobTab'
GO


-- Demora uma eternidade para criar a estatística na coluna Foto...
-- 38 segundos para criar a estatística
-- Consulta roda em 0 segundos
SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL

-- Message
-- AUTOSTATS: CREATED Dbid = 5 Tbl: TestBlobTab(Foto) Rows: 10100  Dur: 38657ms

-- E o auto update? Também demora?

UPDATE TOP (50) PERCENT TestBlobTab SET Foto = CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000))
GO


-- Agora vai disparar o auto update, certo? Vai mesmo? Vejamos...
SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
GO

-- Porque não disparou o auto-update?









-- Query não foi recompilada... vamos recompilar pra gerar o update statistics
SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
OPTION (RECOMPILE, QueryTraceOn 8757) -- desabilita trivial plan

--AUTOSTATS: Tbl: TestBlobTab Objid:2066106401 Rows: 10100.000000 Threshold: 2520 Duration: 44024ms
GO



-- Mais informações aqui...
http://blogs.msdn.com/b/psssql/archive/2009/01/22/how-it-works-statistics-sampling-for-blob-data.aspx



-- Workaround --

-- NO_RECOMPUTE

-- Identificando as estatísticas criadas automaticamente
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('TestBlobTab')
GO

DROP STATISTICS TestBlobTab._WA_Sys_00000003_03F0984C
GO

-- Criando manualmente com clausula NORECOMPUTE
-- DROP STATISTICS TestBlobTab.StatsFoto
CREATE STATISTICS StatsFoto ON TestBlobTab(Foto) WITH NORECOMPUTE, SAMPLE 0 PERCENT
GO

SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
OPTION (RECOMPILE)

-- Boa prática, criar estatísticas em colunas LOB e controlar manualmente quando ela 
-- será atualizada...
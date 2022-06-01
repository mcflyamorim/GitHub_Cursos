/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

---------------------------------------
-- Identificando colunas ascendentes --
---------------------------------------

USE Northwind
GO

-- Utilizando TF 2388 para mudar o resultado do DBCC SHOW_STATISTICS
DBCC TRACEON(2388) WITH NO_INFOMSGS


-- Script para varrer todas as estatísticas do banco de dados
-- procurando por estatísticas "marcadas" como ascendentes
SET NOCOUNT ON
IF OBJECT_ID('tempdb.dbo.#TMP_stats') IS NOT NULL
  DROP TABLE #TMP_stats

IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP

CREATE TABLE #TMP(ROWID Int IDENTITY(1,1) PRIMARY KEY, 
                  TableName NVarChar(800),
                  StatsName NVarChar(800),
                  "Updated" NVarChar(800),
                  "Table Cardinality" BigInt,
                  "Snapshot Ctr"	BigInt,
                  "Steps"	BigInt,
                  "Density" Float,
                  "Rows Above" Float,
                  "Rows Below" Float,
                  "Squared Variance Error" Float,
                  "Inserts Since Last Update" Float,
                  "Deletes Since Last Update" Float,
                  "Leading column Type" NVarChar(200))

;with CTE_1
as
(
  select object_schema_name(a.object_id) schemaname, 
         object_name(a.object_id) as 'TableName',
         a.name as 'StatsName',
         stats_date(a.object_id, stats_id) as stats_last_updated_time,
         (SELECT SUM(p.rows)
            FROM sys.partitions p
           WHERE a.object_id = p.object_id
             and index_id <= 1) as number_of_rows
  from sys.stats as a
  inner join sys.objects as b
  on a.object_id = b.object_id
  where b.type = 'U'
)
select IDENTITY(Int , 1,1) ROWID, *, 'DBCC SHOW_STATISTICS ("' + schemaname + '.' + tablename + '",' + statsname + ') WITH NO_INFOMSGS' AS SQL
  INTO #TMP_stats
  from CTE_1
 where number_of_rows > 1000
CREATE CLUSTERED INDEX ix ON #TMP_stats(ROWID)

DECLARE @SQL NVarChar(MAX),
        @TableName NVarChar(800),
        @StatsName NVarChar(800),
        @ROWID Int,
        @LastID Int,
        @MaxID Int

SELECT @ROWID = 0,
       @SQL = '',
       @TableName = '',
       @StatsName = '',
       @LastID = 0,
       @MaxID = 2147483647

SELECT TOP 1 
       @ROWID = ROWID,
       @SQL = SQL,
       @TableName = TableName,
       @StatsName = StatsName
  FROM #TMP_stats
 WHERE ROWID > @ROWID
 ORDER BY ROWID

WHILE @@ROWCOUNT > 0
BEGIN
  PRINT @SQL

  INSERT INTO #TMP ("Updated","Table Cardinality","Snapshot Ctr","Steps","Density","Rows Above","Rows Below","Squared Variance Error","Inserts Since Last Update","Deletes Since Last Update","Leading column Type")
  EXEC (@SQL)

  SELECT @LastID = MIN(ROWID), @MaxID = MAX(ROWID)
    FROM #TMP
   WHERE ROWID BETWEEN (SELECT MIN(a.ROWID) FROM #TMP a WHERE a.TableName IS NULL) AND (SELECT MAX(b.ROWID) FROM #TMP b WHERE b.TableName IS NULL)

  UPDATE #TMP SET TableName = @TableName, StatsName = @StatsName
  WHERE ROWID BETWEEN @LastID AND @MaxID

  SELECT TOP 1
         @ROWID = ROWID,
         @SQL = SQL,
         @TableName = TableName,
         @StatsName = StatsName
    FROM #TMP_stats
   WHERE ROWID > @ROWID
   ORDER BY ROWID
END
DBCC TRACEOFF(2388) WITH NO_INFOMSGS

SELECT TableName,
       StatsName, 
       "Leading column Type",
       (SELECT SUM(p.rows)
          FROM sys.partitions p
         WHERE OBJECT_ID(TableName) = p.object_id
           AND index_id <= 1) as number_of_rows
  FROM #TMP
 ORDER BY ISNULL("Leading column Type",'x'), number_of_rows DESC
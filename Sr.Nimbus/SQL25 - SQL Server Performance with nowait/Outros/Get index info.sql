-- Specify DB you want to save the index usage information
USE msdb
GO
IF OBJECT_ID('DBAInfo_index_usage') IS NULL
BEGIN
  CREATE TABLE DBAInfo_index_usage
  ( database_name NVARCHAR (250) NULL,
    table_name NVARCHAR (250) NOT NULL,
    index_name NVARCHAR (250) NOT NULL,
    partition_number smallint NULL,
    index_type NVARCHAR (250) NULL,
    user_seeks BIGINT NOT NULL,
    user_scans BIGINT NOT NULL,
    user_lookups BIGINT NOT NULL,
    user_updates BIGINT NOT NULL,
    tot BIGINT NULL,
    leaf_insert_count bigint NULL,
    leaf_delete_count bigint NULL,
    leaf_update_count bigint NULL,
    leaf_ghost_count bigint NULL,
    nonleaf_insert_count bigint NULL,
    nonleaf_delete_count bigint NULL,
    nonleaf_update_count bigint NULL,
    range_scan_count bigint NULL,
    singleton_lookup_count bigint NULL,
    forwarded_fetch_count bigint NULL,
    lob_fetch_in_pages bigint NULL,
    page_latch_wait_count bigint NULL,
    page_io_latch_wait_count bigint NULL,
    captured_date DATETIME NOT NULL)
END

IF OBJECT_ID('tempdb.dbo.#db') IS NOT NULL
  DROP TABLE #db

SELECT d1.name into #db
FROM sys.databases d1
where d1.state_desc = 'ONLINE' and is_read_only = 0
and d1.name not in ('tempdb', 'master', 'msdb', 'model')

DECLARE @SQL VarCHar(MAX)
declare @database_name sysname

DECLARE c_databases CURSOR read_only FOR
    SELECT name FROM #db
OPEN c_databases

FETCH NEXT FROM c_databases
into @database_name
WHILE @@FETCH_STATUS = 0
BEGIN

  SET @SQL = 'use "' + @database_name + '"; ' + 
  
  'SELECT 
          DB_NAME() as database_name,
          sc.name + ''.'' + o.name AS table_name,
          ISNULL(i.name, ''HEAP'') AS index_name,
          ios.partition_number,
          i.type_desc AS index_type,
          ISNULL(s.user_seeks,0) AS user_seeks,
          ISNULL(s.user_scans,0) AS user_scans,
          ISNULL(s.user_lookups,0) AS user_lookups,
          ISNULL(s.user_updates,0) AS user_updates,
          ISNULL(s.user_seeks,0) + ISNULL(s.user_scans,0) + ISNULL(s.user_lookups,0) + ISNULL(s.user_updates,0) AS tot,
          ISNULL(ios.leaf_insert_count,0), -- Cumulative count of leaf-level inserts.
          ISNULL(ios.leaf_delete_count,0), -- Cumulative count of leaf-level deletes.
          ISNULL(ios.leaf_update_count,0), -- Cumulative count of leaf-level updates.
          ISNULL(ios.leaf_ghost_count,0), -- Cumulative count of leaf-level rows that are marked as deleted, but not yet removed.
          ISNULL(ios.nonleaf_insert_count,0), -- Cumulative count of inserts above the leaf level
          ISNULL(ios.nonleaf_delete_count,0), -- Cumulative count of deletes above the leaf level
          ISNULL(ios.nonleaf_update_count,0), -- Cumulative count of updates above the leaf level
          ISNULL(ios.range_scan_count,0), -- Cumulative count of range and table scans started on the index or heap
          ISNULL(ios.singleton_lookup_count,0), -- Cumulative count of single row retrievals from the index or heap.
          ISNULL(ios.forwarded_fetch_count,0), -- Count of rows that were fetched through a forwarding record. 
          ISNULL(ios.lob_fetch_in_pages,0), -- Cumulative count of large object (LOB) pages retrieved from the LOB_DATA allocation unit.
          ISNULL(ios.page_latch_wait_count,0), -- Cumulative number of times the Database Engine waited, because of latch contention.
          ISNULL(ios.page_io_latch_wait_count,0), -- Cumulative number of times the Database Engine waited on an I/O page latch. 
          GETDATE() AS captured_date
     FROM sys.indexes i WITH (NOLOCK)
    INNER JOIN sys.objects o WITH(NOLOCK)
       ON i.object_id = o.object_id
    INNER JOIN sys.schemas sc WITH(NOLOCK)
       ON sc.schema_id = o.schema_id
     LEFT OUTER JOIN sys.dm_db_index_usage_stats s WITH (NOLOCK) 
       ON s.index_id = i.index_id
      AND s.object_id = i.object_id
      AND s.database_id = DB_ID()
    OUTER APPLY sys.dm_db_index_operational_stats(DB_ID(), o.object_id, i.index_id, NULL) AS ios
    WHERE OBJECTPROPERTY(i.[object_id], ''IsUserTable'') = 1
      AND OBJECT_NAME(i.object_id) IS NOT NULL'

  INSERT INTO DBAInfo_index_usage
  EXEC (@SQL)
  
  FETCH NEXT FROM c_databases
  into @database_name
END
CLOSE c_databases
DEALLOCATE c_databases
GO


-- Some queries to grab information
; WITH CTE_1
AS
(
  SELECT *, 
         MONTH(captured_date) AS month_captured_date,
         DAY(captured_date) AS day_captured_date,
         DATEPART(hh, captured_date) AS hour_captured_date,
         DATEPART(mi, captured_date) AS minute_captured_date
    FROM DBAInfo_index_usage
)
SELECT captured_date, month_captured_date, day_captured_date, hour_captured_date, minute_captured_date,
       database_name, table_name, index_name, partition_number,
       user_seeks - LAG(user_seeks, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "user_seeks - Diff from last captured date",
       user_scans - LAG(user_scans, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_scans - Diff from last captured date",
       user_lookups - LAG(user_lookups, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_lookups - Diff from last captured date",
       user_updates - LAG(user_updates, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_updates - Diff from last captured date",
       tot - LAG(tot, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "Total reads - Diff from last captured date",
       leaf_insert_count - LAG(leaf_insert_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_insert_count - Diff from last captured date",
       leaf_delete_count - LAG(leaf_delete_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_delete_count - Diff from last captured date",
       leaf_update_count - LAG(leaf_update_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_update_count - Diff from last captured date",
       leaf_ghost_count - LAG(leaf_ghost_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_ghost_count - Diff from last captured date",
       nonleaf_insert_count - LAG(nonleaf_insert_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_insert_count - Diff from last captured date",
       nonleaf_delete_count - LAG(nonleaf_delete_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_delete_count - Diff from last captured date",
       nonleaf_update_count - LAG(nonleaf_update_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_update_count - Diff from last captured date",
       range_scan_count - LAG(range_scan_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "range_scan_count - Diff from last captured date",
       singleton_lookup_count - LAG(singleton_lookup_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "singleton_lookup_count - Diff from last captured date",
       forwarded_fetch_count - LAG(forwarded_fetch_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "forwarded_fetch_count - Diff from last captured date",
       lob_fetch_in_pages - LAG(lob_fetch_in_pages, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "lob_fetch_in_pages - Diff from last captured date",
       page_latch_wait_count - LAG(page_latch_wait_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "page_latch_wait_count - Diff from last captured date",
       page_io_latch_wait_count - LAG(page_io_latch_wait_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "page_io_latch_wait_count - Diff from last captured date"
  FROM CTE_1
  WHERE database_name = 'collectmessage' and table_name like 'dbo.TbMessage' and index_name = 'ix_IdLastMessageEventSource'
 ORDER BY database_name, table_name, index_name, partition_number, captured_date

-- Insert into a table to read from excel later
; WITH CTE_1
AS
(
  SELECT *, 
         MONTH(captured_date) AS month_captured_date,
         DAY(captured_date) AS day_captured_date,
         DATEPART(hh, captured_date) AS hour_captured_date,
         DATEPART(mi, captured_date) AS minute_captured_date
    FROM DBAInfo_index_usage
)
,
CTE_2
AS
(
SELECT captured_date, month_captured_date, day_captured_date, hour_captured_date, minute_captured_date,
       database_name, table_name, index_name, partition_number,
       database_name + '.' + table_name + '.' + index_name AS fullobjName,
       user_seeks - LAG(user_seeks, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "user_seeks - Diff from last captured date",
       user_scans - LAG(user_scans, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_scans - Diff from last captured date",
       user_lookups - LAG(user_lookups, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_lookups - Diff from last captured date",
       user_updates - LAG(user_updates, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "User_updates - Diff from last captured date",
       tot - LAG(tot, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "Total reads - Diff from last captured date",
       leaf_insert_count - LAG(leaf_insert_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_insert_count - Diff from last captured date",
       leaf_delete_count - LAG(leaf_delete_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_delete_count - Diff from last captured date",
       leaf_update_count - LAG(leaf_update_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_update_count - Diff from last captured date",
       leaf_ghost_count - LAG(leaf_ghost_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "leaf_ghost_count - Diff from last captured date",
       nonleaf_insert_count - LAG(nonleaf_insert_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_insert_count - Diff from last captured date",
       nonleaf_delete_count - LAG(nonleaf_delete_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_delete_count - Diff from last captured date",
       nonleaf_update_count - LAG(nonleaf_update_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "nonleaf_update_count - Diff from last captured date",
       range_scan_count - LAG(range_scan_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "range_scan_count - Diff from last captured date",
       singleton_lookup_count - LAG(singleton_lookup_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "singleton_lookup_count - Diff from last captured date",
       forwarded_fetch_count - LAG(forwarded_fetch_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "forwarded_fetch_count - Diff from last captured date",
       lob_fetch_in_pages - LAG(lob_fetch_in_pages, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "lob_fetch_in_pages - Diff from last captured date",
       page_latch_wait_count - LAG(page_latch_wait_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "page_latch_wait_count - Diff from last captured date",
       page_io_latch_wait_count - LAG(page_io_latch_wait_count, 1, NULL) OVER(PARTITION BY database_name, table_name, index_name, partition_number ORDER BY captured_date ASC) AS "page_io_latch_wait_count - Diff from last captured date"
  FROM CTE_1
)
SELECT *, "Total reads - Diff from last captured date" - "User_updates - Diff from last captured date" AS TotReadLessUpdates
  INTO IndexUsageTable
  FROM CTE_2
 ORDER BY database_name, table_name, index_name, partition_number, captured_date
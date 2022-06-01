/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano.amorim@srnimbus.com.br
  http://www.srnimbus.com.br
  http://blogfabiano.com
*/

USE SrCheck_BD
GO

set nocount on;

-- MetaData --
IF OBJECT_ID('tempdb.dbo.#MemoryUsagePerObject') IS NOT NULL
BEGIN
  DROP TABLE #MemoryUsagePerObject
END
CREATE TABLE [dbo].#MemoryUsagePerObject
(
[dbName] [nvarchar] (128) NULL,
[objectname] [nvarchar] (128) NULL,
[indexname] [sys].[sysname] NULL,
[indexid] [int] NOT NULL,
[cached_pages_count] [int] NULL,
[kb_cached] [int] NULL,
[mb_cached] [numeric] (16, 6) NULL,
  Free_Space_MB [numeric] (16, 6) NULL
) ON [PRIMARY]
GO

IF OBJECT_ID('MemoryUsagePerObject', 'u') IS NULL
BEGIN
  -- DROP TABLE MemoryUsagePerObject
  CREATE TABLE [dbo].[MemoryUsagePerObject]
  (
  [dbName] [nvarchar] (128) NULL,
  [objectname] [nvarchar] (128) NULL,
  [indexname] [sys].[sysname] NULL,
  [indexid] [int] NOT NULL,
  [cached_pages_count] [int] NULL,
  [kb_cached] [int] NULL,
  [mb_cached] [numeric] (16, 6) NULL,
  Free_Space_MB [numeric] (16, 6) NULL,
  [capture_date] [datetime] NOT NULL
  ) ON [PRIMARY]
END
GO

IF OBJECT_ID('tempdb.dbo.#db') IS NOT NULL
  DROP TABLE #db
GO

SELECT d1.[name] into #db
FROM sys.databases d1
where d1.state_desc = 'ONLINE' and is_read_only = 0
and d1.name not in ('tempdb')

DECLARE @SQL VarCHar(MAX)
declare @database_name sysname

DECLARE c_databases CURSOR read_only FOR
    SELECT [name] FROM #db
OPEN c_databases

FETCH NEXT FROM c_databases
into @database_name
WHILE @@FETCH_STATUS = 0
BEGIN
  print @database_name
  SET @SQL = 'use [' + @database_name + ']; ' + 
             'INSERT INTO #MemoryUsagePerObject
              SELECT DB_Name() AS dbName, 
                     obj.name as objectname,
                     ind.name as indexname,
                     obj.index_id as indexid,
                     count(*) as cached_pages_count,
                     (count(*) * 8) as kb_cached,
                     (count(*) * 8) / 1024. as mb_cached,
                     (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS Free_Space_MB
                FROM sys.dm_os_buffer_descriptors as bd
               INNER JOIN (SELECT object_id as objectid,
                                  object_name(object_id) as name,
                                  index_id,
                                  allocation_unit_id
                             FROM sys.allocation_units as au
                            INNER JOIN sys.partitions as p
                               ON au.container_id = p.hobt_id
                              AND (au.type = 1 OR au.type = 3)
                            UNION ALL
                           SELECT object_id as objectid,
                                  object_name(object_id) as name,
                                  index_id,
                                  allocation_unit_id
                             FROM sys.allocation_units as au
                            INNER JOIN sys.partitions as p
                               ON au.container_id = p.partition_id
                              AND au.type = 2) as obj
                  ON bd.allocation_unit_id = obj.allocation_unit_id
                LEFT OUTER JOIN sys.indexes ind
                  ON obj.objectid = ind.object_id
                 AND obj.index_id = ind.index_id
               WHERE bd.database_id = db_id()
                 AND bd.page_type in (''data_page'', ''index_page'')
               GROUP BY obj.name,
                       ind.name,
                       obj.index_id
               ORDER BY cached_pages_count DESC'

  EXEC (@SQL)
  
  FETCH NEXT FROM c_databases
  into @database_name
END
CLOSE c_databases
DEALLOCATE c_databases
GO
INSERT INTO MemoryUsagePerObject
SELECT *, getdate() as capture_date FROM #MemoryUsagePerObject
GO

SELECT * 
  FROM MemoryUsagePerObject
 ORDER BY capture_date, cached_pages_count DESC

/*
IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL 
  DROP TABLE #tmp1

SELECT * 
  INTO #tmp1 
  FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'limited')

SELECT DB_Name() AS dbName, 
       schemas.name + '.' + obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid,
       obj.data_compression_desc,
       obj.ActualSizeMB,
       count(*) as cached_pages_count,
       (count(*) * 8) / 1024. as mb_cached,
       (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS Free_Space_MB,
       indexstats.avg_fragmentation_in_percent,
       indexstats.page_count
  FROM sys.dm_os_buffer_descriptors as bd
 INNER JOIN (SELECT object_id as objectid,
                    object_name(object_id) as name,
                    index_id,
                    allocation_unit_id,
                    p.data_compression_desc,
                    (au.total_pages * 8) / 1024. ActualSizeMB
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.hobt_id
                AND (au.type = 1 OR au.type = 3)
              UNION ALL
             SELECT object_id as objectid,
                    object_name(object_id) as name,
                    index_id,
                    allocation_unit_id,
                    p.data_compression_desc,
                    (au.total_pages * 8) / 1024. ActualSizeMB
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.partition_id
                AND au.type = 2) as obj
    ON bd.allocation_unit_id = obj.allocation_unit_id
  LEFT OUTER JOIN #tmp1 indexstats
    ON obj.objectid = indexstats.object_id
   AND obj.index_id = indexstats.index_id
  LEFT OUTER JOIN sys.indexes ind
    ON obj.objectid = ind.object_id
   AND obj.index_id = ind.index_id
  LEFT OUTER JOIN sys.objects
    ON objects.object_id = ind.object_id
  LEFT OUTER JOIN sys.schemas
    ON objects.schema_id = schemas.schema_id
 WHERE bd.database_id = db_id()
   AND bd.page_type in ('data_page', 'index_page')
 GROUP BY schemas.name + '.' + obj.name,
         ind.name,
         obj.index_id,
         obj.data_compression_desc,
         ActualSizeMB,
         indexstats.avg_fragmentation_in_percent,
         indexstats.page_count
 ORDER BY cached_pages_count DESC
*/
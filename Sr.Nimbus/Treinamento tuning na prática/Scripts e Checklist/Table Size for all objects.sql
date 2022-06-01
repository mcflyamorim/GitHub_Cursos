/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano.amorim@srnimbus.com.br
  http://www.srnimbus.com.br
  http://blogfabiano.com
*/

USE SrCheck_BD
GO

IF OBJECT_ID('tempdb.dbo.#TMP1') IS NOT NULL
  DROP TABLE #TMP1
GO
CREATE TABLE #TMP1 ([DBName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                    [ObjectName] [nvarchar] (257) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
                    [IndexName] [sys].[sysname] NULL,
                    [type_desc] [nvarchar] (60) COLLATE Latin1_General_CI_AS_KS_WS NULL,
                    [row_count] [bigint] NOT NULL,
                    [reserved_mb] [numeric] (27, 6) NULL,
                    [data_mb] [numeric] (27, 6) NULL,
                    [index_mb] [numeric] (27, 6) NULL,
                    [unused_mb] [numeric] (27, 6) NULL)
GO
IF OBJECT_ID('ObjectSizeForAllObjects', 'u') IS NULL
BEGIN
  -- DROP TABLE ObjectSizeForAllObjects
  CREATE TABLE [dbo].ObjectSizeForAllObjects(
    [DBName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    [ObjectName] [nvarchar] (257) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    [IndexName] [sys].[sysname] NULL,
    [type_desc] [nvarchar] (60) COLLATE Latin1_General_CI_AS_KS_WS NULL,
    [row_count] [bigint] NOT NULL,
    [reserved_mb] [numeric] (27, 6) NULL,
    [data_mb] [numeric] (27, 6) NULL,
    [index_mb] [numeric] (27, 6) NULL,
    [unused_mb] [numeric] (27, 6) NULL,
    captute_date datetime
    )
END
GO

INSERT INTO #TMP1
EXEC sp_MSforeachdb @command1 = 
'USE [?];
SELECT DB_NAME() AS DBName,
       ss.name + ''.'' + so.name AS ObjectName,
       si.Name AS IndexName,
       si.type_desc,
       st.row_count,
       reserved_mb = (8. * sum(st.reserved_page_count)) / 1024,
       data_mb = (8. * sum(case when st.index_id < 2 then st.in_row_data_page_count + st.lob_used_page_count + st.row_overflow_used_page_count
                              else st.lob_used_page_count + st.row_overflow_used_page_count
                         end)) / 1024,
       index_mb = (8. * (sum(st.used_page_count) - sum(case when st.index_id < 2 then st.in_row_data_page_count + st.lob_used_page_count + st.row_overflow_used_page_count
                                                       else st.lob_used_page_count + st.row_overflow_used_page_count
                                                  end))) / 1024,
       unused_mb = (8. * sum(st.reserved_page_count - st.used_page_count)) / 1024
  FROM sys.objects so
 INNER JOIN sys.schemas ss
    ON so.schema_id = ss.schema_id
 INNER JOIN sys.indexes si
    ON si.Object_ID = so.Object_ID
 INNER JOIN sys.dm_db_partition_stats st
    ON so.object_id = st.object_id
   AND si.index_id = st.index_id
 WHERE so.type = ''U''
 GROUP BY ss.name,
          so.name,
          si.Name,
          si.type_desc,
          st.row_count
 ORDER BY reserved_mb DESC'
GO

INSERT INTO ObjectSizeForAllObjects
SELECT *, GetDate() AS captute_date FROM #TMP1
ORDER BY DBName, reserved_mb DESC
GO

SELECT * FROM ObjectSizeForAllObjects
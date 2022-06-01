/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano.amorim@srnimbus.com.br
  http://www.srnimbus.com.br
  http://blogfabiano.com
*/

USE tempdb
GO
SET NOCOUNT ON;


IF OBJECT_ID('tempdb.dbo.#tmpIndexInformation') IS NOT NULL
  DROP TABLE #tmpIndexInformation
GO
CREATE TABLE [dbo].#tmpIndexInformation
(
DBName NVarChar(500),
[table_name] [sys].[sysname] NOT NULL,
[index_name] [sys].[sysname] NOT NULL,
[object_id] [int] NOT NULL,
[index_id] [int] NOT NULL,
[index_description] [varchar] (210) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[indexed_columns] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[included_columns] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[filter_definition] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
fill_factor int,
[row_count] [bigint] NULL,
[QtKeyColumns] [bigint] NULL
) ON [PRIMARY]
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

  SET @SQL = 'use [' + @database_name + ']; ' + 
  
  'WITH IndexCTE
  AS
    ( 
    Select DB_Name() AS DBName
        , st.name As "table_name"
        , IsNull(ix.name, '''') As "index_name"
        , ix.object_id
        , ix.index_id
	    , Cast(
            Case When ix.index_id = 1 
                    Then ''clustered''
                When ix.index_id =0
                    Then ''heap''
                Else ''nonclustered'' End
		    + Case When ix.ignore_dup_key <> 0 
                Then '', ignore duplicate keys''
                    Else '''' End
		    + Case When ix.is_unique <> 0 
                Then '', unique''
                    Else '''' End
		    + Case When ix.is_primary_key <> 0 
                Then '', primary key'' Else '''' End As varchar(210)
            ) As ''index_description''
        , IsNull(Replace( Replace( Replace(
            (   
                Select c.name As ''columnName''
                From sys.index_columns As sic
                Join sys.columns As c 
                    On c.column_id = sic.column_id 
                    And c.object_id = sic.object_id
                Where sic.object_id = ix.object_id
                    And sic.index_id = ix.index_id
                    And is_included_column = 0
                Order By sic.index_column_id
                For XML Raw)
                , ''"/><row columnName="'', '', '')
                , ''<row columnName="'', '''')
                , ''"/>'', ''''), '''')
            As ''indexed_columns''
        , IsNull(Replace( Replace( Replace(
            (   
                Select c.name As ''columnName''
                From sys.index_columns As sic
                Join sys.columns As c 
                    On c.column_id = sic.column_id 
                    And c.object_id = sic.object_id
                Where sic.object_id = ix.object_id
                    And sic.index_id = ix.index_id
                    And is_included_column = 1
                Order By sic.index_column_id
                For XML Raw)
                , ''"/><row columnName="'', '', '')
                , ''<row columnName="'', '''')
                , ''"/>'', ''''), '''')
            As ''included_columns''
        , ix.filter_definition
        , ix.fill_factor AS fill_factor
        , Sum(rows) As ''row_count''
    From sys.indexes As ix
    Join sys.partitions As sp
        On ix.object_id = sp.object_id
        And ix.index_id = sp.index_id
    Join sys.tables As st
        On ix.object_id = st.object_id
    Group By  
         st.name
        , IsNull(ix.name, '''')
        , ix.object_id
        , ix.index_id
	    , Cast(
            Case When ix.index_id = 1 
                    Then ''clustered''
                When ix.index_id =0
                    Then ''heap''
                Else ''nonclustered'' End
		    + Case When ix.ignore_dup_key <> 0 
                Then '', ignore duplicate keys''
                    Else '''' End
		    + Case When ix.is_unique <> 0 
                Then '', unique''
                    Else '''' End
		    + Case When ix.is_primary_key <> 0 
                Then '', primary key'' Else '''' End As varchar(210)
            )
        , ix.filter_definition , ix.fill_factor
  )
  INSERT INTO #tmpIndexInformation
          (
           DBName,
           table_name,
           index_name,
           object_id,
           index_id,
           index_description,
           indexed_columns,
           included_columns,
           filter_definition,
           ix.fill_factor,
           row_count,
           QtKeyColumns
          )
  SELECT IndexCTE.*, 
         LEN(Indexed_Columns) - LEN(REPLACE(Indexed_Columns, '','','''')) + 1 AS QtKeyColumns
    FROM IndexCTE'

  EXEC (@SQL)
  
  FETCH NEXT FROM c_databases
  into @database_name
END
CLOSE c_databases
DEALLOCATE c_databases
GO


-- Indexes per table... 
SELECT dbname, table_name, COUNT(*) AS cnt
  FROM #tmpIndexInformation
 GROUP BY dbname, table_name
 ORDER BY 3 DESC

-- other info
SELECT * 
  FROM #tmpIndexInformation
 ORDER BY DBName, QtKeyColumns DESC


-- Query to check specific table...
/*

WITH IndexCTE
  AS
    ( 
    Select DB_Name() AS DBName
        , st.name As "table_name"
        , IsNull(ix.name, '') As "index_name"
        , ix.object_id
        , ix.index_id
	    , Cast(
            Case When ix.index_id = 1 
                    Then 'clustered'
                When ix.index_id =0
                    Then 'heap'
                Else 'nonclustered' End
		    + Case When ix.ignore_dup_key <> 0 
                Then ', ignore duplicate keys'
                    Else '' End
		    + Case When ix.is_unique <> 0 
                Then ', unique'
                    Else '' End
		    + Case When ix.is_primary_key <> 0 
                Then ', primary key' Else '' End As varchar(210)
            ) As 'index_description'
        , IsNull(Replace( Replace( Replace(
            (   
                Select c.name As 'columnName'
                From sys.index_columns As sic
                Join sys.columns As c 
                    On c.column_id = sic.column_id 
                    And c.object_id = sic.object_id
                Where sic.object_id = ix.object_id
                    And sic.index_id = ix.index_id
                    And is_included_column = 0
                Order By sic.index_column_id
                For XML Raw)
                , '"/><row columnName="', ', ')
                , '<row columnName="', '')
                , '"/>', ''), '')
            As 'indexed_columns'
        , IsNull(Replace( Replace( Replace(
            (   
                Select c.name As 'columnName'
                From sys.index_columns As sic
                Join sys.columns As c 
                    On c.column_id = sic.column_id 
                    And c.object_id = sic.object_id
                Where sic.object_id = ix.object_id
                    And sic.index_id = ix.index_id
                    And is_included_column = 1
                Order By sic.index_column_id
                For XML Raw)
                , '"/><row columnName="', ', ')
                , '<row columnName="', '')
                , '"/>', ''), '')
            As 'included_columns'
        , ix.filter_definition
        , ix.fill_factor AS fill_factor
        , Sum(rows) As 'row_count'
    From sys.indexes As ix
    Join sys.partitions As sp
        On ix.object_id = sp.object_id
        And ix.index_id = sp.index_id
    Join sys.tables As st
        On ix.object_id = st.object_id
    Group By  
         st.name
        , IsNull(ix.name, '')
        , ix.object_id
        , ix.index_id
	    , Cast(
            Case When ix.index_id = 1 
                    Then 'clustered'
                When ix.index_id =0
                    Then 'heap'
                Else 'nonclustered' End
		    + Case When ix.ignore_dup_key <> 0 
                Then ', ignore duplicate keys'
                    Else '' End
		    + Case When ix.is_unique <> 0 
                Then ', unique'
                    Else '' End
		    + Case When ix.is_primary_key <> 0 
                Then ', primary key' Else '' End As varchar(210)
            )
        , ix.filter_definition , ix.fill_factor
  )
  SELECT IndexCTE.*, 
         LEN(included_columns) - LEN(REPLACE(included_columns, ',','')) + 1 AS QtIncludedColumns,
         LEN(Indexed_Columns) - LEN(REPLACE(Indexed_Columns, ',','')) + 1 AS QtKeyColumns
    FROM IndexCTE
   WHERE table_name = 'Payment'

*/
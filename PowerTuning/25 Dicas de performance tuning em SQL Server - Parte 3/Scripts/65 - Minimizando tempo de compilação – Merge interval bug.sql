USE Northwind
GO
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #TMP
CREATE TABLE #TMP (Col NVarChar(MAX))
GO
DECLARE @In VarChar(MAX), 
        @SQL VarChar(MAX), 
        @i Int
SELECT @In = '0', @SQL = '', @i = 1

WHILE @i <= 2000
BEGIN
  SET @In = @In + ',' + CONVERT(VarChar, @i)
  SET @i = @i + 1
END

SET @SQL = 'SELECT * FROM OrdersBig INNER JOIN CustomersBig ON OrdersBig.CustomerID = CustomersBig.CustomerID ' + 
           'WHERE OrdersBig.OrderID IN (' + @In + ')'
--SELECT @SQL

INSERT INTO #TMP VALUES(@SQL)
GO
DBCC FREEPROCCACHE()
GO
-- Return plan with join to dummy table (constant scan)
DECLARE @SQL VarChar(MAX)
SELECT @SQL = Col 
  FROM #TMP

SET STATISTICS TIME ON
EXEC (@SQL)
SET STATISTICS TIME OFF
GO

-- E com sp_executesql?
-- compiletime 539ms
USE Northwind
GO
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #TMP
CREATE TABLE #TMP (Col NVarChar(MAX))
GO

DECLARE @In NVarChar(MAX), 
        @Parameters NVarChar(MAX),
        @SQL NVarChar(MAX), 
        @i Int
SELECT @In = '0', @Parameters = '@p0 Int', @SQL = '', @i = 1

WHILE @i <= 2000
BEGIN
  SET @In = @In + ',' + CONVERT(VarChar, @i)
  SET @Parameters = @Parameters + ', @p' + CONVERT(VarChar, @i) + ' Int'
  SET @i = @i + 1
END

SET @SQL = 'SELECT * FROM OrdersBig INNER JOIN CustomersBig ON OrdersBig.CustomerID = CustomersBig.CustomerID ' + 
           'WHERE OrdersBig.OrderID IN (' + REPLACE(@Parameters ,' Int', '')+ ')'
SET @SQL = 'EXEC sp_executeSQL N' + '''' + @SQL + '''' + ', N' + '''' + @Parameters + '''' + ', ' + @In

--SELECT @SQL

INSERT INTO #TMP VALUES(@SQL)
GO
DBCC FREEPROCCACHE()
GO

DECLARE @SQL VarChar(MAX)
SELECT @SQL = Col 
  FROM #TMP

-- Return plan with merge interval
SET STATISTICS TIME ON
EXEC (@SQL)
SET STATISTICS TIME OFF
GO





-- E sp_executesql + OPTION (RECOMPILE)?
-- compiletime 110ms
USE Northwind
GO
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #TMP
CREATE TABLE #TMP (Col NVarChar(MAX))
GO

DECLARE @In NVarChar(MAX), 
        @Parameters NVarChar(MAX),
        @SQL NVarChar(MAX), 
        @i Int
SELECT @In = '0', @Parameters = '@p0 Int', @SQL = '', @i = 1

WHILE @i <= 2000
BEGIN
  SET @In = @In + ',' + CONVERT(VarChar, @i)
  SET @Parameters = @Parameters + ', @p' + CONVERT(VarChar, @i) + ' Int'
  SET @i = @i + 1
END

SET @SQL = 'SELECT * FROM OrdersBig INNER JOIN CustomersBig ON OrdersBig.CustomerID = CustomersBig.CustomerID ' + 
           'WHERE OrdersBig.OrderID IN (' + REPLACE(@Parameters ,' Int', '')+ ') OPTION (RECOMPILE)'
SET @SQL = 'EXEC sp_executeSQL N' + '''' + @SQL + '''' + ', N' + '''' + @Parameters + '''' + ', ' + @In 

--SELECT @SQL

INSERT INTO #TMP VALUES(@SQL)
GO
DBCC FREEPROCCACHE()
GO

DECLARE @SQL VarChar(MAX)
SELECT @SQL = Col 
  FROM #TMP

-- Return plan with merge interval
SET STATISTICS TIME ON
EXEC (@SQL)
SET STATISTICS TIME OFF
GO
/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

/*
  Table sample
  sp_spaceused TMP_bl_cargo_OriginalDataTypes
  GO
  sp_spaceused TMP_bl_cargo_DataTypeChanged_1

  DBCC SHOWCONTIG(TMP_bl_cargo_OriginalDataTypes)
  GO
  DBCC SHOWCONTIG(TMP_bl_cargo_DataTypeChanged_1)
*/

SET NOCOUNT ON;

IF OBJECT_ID('TMP_Result') IS NULL
BEGIN
  CREATE TABLE TMP_Result(TableName      VarChar(200), 
                          ColumnName     VarChar(200),
                          ActualDataType VarChar(80),
                          BestDataType   VarChar(80),
                          NumberOfRows   Int,
                          PRIMARY KEY(TableName, ColumnName))
END
GO

DECLARE @TableName VarChar(200), 
        @ColumnName VarChar(200),
        @BestDataType VarChar(80),
        @ActualDataType VarChar(80),
        @NumberOfRows Int,
        @Min BigInt, 
        @Max BigInt,
        @MinDate Datetime,
        @MaxDate Datetime,
        @Sql NVarChar(MAX)

DECLARE TMP_Cursor CURSOR READ_ONLY FOR
SELECT Object_Name(syscolumns.id) AS TableName,
       syscolumns.Name AS ColumnName,
       systypes.name AS DataTypeName,
       sysindexes.Rowcnt AS NumberOfRows
  FROM syscolumns WITH(NOLOCK)
 INNER JOIN systypes WITH(NOLOCK)
    ON syscolumns.xtype = systypes.xtype
 INNER JOIN sysobjects WITH(NOLOCK)
    ON syscolumns.id = sysobjects.id
 INNER JOIN sysindexes WITH(NOLOCK)
    ON sysobjects.id = sysindexes.id
   AND indid <=1
 WHERE systypes.name IN ('TinyInt', 'SmallInt', 'Int', 'BigInt', 'DateTime')
   AND sysobjects.xtype = 'U'
   AND sysindexes.rowcnt > 0
   AND NOT EXISTS(SELECT 1 
                    FROM TMP_Result
                   WHERE TMP_Result.TableName = Object_Name(syscolumns.id)
                     AND TMP_Result.ColumnName = syscolumns.Name)
 UNION ALL
SELECT Object_Name(syscolumns.id) AS TableName,
       syscolumns.Name AS ColumnName,
       systypes.name AS DataTypeName,
       sysindexes.Rowcnt AS NumberOfRows
  FROM syscolumns WITH(NOLOCK)
 INNER JOIN systypes WITH(NOLOCK)
    ON syscolumns.xtype = systypes.xtype
 INNER JOIN sysobjects WITH(NOLOCK)
    ON syscolumns.id = sysobjects.id
 INNER JOIN sysindexes WITH(NOLOCK)
    ON sysobjects.id = sysindexes.id
   AND indid <=1
 WHERE systypes.name IN ('VarChar')
   AND sysobjects.xtype = 'U'
   AND sysindexes.rowcnt > 0
   AND syscolumns.length = 1
   AND NOT EXISTS(SELECT 1 
                    FROM TMP_Result
                   WHERE TMP_Result.TableName = Object_Name(syscolumns.id)
                     AND TMP_Result.ColumnName = syscolumns.Name)
 ORDER BY 4 ASC

OPEN TMP_Cursor;

FETCH NEXT FROM TMP_Cursor
INTO @TableName, @ColumnName, @ActualDataType, @NumberOfRows;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @ActualDataType IN ('TinyInt', 'SmallInt', 'Int', 'BigInt')
  BEGIN
    SELECT @Min = 0, @Max = 0
    
    SET @Sql = N'SELECT @MinOut = MIN('+@ColumnName+'), @MaxOut = MAX('+@ColumnName+')'+
                 ' FROM ' +@TableName+
                ' WHERE ' +@ColumnName+ ' IS NOT NULL';
                
    RAISERROR (@Sql, 0, 0) WITH NOWAIT

    EXECUTE sp_executesql @Sql,
                          N'@MaxOUT BigInt OUTPUT, @MinOUT BigInt OUTPUT', 
                          @MinOut = @Min OUTPUT,
                          @MaxOut = @Max OUTPUT;

    SELECT @BestDataType = CASE 
                             WHEN [TinyInt]  = 'Yes' THEN 'TyniInt'
                             WHEN [SmallInt] = 'Yes' THEN 'SmallInt'
                             WHEN [Int]      = 'Yes' THEN 'Int'
                             WHEN [BigInt]   = 'Yes' THEN 'BigInt'
                             ELSE 'All "values" are NULLs'
                           END
      FROM (SELECT CASE
                     WHEN (@Min BETWEEN -9223372036854775808 AND 9223372036854775807) AND
                          (@Max BETWEEN -9223372036854775808 AND 9223372036854775807) THEN 'Yes'
                   END AS [BigInt],
                   CASE 
                     WHEN (@Min BETWEEN -2147483648 AND 2147483647) AND
                          (@Max BETWEEN -2147483648 AND 2147483647) THEN 'Yes'
                   END AS [Int],
                   CASE 
                     WHEN (@Min BETWEEN -32768 AND 32767) AND
                          (@Max BETWEEN -32768 AND 32767) THEN 'Yes'
                   END AS [SmallInt],
                   CASE 
                     WHEN (@Min BETWEEN 0 AND 255) AND
                          (@Max BETWEEN 0 AND 255) THEN 'Yes'
                   END AS [TinyInt]) AS Tab
  END
  ELSE IF @ActualDataType IN ('DateTime')
  BEGIN
    SELECT @Min = 0, @Max = 0
    
    SET @Sql = N'SELECT @MinOut = MIN('+@ColumnName+'), @MaxOut = MAX('+@ColumnName+')'+
                 ' FROM ' +@TableName+
                ' WHERE ' +@ColumnName+ ' IS NOT NULL';
                
    RAISERROR (@Sql, 0, 0) WITH NOWAIT

    EXECUTE sp_executesql @Sql,
                          N'@MaxOUT DateTime OUTPUT, @MinOUT DateTime OUTPUT', 
                          @MinOut = @MinDate OUTPUT,
                          @MaxOut = @MaxDate OUTPUT;

    SELECT @BestDataType = CASE 
                             WHEN [SmallDateTime] = 'Yes' THEN 'SmallDateTime'
                             WHEN [SmallDateTime] = 'No' THEN 'DateTime'
                             ELSE 'All "values" are NULLs'
                           END
      FROM (SELECT CASE
                     WHEN (@MinDate BETWEEN '19000101' AND '20790606') AND
                          (@MaxDate BETWEEN '19000101' AND '20790606') THEN 'Yes'
                   END AS [SmallDateTime]) AS Tab    
  END
  ELSE IF @ActualDataType = 'VarChar'
  BEGIN
    SET @BestDataType = 'Char'
  END

  INSERT INTO TMP_Result (TableName,
                          ColumnName,
                          ActualDataType,
                          BestDataType,
                          NumberOfRows)
  SELECT @TableName, 
         @ColumnName,
         @ActualDataType,
         @BestDataType,
         @NumberOfRows
  
  FETCH NEXT FROM TMP_Cursor
  INTO @TableName, @ColumnName, @ActualDataType, @NumberOfRows;
END;

CLOSE TMP_Cursor;
DEALLOCATE TMP_Cursor;
GO


---------------------------------------------------------------------

SELECT SUM((((EstimatedSavedSpace * NumberOfRows) / 1024.) / 1024.)) AS EstimatedSavedSpaceInMB
  FROM (SELECT *,
               CASE 
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'Int' THEN 4
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'SmallInt' THEN 6
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'TyniInt' THEN 7
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'SmallInt' THEN 2
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'TyniInt' THEN 3
                 WHEN ActualDataType = 'SmallInt' AND BestDatatype = 'TyniInt' THEN 1
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'SmallDateTime' THEN 4
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'All "values" are NULLs' THEN 4
                 WHEN ActualDataType = 'VarChar' AND BestDatatype = 'Char' THEN 2
                 ELSE 0
               END AS EstimatedSavedSpace
          FROM TMP_Result WITH(NOLOCK)
         WHERE ActualDataType <> BestDataType) AS Tab
GO
SELECT TableName, SUM((((EstimatedSavedSpace * NumberOfRows) / 1024.) / 1024.)) AS EstimatedSavedSpaceInMB
  FROM (SELECT *,
               CASE 
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'Int' THEN 4
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'SmallInt' THEN 6
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'TyniInt' THEN 7
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'SmallInt' THEN 2
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'TyniInt' THEN 3
                 WHEN ActualDataType = 'SmallInt' AND BestDatatype = 'TyniInt' THEN 1
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'SmallDateTime' THEN 4
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'All "values" are NULLs' THEN 4
                 WHEN ActualDataType = 'VarChar' AND BestDatatype = 'Char' THEN 2
                 ELSE 0
               END AS EstimatedSavedSpace
          FROM TMP_Result WITH(NOLOCK)
         WHERE ActualDataType <> BestDataType) AS Tab
 GROUP BY TableName
 ORDER BY EstimatedSavedSpaceInMB DESC
GO
SELECT *, (((EstimatedSavedSpace * NumberOfRows) / 1024.) / 1024.) AS EstimatedSavedSpaceInMB
  FROM (SELECT *,
               CASE 
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'Int' THEN 4
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'SmallInt' THEN 6
                 WHEN ActualDataType = 'BigInt' AND BestDatatype = 'TyniInt' THEN 7
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'SmallInt' THEN 2
                 WHEN ActualDataType = 'Int' AND BestDatatype = 'TyniInt' THEN 3
                 WHEN ActualDataType = 'SmallInt' AND BestDatatype = 'TyniInt' THEN 1
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'SmallDateTime' THEN 4
                 WHEN ActualDataType = 'DateTime' AND BestDatatype = 'All "values" are NULLs' THEN 4
                 WHEN ActualDataType = 'VarChar' AND BestDatatype = 'Char' THEN 2
                 ELSE 0
               END AS EstimatedSavedSpace
          FROM TMP_Result WITH(NOLOCK)
         WHERE ActualDataType <> BestDataType) AS Tab
 ORDER BY NumberOfRows DESC
GO
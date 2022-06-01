USE Northwind
GO

SET NOCOUNT ON;

-- Collect BP usage before compression estimate... 
IF OBJECT_ID('tempdb.dbo.#tmpBufferDescriptors') IS NOT NULL 
  DROP TABLE #tmpBufferDescriptors

SELECT allocation_unit_id, 
        (count(*) * 8) / 1024. as CacheSizeMB, 
        (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS FreeSpaceMB
  INTO #tmpBufferDescriptors
  FROM sys.dm_os_buffer_descriptors
 WHERE dm_os_buffer_descriptors.database_id = db_id()
   AND dm_os_buffer_descriptors.page_type in ('data_page', 'index_page')
 GROUP BY allocation_unit_id

CREATE CLUSTERED INDEX ix1 ON #tmpBufferDescriptors (Allocation_unit_id)


DECLARE @default_ff INT,
        @statusMsg  VARCHAR(MAX) = '',
        @tableCount INT,
        @i          INT = 0,
        @EstimateNoneCompression CHAR(1) = 'N', -- SET to 'Y' to test NONE compression option
        @TabName VARCHAR(2000) = NULL --'interf_nfe'; -- Leave this NULL to run script for all Objs

SELECT @default_ff = CASE
                         WHEN value_in_use = 0 THEN
                             100
                         ELSE
                             CONVERT(INT, value_in_use)
                     END
FROM sys.configurations WITH (NOLOCK)
WHERE name = 'fill factor (%)';

IF OBJECT_ID('tempdb..#ObjEst') IS NOT NULL
    DROP TABLE #ObjEst;

CREATE TABLE #ObjEst
(
    PK INT IDENTITY NOT NULL PRIMARY KEY,
    object_name VARCHAR(250),
    schema_name VARCHAR(250),
    index_id INT,
    partition_number INT,
    size_with_current_compression_setting BIGINT,
    size_with_requested_compression_setting BIGINT,
    sample_size_with_current_compression_setting BIGINT,
    sample_size_with_requested_compresison_setting BIGINT
);

IF OBJECT_ID('tempdb..#dbEstimate') IS NOT NULL
    DROP TABLE #dbEstimate;

CREATE TABLE #dbEstimate
(
    PK INT IDENTITY NOT NULL PRIMARY KEY,
    objectid INT,
    schema_name VARCHAR(250),
    object_name VARCHAR(250),
    index_id INT,
    index_fill_factor INT,
    ixName VARCHAR(255),
    ixType VARCHAR(50),
    partition_number INT,
    data_compression_desc VARCHAR(50),
    None_Size INT,
    Row_Size INT,
    Page_Size INT,
    Current_Size INT
);

INSERT INTO #dbEstimate
(
    objectid,
    schema_name,
    object_name,
    index_id,
    ixName,
    index_fill_factor,
    ixType,
    partition_number,
    data_compression_desc
)
SELECT o.object_id,
       S.name,
       O.name,
       I.index_id,
       I.name,
       CASE
           WHEN I.fill_factor = 0 THEN
               @default_ff
           ELSE
               I.fill_factor
       END,
       I.type_desc,
       P.partition_number,
       P.data_compression_desc
FROM sys.schemas AS S
    INNER JOIN sys.objects AS O
        ON S.schema_id = O.schema_id
    INNER JOIN sys.indexes AS I
        ON O.object_id = I.object_id
    INNER JOIN sys.partitions AS P
        ON I.object_id = P.object_id
           AND I.index_id = P.index_id
WHERE O.type = 'U'
  AND (o.name = @TabName OR @TabName IS NULL);

SELECT @tableCount = COUNT(*) FROM #dbEstimate;

-- Determine Compression Estimates
DECLARE @PK INT,
        @ObjectID INT,
        @Schema VARCHAR(150),
        @object VARCHAR(250),
        @DAD VARCHAR(25),
        @partNO INT,
        @indexID INT,
        @SQL NVARCHAR(MAX),
        @ixName VARCHAR(250);

DECLARE cCompress CURSOR FAST_FORWARD READ_ONLY FOR
SELECT schema_name,
       object_name,
       index_id,
       ixName,
       partition_number,
       data_compression_desc
FROM #dbEstimate;

OPEN cCompress;

FETCH cCompress
INTO @Schema,
     @object,
     @indexID,
     @ixName,
     @partNO,
     @DAD; -- prime the cursor

WHILE @@Fetch_Status = 0
BEGIN
    SET @i = @i + 1;

    SET @statusMsg = 'Working on ' + CAST(@i AS VARCHAR(10)) 
        + ' of ' + CAST(@tableCount AS VARCHAR(10)) + ' obj = ' + @object + '.' + ISNULL(@ixName,'HEAP')

    IF @DAD = 'COLUMNSTORE'
    BEGIN
      SET @statusMsg = 'Working on ' + CAST(@i AS VARCHAR(10)) 
          + ' of ' + CAST(@tableCount AS VARCHAR(10)) + ' Skipping obj as it is set to ColumnStore = ' + @object + '.' + ISNULL(@ixName,'HEAP')
    END

    SET @statusMsg = REPLACE(REPLACE(@statusMsg, CHAR(13), ''), CHAR(10), '')
    RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;

    BEGIN TRY   
      IF @DAD = 'none'
      BEGIN
          -- estimate Page compression
          INSERT #ObjEst
          (
              object_name,
              schema_name,
              index_id,
              partition_number,
              size_with_current_compression_setting,
              size_with_requested_compression_setting,
              sample_size_with_current_compression_setting,
              sample_size_with_requested_compresison_setting
          )
          EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                    @object_name = @object,
                                                    @index_id = @indexID,
                                                    @partition_number = @partNO,
                                                    @data_compression = 'page';

          UPDATE #dbEstimate
          SET None_Size = O.size_with_current_compression_setting,
              Page_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;

          -- estimate Row compression
          INSERT #ObjEst
          (
              object_name,
              schema_name,
              index_id,
              partition_number,
              size_with_current_compression_setting,
              size_with_requested_compression_setting,
              sample_size_with_current_compression_setting,
              sample_size_with_requested_compresison_setting
          )
          EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                    @object_name = @object,
                                                    @index_id = @indexID,
                                                    @partition_number = @partNO,
                                                    @data_compression = 'row';

          UPDATE #dbEstimate
          SET Row_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;
      END; -- none compression estimate     

      IF @DAD = 'row'
      BEGIN
          -- estimate Page compression
          INSERT #ObjEst
          (
              object_name,
              schema_name,
              index_id,
              partition_number,
              size_with_current_compression_setting,
              size_with_requested_compression_setting,
              sample_size_with_current_compression_setting,
              sample_size_with_requested_compresison_setting
          )
          EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                    @object_name = @object,
                                                    @index_id = @indexID,
                                                    @partition_number = @partNO,
                                                    @data_compression = 'page';

          UPDATE #dbEstimate
          SET Row_Size = O.size_with_current_compression_setting,
              Page_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;

          IF @EstimateNoneCompression = 'Y'
          BEGIN
            -- estimate None compression
            INSERT #ObjEst
            (
                object_name,
                schema_name,
                index_id,
                partition_number,
                size_with_current_compression_setting,
                size_with_requested_compression_setting,
                sample_size_with_current_compression_setting,
                sample_size_with_requested_compresison_setting
            )
            EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                      @object_name = @object,
                                                      @index_id = @indexID,
                                                      @partition_number = @partNO,
                                                      @data_compression = 'none';
          END

          UPDATE #dbEstimate
          SET None_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;
      END; -- row compression estimate    

      IF @DAD = 'page'
      BEGIN
          -- estimate Row compression
          INSERT #ObjEst
          (
              object_name,
              schema_name,
              index_id,
              partition_number,
              size_with_current_compression_setting,
              size_with_requested_compression_setting,
              sample_size_with_current_compression_setting,
              sample_size_with_requested_compresison_setting
          )
          EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                    @object_name = @object,
                                                    @index_id = @indexID,
                                                    @partition_number = @partNO,
                                                    @data_compression = 'row';

          UPDATE #dbEstimate
          SET Page_Size = O.size_with_current_compression_setting,
              Row_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;

          IF @EstimateNoneCompression = 'Y'
          BEGIN
            -- estimate None compression
            INSERT #ObjEst
            (
                object_name,
                schema_name,
                index_id,
                partition_number,
                size_with_current_compression_setting,
                size_with_requested_compression_setting,
                sample_size_with_current_compression_setting,
                sample_size_with_requested_compresison_setting
            )
            EXEC sp_estimate_data_compression_savings @schema_name = @Schema,
                                                      @object_name = @object,
                                                      @index_id = @indexID,
                                                      @partition_number = @partNO,
                                                      @data_compression = 'none';
          END

          UPDATE #dbEstimate
          SET None_Size = O.size_with_requested_compression_setting
          FROM #dbEstimate D
              INNER JOIN #ObjEst O
                  ON D.schema_name = O.schema_name
                     AND D.object_name = O.object_name
                     AND D.index_id = O.index_id
                     AND D.partition_number = O.partition_number;

          DELETE #ObjEst;
      END; -- page compression estimate
	   END TRY
    BEGIN CATCH
      SET @statusMsg = 'Error processing obj ' + @object + '.' + ISNULL(@ixName,'HEAP') + ' skipping this obj... ErrMsg = ' + ERROR_MESSAGE()
      RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;
    END CATCH

    FETCH cCompress
    INTO @Schema,
         @object,
         @indexID,
         @ixName,
         @partNO,
         @DAD;
END;

CLOSE cCompress;

DEALLOCATE cCompress;


DELETE FROM #dbEstimate
WHERE ixType = 'NONCLUSTERED COLUMNSTORE'

UPDATE #dbEstimate SET Current_Size = t.col1
FROM #dbEstimate 
CROSS APPLY (select sum((st.reserved_page_count * 8))  col1 from sys.dm_db_partition_stats st
    where #dbEstimate.objectid = st.object_id
   AND #dbEstimate.index_id = st.index_id) as t

UPDATE #dbEstimate SET Current_Size = 1 WHERE Current_Size = 0
UPDATE #dbEstimate SET None_Size = 1 WHERE None_Size = 0
UPDATE #dbEstimate SET Row_Size  = 1 WHERE Row_Size  = 0
UPDATE #dbEstimate SET Page_Size = 1 WHERE Page_Size = 0


SET @statusMsg = 'Collecting index fragmentation info...'
RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;



IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL 
  DROP TABLE #tmp1


SELECT * 
  INTO #tmp1 
  FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')
 WHERE dm_db_index_physical_stats.alloc_unit_type_desc = 'IN_ROW_DATA'



CREATE NONCLUSTERED INDEX ix1
ON [dbo].#dbEstimate ([objectid],[index_id])
INCLUDE ([schema_name],[object_name],[index_fill_factor],[ixName],[ixType],[partition_number],[data_compression_desc],[None_Size],[Row_Size],[Page_Size])

CREATE CLUSTERED INDEX ix1
ON [dbo].#tmp1 ([object_id],[index_id])

-- report findings
SELECT schema_name + '.' + object_name AS ObjectName,
       #dbEstimate.index_id AS IndexID,
       ixName AS IndexName,
       ixType AS IndexType,
       #dbEstimate.partition_number AS PartitionNumber,
       st.row_count AS "RowCount",
       ISNULL(dm_db_index_usage_stats.user_seeks,0) AS user_seeks,
       ISNULL(dm_db_index_usage_stats.user_scans,0) AS user_scans,
       ISNULL(dm_db_index_usage_stats.user_lookups,0) AS user_lookups,
       ISNULL(dm_db_index_usage_stats.user_updates,0) AS user_updates,
       ISNULL(dm_db_index_usage_stats.user_seeks,0) + ISNULL(dm_db_index_usage_stats.user_scans,0) + ISNULL(dm_db_index_usage_stats.user_lookups,0) + ISNULL(dm_db_index_usage_stats.user_updates,0) AS total_reads,
       ISNULL(ios.page_latch_wait_count,0) AS page_latch_wait_count, -- Cumulative number of times the Database Engine waited, because of latch contention.
       ISNULL(ios.page_io_latch_wait_count,0) AS page_io_latch_wait_count, -- Cumulative number of times the Database Engine waited on an I/O page latch. 
       data_compression_desc AS CurrentCompression,
	      ROUND((CAST(Current_Size AS Numeric(18,2)) / 1024), 2) AS 'CurrentSize_MB',
       ROUND((CAST(None_Size AS Numeric(18,2)) / 1024), 2) AS 'EstimatedCompression_None_MB',
       ROUND((CAST(Row_Size AS Numeric(18,2)) / 1024), 2) AS 'EstimatedCompression_Row_MB',
       ROUND(CAST(Page_Size AS Numeric(18,2)) / 1024, 2) AS 'EstimatedCompression_Page_MB',
       index_fill_factor AS 'CurrentFillFactor',
       indexstats.avg_fragmentation_in_percent AS 'FragmentationPercent',
       ROUND((1 - (CAST(Row_Size AS Numeric(18,2)) / Current_Size)) * 100, 2) AS 'RowPercentSaving',
       ROUND((1 - (CAST(Page_Size AS Numeric(18,2)) / Current_Size)) * 100, 2) AS 'PagePercentSaving',
       Tab1.Compressao_Recomendada AS 'RecomendedCompression',
       ISNULL(bp.CacheSizeMB,0) AS 'BufferPoolSpaceUsed_MB',
       ISNULL(bp.FreeSpaceMB,0) AS 'BufferPoolFreeSpace_MB',
       CASE ixType 
         WHEN 'HEAP' THEN 'ALTER TABLE "' + schema_name + '"."' + object_name + '" REBUILD WITH(DATA_COMPRESSION=' + Tab1.Compressao_Recomendada + ', ONLINE=ON)' 
         ELSE 'ALTER INDEX "' + ISNULL(ixName,'ALL') +'" ON "' + schema_name + '"."' + object_name + '" REBUILD WITH(DATA_COMPRESSION=' + Tab1.Compressao_Recomendada + ', ONLINE=ON)'
       END AS SqlToCompressHeap
  FROM #dbEstimate
 INNER JOIN (SELECT object_id as objectid,
                    object_name(object_id) as name,
                    allocation_unit_id,
                    p.index_id,
                    au.type_desc
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.hobt_id) as obj
    ON #dbEstimate.objectid = obj.objectid
   AND #dbEstimate.index_id = obj.index_id
 INNER JOIN sys.dm_db_partition_stats st
    ON #dbEstimate.objectid = st.object_id
   AND #dbEstimate.index_id = st.index_id
  LEFT OUTER JOIN #tmpBufferDescriptors as bp
    ON bp.allocation_unit_id = obj.allocation_unit_id
  LEFT OUTER JOIN #tmp1 indexstats
    ON #dbEstimate.objectid = indexstats.object_id
   AND #dbEstimate.index_id = indexstats.index_id
  LEFT OUTER JOIN sys.dm_db_index_usage_stats dm_db_index_usage_stats WITH (NOLOCK) 
    ON dm_db_index_usage_stats.index_id = obj.index_id
   AND dm_db_index_usage_stats.object_id = obj.objectid
   AND dm_db_index_usage_stats.database_id = DB_ID()
 OUTER APPLY sys.dm_db_index_operational_stats(DB_ID(), obj.objectid, obj.index_id, NULL) AS ios
  CROSS APPLY (SELECT CASE
                          WHEN (1 - (CAST(Row_Size AS Numeric(18,2)) / Current_Size)) >= .10
                               AND (Row_Size <= Page_Size) THEN
                              'Row'
                          WHEN (1 - (CAST(Page_Size AS Numeric(18,2)) / Current_Size)) >= .10
                               AND (Page_Size <= Row_Size) THEN
                              'Page'
                          ELSE
                              data_compression_desc
                      END AS Compressao_Recomendada) AS Tab1
  WHERE obj. type_desc = 'IN_ROW_DATA'
    --AND indexstats.page_count > 1000 -- Only tables greater than 1k pages...
    --AND (ROUND((1 - (CAST(Row_Size AS FLOAT) / None_Size)) * 100, 2) >= 10 OR ROUND((1 - (CAST(Page_Size AS FLOAT) / None_Size)) * 100, 2) >= 10) -- Only indexes with compression % >= 10%
ORDER BY CurrentSize_MB DESC
GO


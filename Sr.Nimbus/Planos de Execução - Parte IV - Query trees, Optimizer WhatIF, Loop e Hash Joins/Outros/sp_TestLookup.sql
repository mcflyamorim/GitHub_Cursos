USE NorthWind
GO
IF OBJECT_ID('sp_TestLookup') IS NOT NULL
BEGIN
  DROP PROCEDURE dbo.sp_TestLookup
END
GO
CREATE PROCEDURE dbo.sp_TestLookup @Table_Name   VarChar(200),
                                   @Lookup_Index VarChar(200),
                                   @Trace_Path   NVarChar(200)

AS
BEGIN

/*
Author: Fabiano Neves Amorim
E-Mail: fabiano_amorim@bol.com.br
http://fabianosqlserver.spaces.live.com/
http://www.simple-talk.com/author/fabiano-amorim/

Use:

EXEC dbo.sp_TestLookup @Table_Name   = 'Produtos',
                       @Lookup_Index = '[ix_Descricao_Produto]',
                       @Trace_Path   = 'C:\TesteTrace.trc'

*/

  BEGIN TRY
    SET NOCOUNT ON;
    
    IF OBJECT_ID(@Table_Name) IS NULL
    BEGIN
      RAISERROR ('Specified table do not exists', 16, 0);
    END

    IF INDEXPROPERTY(OBJECT_ID(@Table_Name), @Lookup_Index, 'IsClustered') <> 0
    BEGIN
      RAISERROR ('Specified index must be a nonclustered index', 16,0);
    END    
    ---------------------------------------------------------
    --------------- Drop temp tables ------------------------
    ---------------------------------------------------------

    IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
    BEGIN
      DROP TABLE #tmp
    END
    IF OBJECT_ID('tempdb.dbo.#tmp_1') IS NOT NULL
    BEGIN
      DROP TABLE #tmp_1
    END
    IF OBJECT_ID('tempdb.dbo.#tmp_2') IS NOT NULL
    BEGIN
      DROP TABLE #tmp_2
    END
    IF OBJECT_ID('tempdb.dbo.#tb_Results') IS NOT NULL
    BEGIN
      DROP TABLE #tb_Results
    END
    CREATE TABLE #tmp_2 (Total_Rows Int)

    ---------------------------------------------------------
    --------------- Create trace file -----------------------
    ---------------------------------------------------------
    DECLARE @TraceID  Int, 
            @Str      VarChar(MAX),
            @Msg      VarChar(MAX),
            @CmdShell VarChar(200)
            
    -- Delete the tracefile
    SET @CmdShell = 'del ' + @Trace_Path
    EXEC xp_cmdShell @CmdShell, no_output

    SET @Trace_Path = REPLACE(@Trace_Path, '.trc','')
    
    -- Start Trace
    EXEC sys.sp_trace_create @TraceID output, 0, @Trace_Path
    
    SET @Trace_Path = @Trace_Path + '.trc'
    
    -- Set Events
    -- 10 is RPC:Completed event. 1 is TextData column
    EXEC sys.sp_trace_setevent @TraceID, 45, 16, 1
    -- 13 is SQL:BatchStarting, 1 is TextData column
    EXEC sys.sp_trace_setevent @TraceID, 45, 1, 1 
    -- Set Filter to actual session
    SET @Str = 'EXEC sys.sp_trace_setfilter '+ Convert(VarChar, @TraceID) +' , 12, 0, 0, ' + Convert(VarChar, @@SPID)
    EXEC (@str)
    -- Start Trace (status 1 = start)
    EXEC sys.sp_trace_setstatus @TraceID, 1


    ---------------------------------------------------------
    --------------- Start fullscan read ---------------------
    ---------------------------------------------------------
    DECLARE @i             Int,
            @percent       Int,
            @Total_Rows    Int,
            @Scan_IO       Int,
            @Key_Lookup_IO Int,
            @Points        VarChar(MAX),
            @Str_Col       VarChar(500),
            @Col           VarChar(200)
            
    -- Looking for a column that are not in nonclustered and clustered index
    SELECT TOP 1 
           @Str_Col = 'DECLARE @' + c.name + ' ' + t.name,
           @Col     = c.Name
      FROM sys.columns c
     INNER JOIN sys.types t
        ON c.system_type_id = t.system_type_id
     WHERE c.column_id NOT IN (SELECT ic.column_id
                                 FROM sys.indexes i
                                INNER JOIN sys.index_columns ic
                                   ON i.object_id = ic.object_id
                                  AND i.index_id = ic.index_id
                                WHERE (i.name = @Lookup_Index OR i.type = 1)
                                  AND OBJECT_NAME(i.object_id) = @Table_Name)
       AND OBJECT_NAME(c.object_id) = @Table_Name       
    
    IF ISNULL(@Col,'') = ''
    BEGIN
      RAISERROR ('There is no "nonclustered/clustered" column', 16, 0);
    END
           
    -- Run a scan at @Table_Name
    SET @Str = 'SELECT COUNT(*) AS Count_Rows FROM ' + QUOTENAME(@Table_Name) + 'WITH(INDEX=0) OPTION (MAXDOP 1) -- ;fullscan;';

    INSERT INTO #tmp_2(Total_Rows)
    EXEC (@Str)

    SELECT @Total_Rows = Total_Rows 
      FROM #tmp_2

    -- Get the number of Reads
    SELECT @Scan_IO = Reads
      FROM ::fn_trace_gettable(@Trace_Path, 1)
     WHERE TextData like '%;fullscan;%'
     
    ---------------------------------------------------------
    --------------- Start lookup tests ----------------------
    ---------------------------------------------------------
    SET @Msg = 'Logical Reads to Scan ' + Convert(VarChar, @Total_Rows) + ' rows of table ' + @Table_Name + ': ' + Convert(VarChar, @Scan_IO)
    RAISERROR (@Msg, 0,0) WITH NOWAIT
    
    SET @Points = CHAR(13) + REPLICATE('*', SubString(Convert(VarChar,@Scan_IO),1, LEN(Convert(VarChar,@Scan_IO)) -2)) + ' Scan'
    SET @Key_Lookup_IO = 0;
    SET @i = 0;
    SET @percent = 1;

    WHILE @Scan_IO >= @Key_Lookup_IO
    BEGIN
      SET @i = CONVERT(Numeric(18,2),(@Total_Rows * @percent) / 1000,2)

      -- Run partial scan at @Table_Name
      SET @Str = @Str_Col +
                 ' SELECT TOP '+ Convert(VarChar,@i) + ' @' + @Col +' = ' + @Col +' FROM ' + QUOTENAME(@Table_Name) + 
                 ' WITH(INDEX='+ QUOTENAME(@Lookup_Index) +') OPTION (MAXDOP 1) -- ;partialscan ' + Convert(VarChar,@i) + ';';
      EXEC (@Str)

      -- Get the number of Reads
      SELECT @Key_Lookup_IO = Reads
        FROM ::fn_trace_gettable(@Trace_Path, 1)
       WHERE TextData like '%;partialscan ' + Convert(VarChar,@i) + ';%'

      IF @Scan_IO > @Key_Lookup_IO
      BEGIN
        SET @Msg = 'GoodPlan - Logical Reads to Lookup ' + Convert(VarChar,@i)+ 
                   '('+ CONVERT(VarChar(20), CONVERT(Numeric(18,1), CONVERT(Numeric(18,2), @i) / CONVERT(Numeric(18,1), @Total_Rows) * 100)) +'%%) rows ' +
                   'of table : ' + Convert(VarChar,@Key_Lookup_IO) 

        RAISERROR (@Msg, 0,0) WITH NOWAIT
        IF LEN(Convert(VarChar,@Key_Lookup_IO)) > 2
        BEGIN
          SET @Points = @Points + CHAR(13) + REPLICATE('*', SubString(Convert(VarChar,@Key_Lookup_IO),1, LEN(Convert(VarChar,@Key_Lookup_IO)) -2))
        END
      END
      ELSE
      BEGIN
        SET @Msg = 'BadPlan - Logical Reads to Lookup ' + Convert(VarChar,@i) +
                   '('+ CONVERT(VarChar(20), CONVERT(Numeric(18,1), CONVERT(Numeric(18,2), @i) / CONVERT(Numeric(18,1), @Total_Rows) * 100)) +'%%) rows ' +
                   'of table : ' + Convert(VarChar,@Key_Lookup_IO) 
        RAISERROR (@Msg, 0,0) WITH NOWAIT
        IF LEN(Convert(VarChar,@Key_Lookup_IO)) > 2
        BEGIN
          SET @Points = @Points + CHAR(13) + REPLICATE('*', SubString(Convert(VarChar,@Key_Lookup_IO),1, LEN(Convert(VarChar,@Key_Lookup_IO)) -2))
        END
      END

      SET @percent = @percent + 1;
    END
    PRINT @Points    


    -----------------------------------------------------------------
    --------------- Stop and Close trace ----------------------------
    -----------------------------------------------------------------

    -- Populate a variable with the trace_id of the current trace
    SELECT  @TraceID = TraceID 
      FROM ::fn_trace_getinfo(default) WHERE VALUE = @Trace_Path

    -- First stop the trace. 
    EXEC sp_trace_setstatus @TraceID, 0

    -- Close and then delete its definition from SQL Server. 
    EXEC sp_trace_setstatus @TraceID, 2
    
    -- Delete the tracefile
    SET @CmdShell = 'del ' + @Trace_Path
    EXEC xp_cmdShell @CmdShell, no_output

  END TRY
  BEGIN CATCH
    -----------------------------------------------------------------
    --------------- Stop and Close trace ----------------------------
    -----------------------------------------------------------------
    -- Delete the tracefile
    SET @CmdShell = 'del ' + @Trace_Path
    EXEC xp_cmdShell @CmdShell, no_output
    
    -- Populate a variable with the trace_id of the current trace
    SELECT @TraceID = TraceID 
      FROM ::fn_trace_getinfo(default) WHERE VALUE = @Trace_Path
    
    IF ISNULL(@TraceID,0) <> 0
    BEGIN
      -- First stop the trace. 
      EXEC sp_trace_setstatus @TraceID, 0

      -- Close and then delete its definition from SQL Server. 
      EXEC sp_trace_setstatus @TraceID, 2
    END

    -- Execute error retrieval routine.
    SELECT ERROR_NUMBER()    AS ErrorNumber,
           ERROR_SEVERITY()  AS ErrorSeverity,
           ERROR_STATE()     AS ErrorState,
           ERROR_PROCEDURE() AS ErrorProcedure,
           ERROR_LINE()      AS ErrorLine,
           ERROR_MESSAGE()   AS ErrorMessage;
  END CATCH;
END
GO
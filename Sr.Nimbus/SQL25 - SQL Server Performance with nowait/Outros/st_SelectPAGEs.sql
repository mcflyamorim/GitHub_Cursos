/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

IF OBJECT_ID('st_SelectPAGEs') IS NOT NULL
BEGIN
  DROP PROCEDURE dbo.st_SelectPAGEs
END
GO

CREATE PROCEDURE dbo.st_SelectPAGEs(@Object_ID Int,  @Qtde_Pages Int = 100)
AS
BEGIN
/*
Original Version: John Huang's

Revised by: Fabiano Neves Amorim
E-Mail: fabiano_amorim@bol.com.br
http://fabianosqlserver.spaces.live.com/
http://www.simple-talk.com/author/fabiano-amorim/

Use:

DECLARE @i Int
SET @i = Object_ID('<TABELA>')

EXEC dbo.st_SelectPAGEs @Object_ID = @i, @Qtde_Pages = 10000
*/

  BEGIN TRY
    SET NOCOUNT ON
      
    IF NOT EXISTS(SELECT 1 FROM sysobjects where id = @Object_ID)
    BEGIN
      RAISERROR ('Specified object do not exists', -- Message text.  
                 30002, -- Severity.  
                 1 -- State.
                )
    END
    
    DECLARE @SQL VarChar(Max),
            @PageFID SmallInt, 
            @PagePID Integer
      
    CREATE TABLE #DBCC_IND_SQL2005_2008(ROWID           Integer IDENTITY(1,1) PRIMARY KEY, 
                                        PageFID         SmallInt, 
                                        PagePID         Integer, 
                                        IAMFID          Integer, 
                                        IAMPID          Integer, 
                                        ObjectID        Integer,
                                        IndexID         Integer,
                                        PartitionNumber BigInt,
                                        PartitionID     BigInt, 
                                        Iam_Chain_Type  VarChar(80), 
                                        PageType        Integer,
                                        IndexLevel      Integer,
                                        NexPageFID      Integer,
                                        NextPagePID     Integer,
                                        PrevPageFID     Integer,
                                        PrevPagePID     Integer)
                               
    CREATE TABLE #DBCC_Page(ROWID        Integer IDENTITY(1,1) PRIMARY KEY, 
                            ParentObject VarChar(500),
                            Object       VarChar(500), 
                            Field        VarChar(500), 
                            Value        VarChar(Max))

    CREATE TABLE #Results(ROWID     Integer PRIMARY KEY, 
                            Page      VarChar(100), 
                            Slot      VarChar(300), 
                            Object    VarChar(300), 
                            FieldName VarChar(300), 
                            Value     VarChar(6000))

    CREATE TABLE #Columns(ColumnID Integer PRIMARY KEY, 
                          Name     VarChar(800))

    INSERT INTO #Columns
    SELECT ColID, 
           Name
      FROM syscolumns
     WHERE id = @Object_ID

    SELECT @SQL = 'DBCC IND(' + QUOTENAME(DB_NAME()) + 
                   ', ' + 
                   CONVERT(VarChar(20), @Object_ID) +
                   ', 1) WITH NO_INFOMSGS'

--    PRINT @SQL

    DBCC TRACEON(3604) WITH NO_INFOMSGS
    INSERT INTO #DBCC_IND_SQL2005_2008
    EXEC (@SQL)
    
    DECLARE cCursor CURSOR FOR
    SELECT TOP (@Qtde_Pages)
           PageFID, 
           PagePID 
      FROM #DBCC_IND_SQL2005_2008 
     WHERE PageType = 1

    OPEN cCursor

    FETCH NEXT FROM cCursor INTO @PageFID, @PagePID 

    WHILE @@FETCH_STATUS = 0
    BEGIN
      DELETE #DBCC_Page
      
      SELECT @SQL = 'DBCC PAGE ('  + 
                     QUOTENAME(DB_NAME()) + ',' + 
                     CONVERT(VarChar(20), @PageFID) + 
                     ',' + 
                     CONVERT(VarChar(20), @PagePID) + 
                     ', 3) WITH TABLERESULTS, NO_INFOMSGS '
--      PRINT @SQL
      
      INSERT INTO #DBCC_Page
      EXEC (@SQL)
      
      DELETE FROM #DBCC_Page 
       WHERE Object NOT LIKE 'Slot %' 
          OR Field = '' 
          OR Field IN ('Record Type', 'Record Attributes') 
          OR ParentObject in ('PAGE HEADER:')
      
      INSERT INTO #Results
      SELECT ROWID, cast(@PageFID as VarChar(20)) + ':' + CAST(@PagePID as VarChar(20)), ParentObject, Object, Field, Value FROM #DBCC_Page

      FETCH NEXT FROM cCursor INTO @PageFID, @PagePID 
    END
    
    CLOSE cCursor
    DEALLOCATE cCursor
    
--    SELECT * FROM #Results

    SELECT @SQL = '
    SELECT ' + 
    STUFF(CAST((SELECT ',[' + Name + ']' 
                  FROM #Columns 
                 ORDER BY ColumnID FOR XML PATH('')) AS VarChar(MAX)), 1,1,'')+'
    FROM (SELECT CONVERT(VarChar(20), Page) + CONVERT(VarChar(500),Slot) p, FieldName x_FieldName_x, Value x_Value_x FROM #Results) Tab
    PIVOT(MAX(Tab.x_Value_x) FOR Tab.x_FieldName_x IN( ' 
          + STUFF((SELECT ',[' + Name + ']' FROM #Columns order by ColumnID for xml path('')), 1,1,'') + ' )
    ) AS pvt'

    PRINT @SQL
    EXEC (@SQL)

  END TRY
  BEGIN CATCH
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

/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Enabling CLR
sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO

-- CLR Proc
/*
using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;


public partial class StoredProcedures
{
    [Microsoft.SqlServer.Server.SqlProcedure]
    public static void CLR_GetAutoPilotShowPlan
    (
         SqlString SQL,
         out SqlXml PlanXML
    )
    {
        //Prep connection
        SqlConnection cn = new SqlConnection("Context Connection = True");

        //Set command texts
        SqlCommand cmd_SetAutoPilotOn = new SqlCommand("SET AUTOPILOT ON", cn);
        SqlCommand cmd_SetAutoPilotOff = new SqlCommand("SET AUTOPILOT OFF", cn);
        SqlCommand cmd_input = new SqlCommand(SQL.ToString(), cn);

        if (cn.State != ConnectionState.Open)
        {
            cn.Open();
        }

        //Run AutoPilot On
        cmd_SetAutoPilotOn.ExecuteNonQuery();

        //Run input SQL
        SqlDataAdapter da = new SqlDataAdapter();
        DataSet ds = new DataSet();

        da.SelectCommand = cmd_input;
        ds.Tables.Add(new DataTable("Results"));

        ds.Tables[0].BeginLoadData();
        da.Fill(ds, "Results");
        ds.Tables[0].EndLoadData();

        //Run AutoPilot Off
        cmd_SetAutoPilotOff.ExecuteNonQuery();

        if (cn.State != ConnectionState.Closed)
        {
            cn.Close();
        }

        //Package XML as output
        System.Xml.XmlDocument xmlDoc = new System.Xml.XmlDocument();
        //XML is in 1st Col of 1st Row of 1st Table
        xmlDoc.InnerXml = ds.Tables[0].Rows[0][0].ToString();
        System.Xml.XmlNodeReader xnr = new System.Xml.XmlNodeReader(xmlDoc);
        PlanXML = new SqlXml(xnr);
    }
};
*/

-- Publishing Assembly
IF EXISTS(SELECT * FROM sys.assemblies WHERE name = 'CLR_ProjectAutoPilot')
BEGIN
  IF OBJECT_ID('st_CLR_GetAutoPilotShowPlan') IS NOT NULL
    DROP PROC st_CLR_GetAutoPilotShowPlan

  DROP ASSEMBLY CLR_ProjectAutoPilot
END
GO
CREATE ASSEMBLY CLR_ProjectAutoPilot FROM 'D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL25 - SQL Server Performance with nowait\SQL25\05.3 - Plano de execução avançado - Comandos avançados\ProjectAutoPilot\ProjectAutoPilot\bin\Release\ProjectAutoPilot.dll' WITH PERMISSION_SET = SAFE
GO

CREATE PROCEDURE st_CLR_GetAutoPilotShowPlan (@Query NVarChar(MAX), @ShowPlan XML OUTPUT)
AS
  EXTERNAL NAME CLR_ProjectAutoPilot.StoredProcedures.CLR_GetAutoPilotShowPlan
GO

IF OBJECT_ID('st_TestHipotheticalIndexes', 'p') IS NOT NULL
  DROP PROC dbo.st_TestHipotheticalIndexes
GO
CREATE PROCEDURE dbo.st_TestHipotheticalIndexes (@SQLIndex NVarChar(MAX), @Query NVarChar(MAX))
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRAN
    DECLARE @CreateIndexCommand NVarChar(MAX),
            @IndexName NVarChar(MAX),
            @TableName NVarChar(MAX),
            @SQLIndexTMP NVarChar(MAX),
            @SQLDropIndex NVarChar(MAX),
            @SQLDbccAutoPilot NVarChar(MAX),
            @i Int,
            @QuantityIndex Int,
            @Xml XML

    IF SubString(@SQLIndex, LEN(@SQLIndex), 1) <> ';'
    BEGIN
      RAISERROR ('Last caracter in the index should be ;', -- Message text.
                 16, -- Severity.
                 1 -- State.
                 );
    END

    SET @SQLDropIndex = '';
    SET @QuantityIndex = LEN(@SQLIndex) - LEN(REPLACE(@SQLIndex, ';', ''))
    SELECT @SQLIndexTMP = SUBSTRING(@SQLIndex, 0, CharIndex(';', @SQLIndex))
    
    SET @i = 0
    WHILE @i < @QuantityIndex
    BEGIN
      SET @SQLIndexTMP = SUBSTRING(@SQLIndex, 0, CharIndex(';', @SQLIndex))
      SET @CreateIndexCommand = SUBSTRING(@SQLIndexTMP, 0, CharIndex(' ON ',@SQLIndexTMP))
      SET @IndexName = REVERSE(SubString(REVERSE(@CreateIndexCommand), 0, CharIndex(' ', REVERSE(@CreateIndexCommand))))
      SET @TableName = SUBSTRING(REPLACE(@SQLIndexTMP, @CreateIndexCommand + ' ON ', ''), 0, CharIndex(' ', REPLACE(@SQLIndexTMP, @CreateIndexCommand + ' ON ', '')))
      SET @SQLIndex = REPLACE(@SQLIndex, @SQLIndexTMP + ';', '')
      --SELECT @SQLIndex, @SQLIndexTMP, @CreateIndexCommand, @TableName, @IndexName
    
      -- Creating hypotetical index
      IF CharIndex('WITH STATISTICS_ONLY =', @SQLIndexTMP) = 0
      BEGIN
        SET @SQLIndexTMP = @SQLIndexTMP + ' WITH STATISTICS_ONLY = -1'
      END
      -- PRINT @SQLIndexTMP
      EXEC (@SQLIndexTMP)
      
      -- Creating query to drop the hypotetical index
      SELECT @SQLDropIndex = @SQLDropIndex + 'DROP INDEX ' + @TableName + '.' + @IndexName + '; '
      -- PRINT @SQLDropIndex
      
      -- Executing DBCC AUTOPILOT
      SET @SQLDbccAutoPilot = 'DBCC AUTOPILOT (0, ' + 
                                               CONVERT(VarChar, DB_ID()) + ', '+ 
                                               CONVERT(VarChar, OBJECT_ID(@TableName),0) + ', ' +
                                               CONVERT(VarChar, INDEXPROPERTY(OBJECT_ID(@TableName), @IndexName, 'IndexID')) + ')'

      EXEC (@SQLDbccAutoPilot)
      --PRINT @SQLDbccAutoPilot
    
      SET @i = @i + 1
    END
    
    -- Executing Query
    DECLARE @PlanXML xml

    EXEC st_CLR_GetAutoPilotShowPlan @Query = @Query, 
                                     @ShowPlan = @PlanXML OUT
    SELECT @PlanXML
    
    -- Droping the indexes
    EXEC (@SQLDropIndex)
    
    COMMIT TRAN
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN
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

/*
-- Exemplo 1
EXEC dbo.st_TestHipotheticalIndexes @SQLIndex = 'CREATE INDEX ix_12 ON Products (Unitprice, CategoryID, SupplierID) INCLUDE(ProductName);CREATE INDEX ix_Quantity ON Order_Details (Quantity);', 
                                    @Query = 'SELECT p.ProductName, p.UnitPrice, s.CompanyName, s.Country, od.quantity
                                                FROM Products as P
                                               INNER JOIN Suppliers as S
                                                  ON P.SupplierID = S.SupplierID
                                               INNER JOIN order_details as od
                                                  ON p.productID = od.productid
                                               WHERE P.CategoryID in (1,2,3) 
	                                                AND P.Unitprice < 20
	                                                AND S.Country = ''uk'' 
	                                                AND od.Quantity < 90'

-- Exemplo 2
EXEC dbo.st_TestHipotheticalIndexes @SQLIndex = 'CREATE INDEX ix ON ProductsBig (ProductName);',
                                    @Query = 'SELECT * FROM ProductsBig WHERE ProductName = ''Mishi Kobe Niku 1A11B764'''
*/
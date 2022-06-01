/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
;WITH XMLNAMESPACES (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'), CTE_1
AS
(
  SELECT CONVERT(XML, Tab1.query_plan) AS query_plan
    FROM sys.dm_exec_query_stats qs
   CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) AS Tab1
   WHERE Tab1.query_plan LIKE '%StatementOptmEarlyAbortReason="TimeOut"%'
)
SELECT TOP 5 -- Remove Top to return all plans
       Tab1.ColXML.value('@StatementText', 'varchar(max)') AS StatementText,
       Tab1.ColXML.value('@StatementType', 'varchar(255)') AS StatementType,
       CTE_1.query_plan       
  FROM CTE_1
OUTER APPLY CTE_1.query_plan.nodes('//StmtSimple') Tab1(ColXML) 


/*
  Testar TraceFlags:
    2301 (http://blogs.msdn.com/b/ianjo/archive/2006/04/24/582219.aspx)
    4199 (http://support.microsoft.com/kb/974006/en-US)
*/
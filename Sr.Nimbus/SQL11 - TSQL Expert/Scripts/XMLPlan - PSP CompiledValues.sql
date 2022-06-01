/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano.amorim@srnimbus.com.br
  http://www.srnimbus.com.br
  http://blogfabiano.com
*/

-- Query para consultar parâmetros utilizados para criação de um plano
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

DECLARE @ProcName VarChar(500)
SET @ProcName = 'NOME DA PROCEDURE';

WITH XMLNAMESPACES  (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'), PlanHandles
AS 
  (
    SELECT DISTINCT plan_handle 
      FROM sys.dm_exec_query_stats
  )
,PlanParameters
AS 
  (
    SELECT ph.plan_handle, qp.query_plan, qp.dbid, qp.objectid
      FROM PlanHandles ph
     OUTER APPLY sys.dm_exec_query_plan(ph.plan_handle) qp
     WHERE qp.query_plan.exist('//ParameterList')=1
       AND OBJECT_NAME(qp.objectid, qp.dbid) = @ProcName
  )

SELECT DB_NAME(pp.dbid) AS DatabaseName,
       OBJECT_NAME(pp.objectid, pp.dbid) AS ObjectName,
       n2.value('(@Column)[1]','sysname') AS ParameterName,
       n2.value('(@ParameterCompiledValue)[1]','varchar(max)') AS ParameterValue,
       n1.query('.') AS N1_XML,
       n2.query('.') AS N2_XML
  FROM PlanParameters pp
 CROSS APPLY query_plan.nodes('//ParameterList') AS q1(n1)
 CROSS APPLY n1.nodes('ColumnReference') as q2(n2)
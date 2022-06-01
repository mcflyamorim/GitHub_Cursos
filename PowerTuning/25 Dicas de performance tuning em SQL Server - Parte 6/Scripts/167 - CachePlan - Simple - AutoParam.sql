USE Northwind
GO

DBCC FREEPROCCACHE()
GO

-- Essa é uma query adhoc? 
SELECT * 
  FROM Employees
 WHERE FirstName = 'Nancy' 
GO

-- E essa?
SELECT * 
  FROM Employees
 WHERE FirstName = 'Robert' 
GO

-- Como ficam os planos? 
-- Uéee, mas ainda tem os planos lá, eu to vendo... Calma:
---- "These shell queries do not contain the full execution plan but only a pointer to the full plan in the corresponding prepared plan"
SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO
-- SQL fez um bom trabalho definindo o parametro como VARCHAR(8000)...


DBCC FREEPROCCACHE()
GO

SELECT * 
  FROM Orders
 WHERE Value = 10.1
GO
SELECT * 
  FROM Orders
 WHERE Value = 10.11
GO
SELECT * 
  FROM Orders
 WHERE Value = 10.111
GO

-- Umm, not so good...
SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO

-- Auto param raramente vai funcionar... na verdade, apenas pra consultas muito simples...

DBCC FREEPROCCACHE()
GO

-- Auto param? 
SELECT TOP 1 * 
  FROM Employees
 WHERE FirstName = 'Nancy'
GO

SELECT usecounts, cacheobjtype, objtype, size_in_bytes, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE cacheobjtype = 'Compiled Plan'
AND [text] NOT LIKE '%dm_exec_cached_plans%'; 
GO


/*
  https://docs.microsoft.com/en-us/previous-versions/tn-archive/cc293623%28v%3dtechnet.10%29
  There are many query constructs that normally disallow autoparameterization. Such constructs include any statements with the following elements:

  JOIN
  BULK INSERT
  IN lists
  UNION
  INTO
  FOR BROWSE
  OPTION <query hints>
  DISTINCT
  TOP
  WAITFOR statements
  GROUP BY, HAVING, COMPUTE
  Full-text predicates
  Subqueries
  FROM clause of a SELECT statement has table valued method or full-text table or OPENROWSET or OPENXML or OPENQUERY or OPENDATASOURCE
  Comparison predicate of the form EXPR <> a non-null constant
  Autoparameterization is also disallowed for data modification statements that use the following constructs:

  DELETE/UPDATE with FROM CLAUSE
  UPDATE with SET clause that has variables
*/
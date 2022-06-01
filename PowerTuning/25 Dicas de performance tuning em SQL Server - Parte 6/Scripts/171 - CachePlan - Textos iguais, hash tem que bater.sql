USE Northwind
GO

DBCC FREEPROCCACHE
GO

SELECT * FROM Customers WHERE ContactName = 'Fabiano'
GO
SELECT * FROM Customers WHERE contactName = 'Fabiano'
GO
SELECT * FROM Customers WHERE contactname = 'Fabiano'
GO
SELECT * FROM CUSTOMERS WHERE contactname = 'Fabiano'
GO


-- Quantos planos tenho em cache? 
SELECT usecounts, cacheobjtype, objtype, size_in_bytes / 1024. AS size_in_kb, [text] 
FROM sys.dm_exec_cached_plans P
CROSS APPLY sys.dm_exec_sql_text (plan_handle) 
WHERE [text] LIKE '%Fabiano%' 
AND [text] NOT LIKE '%dm_exec_cached_plans%';
GO

-- Ops
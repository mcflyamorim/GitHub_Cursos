USE Northwind
GO

-- Reset to default...
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'query wait (s)', N'-1'
GO
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO


-- Creating a 2 million rows table...
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(8000), NEWID()) AS Col1,
       CONVERT(VarChar(8000), NEWID()) AS Col2,
       CONVERT(VarChar(8000), NEWID()) AS Col3,
       CONVERT(VarChar(8000), NEWID()) AS Col4,
       CONVERT(VarChar(8000), NEWID()) AS Col5,
       CONVERT(VarChar(8000), NEWID()) AS Col6
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO

-- Iniciar Query Stress -- 
-- 50 threads e 1 iteration
SELECT TOP 10000 * FROM ProductsBig 
 ORDER BY ProductName
OPTION (MAXDOP 1, MIN_GRANT_PERCENT = 50)
GO


-- Query espera MUITO tempo para pegar memória...
SELECT TOP 100 * FROM ProductsBig 
 ORDER BY ProductName
OPTION (MAXDOP 1)
GO
-- Ver warning on MemoryGrant... AWESOME!



EXEC sp_WhoIsActive
GO
SELECT * FROM sys.dm_exec_query_memory_grants
GO


-- Ajustando query wait... 
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'query wait (s)', N'2'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Reiniciar Query Stress -- 


-- E agora? 
-- Query espera MUITO tempo para pegar memória...
SELECT TOP 100 * FROM ProductsBig 
 ORDER BY ProductName
OPTION (MAXDOP 1)
GO


-- Porem agora causamos outro problema...
-- Pois as queries que estavam esperando por resource_semaphore no SQLQueryStress tão rodando
-- Porem com pouca memória e fazendo spill no tempdb...
-- Então, cuidado...

EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO

USE Northwind
GO

IF OBJECT_ID('Products1') IS NOT NULL
  DROP TABLE Products1
GO
SELECT TOP 100000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE Products1 ADD CONSTRAINT xpk_Products1 PRIMARY KEY(ProductID)
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO

-- Colocar os dados no buffer pool data cache
-- 40 segundos pra rodar...
SELECT COUNT(*) FROM Products1
GO


-- Maneira rápida e fácil de visualizar qual allocator está consumindo mais memória
SELECT TOP (50)
       mc.[type] AS [Memory Clerk Type],
       CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2)) AS [Memory Usage (MB)]
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type]
ORDER BY SUM(mc.pages_kb) DESC;
GO

-- MEMORYCLERK_SQLBUFFERPOOL was new for SQL Server 2012. It should be your highest consumer of memory


-- Quantidade de memória utilizada por componentes fora do buffer pool data cache...
SELECT SUM(pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb) / 1024. AS [NonBPData Mb]
FROM sys.dm_os_memory_clerks
WHERE type <> 'MEMORYCLERK_SQLBUFFERPOOL';
GO


---------------------------------------------------
------------ DEMO 1 Memória e backups -------------
---------------------------------------------------

/*
  1 - Backup lê todas as páginas do banco, correto? Então ele vai popular BP data cache com 
      dados do BD ? ...
  2 - Ver memória utilizada pelo MEMORYCLERK_BACKUP (SQL2016+)
*/

SELECT DB_ID('Northwind')
GO

-- Northwind dbid = 5
DBCC FLUSH ('data', 5)
GO

DBCC TRACEON (3604,3213)
GO
BACKUP DATABASE Northwind
TO DISK = 'C:\TEMP\Northwind.bak'
WITH INIT, FORMAT
GO
DBCC TRACEOFF (3604,3213)
GO

-- Rodar em nova sessão
SELECT mc.[type] AS [Memory Clerk Type],
       CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2)) AS [Memory Usage (MB)]
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
WHERE type like 'MEMORYCLERK_BACKUP' -- Antes do SQL2016 fica em MEMORYCLERK_SQLUTILITIES
GROUP BY mc.[type]
ORDER BY SUM(mc.pages_kb) DESC;
GO
SELECT * 
  FROM sys.dm_os_memory_clerks
	WHERE type like 'MEMORYCLERK_BACKUP' -- Antes do SQL2016 fica em MEMORYCLERK_SQLUTILITIES
  AND memory_node_id = 0
GO


-- Vamos ajustar MAXTRANSFERSIZE e BUFFERCOUNT:

--MAXTRANSFERSIZE specifies the unit of transfer used by the SQL Server to perform the backups. 
--The default value is 1024MB – the possible values are multiples of 65536 bytes (64KB) ranging up to 4MB.

--BUFFERCOUNT determines the number of IO buffers used by the backup operations. 
--The values for it are dynamically calculated by the MSSQL Server, 
--however they are not always optimal. However be cautious as very high values may lead to ‘out of memory’ errors.


DBCC TRACEON (3604,3213)
GO
BACKUP DATABASE Northwind
TO DISK = 'C:\TEMP\Northwind_NoCompression.bak' 
WITH INIT, MAXTRANSFERSIZE = 4194304 /*4MB*/, BUFFERCOUNT = 50, NO_COMPRESSION, FORMAT
GO
DBCC TRACEOFF (3604,3213)
GO

-- Compression pode fazer com que SQL use mundarel de memória, já ele tem um "Sets Of Buffers" de 3.... 
DBCC TRACEON (3604,3213)
GO
BACKUP DATABASE Northwind
TO DISK = 'C:\TEMP\Northwind_Compression.bak' 
WITH INIT, MAXTRANSFERSIZE = 4194304 /*4MB*/, BUFFERCOUNT = 50, COMPRESSION, FORMAT
GO
DBCC TRACEOFF (3604,3213)
GO

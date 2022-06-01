USE master
GO
sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
-- Set BP to 10GB
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO

USE Northwind
GO
-- 40 segundos pra rodar...
IF OBJECT_ID('fnSequencial', 'IF') IS NOT NULL
  DROP FUNCTION dbo.fnSequencial
GO
CREATE FUNCTION dbo.fnSequencial (@i Int)
RETURNS TABLE
AS
RETURN 
(
 WITH L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
     L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
     L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
     L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
     L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
     L5   AS(SELECT 1 AS C FROM L4 AS A CROSS JOIN L4 AS B), -- 4,294,967,296 rows
     Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L5)

SELECT TOP (@i) N AS Num
  FROM Nums
)
GO
DROP TABLE IF EXISTS Table1_2GB
-- Creating tables to simulate issue
SELECT ABS(CHECKSUM(NEWID())) / 100000 AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Table1_2GB
  FROM dbo.fnSequencial(256000)
OPTION (MAXDOP 4)
GO
CREATE CLUSTERED INDEX ix1 ON Table1_2GB(ProductID)
GO



-- Reiniciar instância...
EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT create_date FROM sys.databases WHERE name = 'tempdb'
GO


-- Fazendo scan só pra garantir que os dados estão em memória...
SELECT COUNT(*) FROM Table1_2GB
GO


-- Quanto estou usando de BP data cache? 
SELECT SUM(pages_kb) / 1024. SizeInMb 
  FROM sys.dm_os_memory_clerks
 WHERE type = 'MEMORYCLERK_SQLBUFFERPOOL'
GO
/*
  SizeInMb
  --------------
  2097.953125
*/


-- 2GB de memória... basicamente a tabela Table1_2GB
SELECT DBName = DB_NAME(database_id),
       Pages = COUNT(1),
	   CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
	   Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END
  FROM sys.dm_os_buffer_descriptors as bd
WHERE DB_NAME(database_id) = 'Northwind'
GROUP BY database_id, is_modified
ORDER BY COUNT(1) DESC
GO



-- Quanto tempo demora pra criar uma cópia da tabela ? 
-- Quanto de escrita(disk I/O) vai gerar no Log e no MDF?


-- Fazendo scan só pra garantir que os dados estão em memória...
DECLARE @i INT; SELECT @i = COUNT(*) FROM Table1_2GB
GO
-- Pega um snapshot dos I/Os...
DROP TABLE IF EXISTS #tmp1
SELECT
    data_write = SUM(CASE DBF.[type_desc] WHEN 'ROWS' THEN num_of_bytes_written ELSE 0 END), 
    log_write  = SUM(CASE DBF.[type_desc] WHEN 'LOG' THEN num_of_bytes_written ELSE 0 END)
INTO #tmp1
FROM NorthWind.sys.database_files AS DBF
JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS FS
    ON FS.[file_id] = DBF.[file_id]
WHERE fs.database_id IN (DB_ID('NorthWind'), DB_ID('tempdb'))
GO

-- Fazer uma cópia da tabela no próprio banco NorthWind
DROP TABLE IF EXISTS Table1_2GB_Copia
GO
-- Se eu tirar o MAXDOP 1, o operador de Table Insert roda em paralelo... Nice!!!
-- Demora 1.5 segundos pra rodar...
SELECT *
  INTO Table1_2GB_Copia
  FROM Table1_2GB
OPTION (MAXDOP 1)
GO

-- Compara dm_io_virtual_file_stats com o snapshot pra ver o que mudou...
SELECT
    data_write_MB = (SUM(CASE DBF.[type_desc] WHEN 'ROWS' THEN num_of_bytes_written ELSE 0 END) - #tmp1.data_write) / 1024. / 1024., 
    log_write_MB = (SUM(CASE DBF.[type_desc] WHEN 'LOG' THEN num_of_bytes_written ELSE 0 END) - #tmp1.log_write) / 1024. / 1024.
FROM NorthWind.sys.database_files AS DBF
JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS FS
    ON FS.[file_id] = DBF.[file_id]
CROSS JOIN #tmp1
WHERE fs.database_id IN (DB_ID('NorthWind'), DB_ID('tempdb'))
GROUP BY #tmp1.data_write, #tmp1.log_write
GO
DROP TABLE IF EXISTS Table1_2GB_Copia
GO
/*
  data_write_MB        log_write_MB
  -------------------- -----------------
  2000.00781250000     29.72998046875
*/



-- Quase tudo, foi persistido no disco... 
-- Poucas páginas dirty...
SELECT DBName = DB_NAME(database_id),
       Pages = COUNT(1),
	   CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
	   Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END
  FROM sys.dm_os_buffer_descriptors as bd
WHERE DB_NAME(database_id) = 'Northwind'
GROUP BY database_id, is_modified
ORDER BY COUNT(1) DESC
GO
-- Ou seja, gerou mundarel de I/O no mdf...
/*
  DBName         Pages       CachedSizeMB   Page_Status
  -------------- ----------- -------------- -----------
  Northwind      514619      4020.46        Clean
  Northwind      78          0.61           Dirty
*/


-- E se eu criar a tabela no tempdb? como fica?


-- Fazendo scan só pra garantir que os dados estão em memória...
DECLARE @i INT; SELECT @i = COUNT(*) FROM Table1_2GB
GO
-- Pega um snapshot dos I/Os...
DROP TABLE IF EXISTS #tmp1
SELECT
    data_write = SUM(CASE DBF.[type_desc] WHEN 'ROWS' THEN num_of_bytes_written ELSE 0 END), 
    log_write  = SUM(CASE DBF.[type_desc] WHEN 'LOG' THEN num_of_bytes_written ELSE 0 END)
INTO #tmp1
FROM NorthWind.sys.database_files AS DBF
JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS FS
    ON FS.[file_id] = DBF.[file_id]
WHERE fs.database_id IN (DB_ID('NorthWind'), DB_ID('tempdb'))
GO

-- Fazer uma cópia da tabela no próprio banco NorthWind
DROP TABLE IF EXISTS tempdb.dbo.Table1_2GB_Copia
GO
-- Operador de Table Insert rodando em paralelo... Nice!!!
-- Demora 8 segundos pra rodar...
SELECT *
  INTO tempdb.dbo.Table1_2GB_Copia
  FROM Table1_2GB
OPTION (MAXDOP 1)
GO

-- Compara dm_io_virtual_file_stats com o snapshot pra ver o que mudou...
SELECT
    data_write_MB = (SUM(CASE DBF.[type_desc] WHEN 'ROWS' THEN num_of_bytes_written ELSE 0 END) - #tmp1.data_write) / 1024. / 1024., 
    log_write_MB = (SUM(CASE DBF.[type_desc] WHEN 'LOG' THEN num_of_bytes_written ELSE 0 END) - #tmp1.log_write) / 1024. / 1024.
FROM NorthWind.sys.database_files AS DBF
JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS FS
    ON FS.[file_id] = DBF.[file_id]
CROSS JOIN #tmp1
WHERE fs.database_id IN (DB_ID('NorthWind'), DB_ID('tempdb'))
GROUP BY #tmp1.data_write, #tmp1.log_write
GO
DROP TABLE IF EXISTS tempdb.dbo.Table1_2GB_Copia
GO
/*
  data_write_MB        log_write_MB
  -------------------- -----------------
  0.12500000000        6.77880859375
*/


-- Escreveu tudo em memória, e nada de flush...
-- Nice...
SELECT DBName = DB_NAME(database_id),
       Pages = COUNT(1),
	   CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
	   Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END
  FROM sys.dm_os_buffer_descriptors as bd
WHERE DB_NAME(database_id) IN ('Northwind', 'tempdb')
GROUP BY database_id, is_modified
ORDER BY 1, COUNT(1) DESC
GO
/*
  DBName               Pages       CachedSizeMB    Page_Status
  -------------------- ----------- --------------- -----------
  Northwind            514518      4019.67         Clean
  Northwind            80          0.63            Dirty
  tempdb               256079	     2000.62         Dirty
  tempdb               262         2.05            Clean
*/


-- Mas só conseguiu fazer isso tão bem assim porque tinha memória disponível...
-- Se tiver que fazer steal, pode ser que demore um pouco mais...
-- https://www.red-gate.com/simple-talk/sql/performance/tempdb-heres-a-problem-you-didnt-know-you-have/
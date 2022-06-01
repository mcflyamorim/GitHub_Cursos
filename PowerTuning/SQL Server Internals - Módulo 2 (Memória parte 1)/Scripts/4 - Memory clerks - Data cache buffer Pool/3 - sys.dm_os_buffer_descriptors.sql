USE Northwind
GO

-- Demo 1 - read_microsec e process monitor

-- Popular BP data cache com alguma coisa...
SELECT COUNT(*) FROM OrdersBig
GO
SELECT COUNT(*) FROM CustomersBig
GO

SELECT TOP 100 *
  FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID('Northwind')
GO

-- Coluna read_microsec me parece interessante... mas, muita calma nessa hora.

-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-buffer-descriptors-transact-sql?view=sql-server-2017
-- read_microsec	bigint	The actual time (in microseconds)
-- required to read the page into the buffer. 
-- This number is reset when the buffer is reused. Is nullable.

CHECKPOINT;DBCC DROPCLEANBUFFERS(); 
GO

SELECT TOP 1
       *, sys.fn_PhysLocFormatter(%%physloc%%) AS [Physical_Loc]
FROM OrdersBig
ORDER BY OrderID;
GO

SELECT TOP 1
       *, sys.fn_PhysLocFormatter(%%physloc%%) AS [Physical_Loc]
FROM OrdersBig
ORDER BY Value;
GO

-- Notou a diferença de tempo no read_microsec?
SELECT
    obd.file_id,
    obd.page_id,
    obd.page_level,
    obd.row_count,
    obd.free_space_in_bytes,
    obd.is_modified,
    obd.numa_node,
    obd.read_microsec
FROM sys.dm_os_buffer_descriptors AS obd
WHERE database_id = DB_ID('Northwind')  AND
    obd.page_id IN(9344, 12655);
GO


-- 1 - Abrir process monitor
-- 2 - Rodar query com order by OrderID ... Ver tamanho do I/O request
-- 3 - Rodar query com order by Value ... Ver tamanho do I/O request... btw, vários requests... alguns de 4 ou 8 extents
-- 4 - Notice, threadID ... windbg :-) ... agora não... fica pra tarefa...


-- Demo 2 - free_space_in_bytes



-- Uso do bata cache por DB
WITH AggregateBufferPoolUsage
AS (SELECT DB_NAME(database_id) AS [Database Name],
           CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSize]
    FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
    WHERE database_id <> 32767 -- ResourceDB
    GROUP BY DB_NAME(database_id))
SELECT ROW_NUMBER() OVER (ORDER BY CachedSize DESC) AS [Buffer Pool Rank],
       [Database Name],
       CachedSize AS [Cached Size (MB)],
       CAST(CachedSize / SUM(CachedSize) OVER () * 100.0 AS DECIMAL(5, 2)) AS [Buffer Pool Percent]
FROM AggregateBufferPoolUsage
ORDER BY [Buffer Pool Rank];
GO

-- Retornar info no nível do obj/índice
USE Northwind
GO
IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL 
  DROP TABLE #tmp1

SELECT * 
  INTO #tmp1 
  FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')

SELECT DB_Name() AS dbName, 
       schemas.name + '.' + obj.name as objectname,
       ind.name as indexname,
       obj.index_id as indexid,
       obj.data_compression_desc,
       obj.ActualSizeMB,
       count(*) as cached_pages_count,
       (count(*) * 8) / 1024. as mb_cached,
       (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS Free_Space_MB,
       indexstats.avg_fragmentation_in_percent,
       indexstats.page_count
  FROM sys.dm_os_buffer_descriptors as bd
 INNER JOIN (SELECT object_id as objectid,
                    object_name(object_id) as name,
                    index_id,
                    allocation_unit_id,
                    p.data_compression_desc,
                    (au.total_pages * 8) / 1024. ActualSizeMB
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.hobt_id
                AND (au.type = 1 OR au.type = 3)
              UNION ALL
             SELECT object_id as objectid,
                    object_name(object_id) as name,
                    index_id,
                    allocation_unit_id,
                    p.data_compression_desc,
                    (au.total_pages * 8) / 1024. ActualSizeMB
               FROM sys.allocation_units as au
              INNER JOIN sys.partitions as p
                 ON au.container_id = p.partition_id
                AND au.type = 2) as obj
    ON bd.allocation_unit_id = obj.allocation_unit_id
  LEFT OUTER JOIN #tmp1 indexstats
    ON obj.objectid = indexstats.object_id
   AND obj.index_id = indexstats.index_id
  LEFT OUTER JOIN sys.indexes ind
    ON obj.objectid = ind.object_id
   AND obj.index_id = ind.index_id
  LEFT OUTER JOIN sys.objects
    ON objects.object_id = ind.object_id
  LEFT OUTER JOIN sys.schemas
    ON objects.schema_id = schemas.schema_id
 WHERE bd.database_id = db_id()
   AND bd.page_type in ('data_page', 'index_page')
 GROUP BY schemas.name + '.' + obj.name,
         ind.name,
         obj.index_id,
         obj.data_compression_desc,
         ActualSizeMB,
         indexstats.avg_fragmentation_in_percent,
         indexstats.page_count
 ORDER BY cached_pages_count DESC
GO

-- Índice xpk_CustomersBig está com 99% de frag e 130MB de free_space ... 

-- Como fica depois de fezer um rebuild? 
ALTER INDEX ALL ON dbo.CustomersBig REBUILD
GO



-- Demo 3 - Compression

-- É interessante aplicar compressão nos objs consumindo muito espaço na memória
-- O script abaixo pode te ajudar a fazer isso de forma eficiente... de nada... :-) 

-- Rodar script abaixo no banco Northwind e ver resultado no excel...:
-- D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 2 (Memória parte 1)\Scripts\4 - Memory clerks - Data cache buffer Pool\Test Compression per Object - V2.sql


-- Demo 4 - Dirty pages

SELECT Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END,
       DBName = CASE
                    WHEN database_id = 32767 THEN
                        'RESOURCEDB'
                    ELSE
                        DB_NAME(database_id)
                END,
       Pages = COUNT(1)
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID('Northwind') -- Comentar se necessário
GROUP BY database_id,
         is_modified
ORDER BY 2;
GO

-- Se tiver páginas sujas, forçar CHECKPOINT e verificar novamente
CHECKPOINT
GO


-- Caso seja necessário sujar algumas páginas...
UPDATE Tab SET Value = 10
FROM (SELECT TOP (10) PERCENT * FROM OrdersBig) AS Tab
GO


-- Demo 5 - Tempdb vs BP data cache

-- Roda isso em uma nova sessão
-- +- 40 segundos pra rodar
USE tempdb
GO
CHECKPOINT;DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE(); 
GO

DECLARE @TabName VARCHAR(500) = '#Tab' + CONVERT(VARCHAR(250), NEWID()),
        @SQL VARCHAR(MAX) = ''

SET @SQL = 'SET NOCOUNT ON; DROP TABLE IF EXISTS "' + @TabName + '"; CREATE TABLE "' + @TabName + '" (Col1 CHAR(500)); '
SET @SQL += 'INSERT INTO "' + @TabName + '" SELECT TOP 20000000 a.ProductName FROM northwind.dbo.Products A, northwind.dbo.Products B , northwind.dbo.Products c , northwind.dbo.Products d; ' 
SET @SQL += 'DROP TABLE "' + @TabName + '"' 

EXEC (@SQL)



-- Tempdb com páginas no BP? ... Ein? 
-- Yes, dirty shit... :-( ...

-- Uso do bata cache por DB
WITH AggregateBufferPoolUsage
AS (SELECT DB_NAME(database_id) AS [Database Name],
           CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSize]
    FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
    WHERE database_id <> 32767 -- ResourceDB
    GROUP BY DB_NAME(database_id))
SELECT ROW_NUMBER() OVER (ORDER BY CachedSize DESC) AS [Buffer Pool Rank],
       [Database Name],
       CachedSize AS [Cached Size (MB)],
       CAST(CachedSize / SUM(CachedSize) OVER () * 100.0 AS DECIMAL(5, 2)) AS [Buffer Pool Percent]
FROM AggregateBufferPoolUsage
ORDER BY [Buffer Pool Rank];
GO

SELECT Page_Status = CASE
                         WHEN is_modified = 1 THEN
                             'Dirty'
                         ELSE
                             'Clean'
                     END,
       DBName = CASE
                    WHEN database_id = 32767 THEN
                        'RESOURCEDB'
                    ELSE
                        DB_NAME(database_id)
                END,
       Pages = COUNT(1)
FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID('tempdb') -- Comentar se necessário
GROUP BY database_id,
         is_modified
ORDER BY 2;
GO

-- Aaa mas isso é pq a sessão ainda está aberta... 

-- Ok, fechar sessão que rodou o script que cria a temporária...
-- Ver dmvs novamente


-- Ok quando necessário, o Lazywriter vai entrar e remover esse lixo pra 
-- dar lugar pra outra coisa... 
-- Mas eu queria conseguir limitar o BP data cache por DB... quem sabe um dia... 
-- Not much we can do about it... você pode forçar o checkpoint ou fazer shrink do tempdb...
---- mas não sei se é uma boa ideia... ainda não parei pra pensar como resolver isso... 


-- Demo 6 - Buffer pool disfavoring
/*
   Obs.: Só funciona para IndexScan -- Heap = no no!
*/


-----------------------------------------------
-- Inicio script preparação disfavoring demo --
-----------------------------------------------


-- +- 5 minutos pra rodar todo o script de preparação da demo
-- Depois de rodar o script, ver uso de bp data cache do tempdb
USE master
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_1')
BEGIN
  ALTER DATABASE DB_BPDisfavoring_1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		drop database DB_BPDisfavoring_1
end
GO
CREATE DATABASE DB_BPDisfavoring_1
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DB_BPDisfavoring_1', FILENAME = N'C:\DBs\DB_BPDisfavoring_1.mdf' , SIZE = 2097152KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DB_BPDisfavoring_1_log', FILENAME = N'C:\DBs\DB_BPDisfavoring_1_log.ldf' , SIZE = 524288KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE DB_BPDisfavoring_1
GO

-- Criar tabela com +- 900MB
IF OBJECT_ID('Products1') IS NOT NULL
  DROP TABLE Products1
GO
SELECT TOP 115000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT;
GO

-- 900.75 MB -- SELECT 922376 /1024.
EXEC sp_spaceused Products1
GO

USE master
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_2')
		drop database DB_BPDisfavoring_2
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_2')
BEGIN
  ALTER DATABASE DB_BPDisfavoring_2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		drop database DB_BPDisfavoring_2
end
GO
CREATE DATABASE DB_BPDisfavoring_2
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DB_BPDisfavoring_2', FILENAME = N'C:\DBs\DB_BPDisfavoring_2.mdf' , SIZE = 2097152KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DB_BPDisfavoring_2_log', FILENAME = N'C:\DBs\DB_BPDisfavoring_2_log.ldf' , SIZE = 524288KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
USE DB_BPDisfavoring_2
GO

-- Criar tabela com +- 900MB
IF OBJECT_ID('Products2') IS NOT NULL
  DROP TABLE Products2
GO
SELECT TOP 115000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products2
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT;
GO

-- 900.32 MB -- SELECT 922376 /1024.
EXEC sp_spaceused Products2
GO

USE master
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_3')
		drop database DB_BPDisfavoring_3
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_3')
BEGIN
  ALTER DATABASE DB_BPDisfavoring_3 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		drop database DB_BPDisfavoring_3
end
GO
CREATE DATABASE DB_BPDisfavoring_3
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DB_BPDisfavoring_3', FILENAME = N'C:\DBs\DB_BPDisfavoring_3.mdf' , SIZE = 2097152KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DB_BPDisfavoring_3_log', FILENAME = N'C:\DBs\DB_BPDisfavoring_3_log.ldf' , SIZE = 524288KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
USE DB_BPDisfavoring_3
GO

-- Criar tabela com +- 900MB
IF OBJECT_ID('Products3') IS NOT NULL
  DROP TABLE Products3
GO
SELECT TOP 115000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products3
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT;
GO

-- 900.32 MB -- SELECT 922376 /1024.
EXEC sp_spaceused Products3
GO

USE master
GO
if exists (select * from sysdatabases where name='DB_BPDisfavoring_4')
BEGIN
  ALTER DATABASE DB_BPDisfavoring_4 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		drop database DB_BPDisfavoring_4
end
GO
CREATE DATABASE DB_BPDisfavoring_4
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'DB_BPDisfavoring_4', FILENAME = N'C:\DBs\DB_BPDisfavoring_4.mdf' , SIZE = 2097152KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'DB_BPDisfavoring_4_log', FILENAME = N'C:\DBs\DB_BPDisfavoring_4_log.ldf' , SIZE = 524288KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
USE DB_BPDisfavoring_4
GO

-- Criar tabela com +- 4GB
IF OBJECT_ID('Products4GB') IS NOT NULL
  DROP TABLE Products4GB
GO
SELECT TOP 512000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Products4GB
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE Products4GB ADD CONSTRAINT xpk_Products4GB PRIMARY KEY(ProductID)
GO

-- Criar tabela com +- 2GB
-- 1 minuto para rodar
IF OBJECT_ID('Customers2GB_a') IS NOT NULL
  DROP TABLE Customers2GB_a
GO
SELECT TOP 256000 IDENTITY(Int, 1,1) AS CustomerID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Customers2GB_a
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE Customers2GB_a ADD CONSTRAINT xpk_Customers2GB_a PRIMARY KEY(CustomerID)
GO
CHECKPOINT;
GO

-- 4007.07 MB -- SELECT 4103248 /1024.
EXEC sp_spaceused Products4GB
GO
-- 2003.84 MB -- SELECT 2051936 /1024.
EXEC sp_spaceused Customers2GB_a
GO

------------------------------------------------
-- Término script preparação disfavoring demo --
------------------------------------------------

sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
sp_configure 'Ad Hoc Distributed Queries', 1;  
RECONFIGURE;  
GO  
DBCC TRACEON(652) -- Desabilitando read ahead pra deixar demo mais simples... 
GO
-- Set BP to 8GB
EXEC sys.sp_configure N'max server memory (MB)', N'8192'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Iniciando demo
CHECKPOINT;DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE(); 
GO
-- Consultando BP 
USE master
GO
SELECT DB_NAME(database_id) AS [Database Name],
       CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
       COUNT(page_id) AS PageCount
  FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
 WHERE database_id IN (DB_ID('DB_BPDisfavoring_1'),DB_ID('DB_BPDisfavoring_2'),DB_ID('DB_BPDisfavoring_3'), DB_ID('DB_BPDisfavoring_4'))
 GROUP BY DB_NAME(database_id)
GO

-- +- 2 segundos para rodar
SET STATISTICS IO ON
GO
-- Ler 900MB
USE DB_BPDisfavoring_1;
GO
SELECT COUNT(*) FROM dbo.Products1 OPTION (MAXDOP 1)
GO
-- Ler mais 900MB 
USE DB_BPDisfavoring_2;
GO
SELECT COUNT(*) FROM dbo.Products2 OPTION (MAXDOP 1)
GO
-- Ler mais 900MB 
USE DB_BPDisfavoring_3;
GO
SELECT COUNT(*) FROM dbo.Products3 OPTION (MAXDOP 1)
GO
SET STATISTICS IO OFF
GO

-- +- 2.7GB no BP
USE master
GO
SELECT DB_NAME(database_id) AS [Database Name],
       CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
       COUNT(page_id) AS PageCount
  FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
 WHERE database_id IN (DB_ID('DB_BPDisfavoring_1'),DB_ID('DB_BPDisfavoring_2'),DB_ID('DB_BPDisfavoring_3'), DB_ID('DB_BPDisfavoring_4'))
 GROUP BY DB_NAME(database_id)
GO


-- Logical reads?
SET STATISTICS IO ON
GO
-- Ler 900MB
USE DB_BPDisfavoring_1;
GO
SELECT COUNT(*) FROM dbo.Products1 OPTION (MAXDOP 1)
GO
-- Ler mais 900MB 
USE DB_BPDisfavoring_2;
GO
SELECT COUNT(*) FROM dbo.Products2 OPTION (MAXDOP 1)
GO
-- Ler mais 900MB 
USE DB_BPDisfavoring_3;
GO
SELECT COUNT(*) FROM dbo.Products3 OPTION (MAXDOP 1)
GO
SET STATISTICS IO OFF
GO


-- Ler tabela de 4GB
-- Physical reads ?
-- 3 segundos
USE DB_BPDisfavoring_4;
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Products4GB
SET STATISTICS IO OFF
GO

-- Quanto ficou no BP? 
USE master
GO
SELECT DB_NAME(database_id) AS [Database Name],
       CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
       COUNT(page_id) AS PageCount
  FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
 WHERE database_id IN (DB_ID('DB_BPDisfavoring_1'),DB_ID('DB_BPDisfavoring_2'),DB_ID('DB_BPDisfavoring_3'), DB_ID('DB_BPDisfavoring_4'))
 GROUP BY DB_NAME(database_id)
GO

-- MEMORYCLERK_SQLBUFFERPOOL?
SELECT TOP (50)
       mc.[type] AS [Memory Clerk Type],
       CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2)) AS [Memory Usage (MB)]
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type]
ORDER BY SUM(mc.pages_kb) DESC;
GO


-- Lendo denovo a tabela de 4GB
-- Logical reads? 
USE DB_BPDisfavoring_4;
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Products4GB
SET STATISTICS IO OFF
GO


-- Lendo uma tabela de 2GB... 
-- Physical reads
USE DB_BPDisfavoring_4;
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Customers2GB_a
SET STATISTICS IO OFF
GO

-- Lendo novamente... Agora tenho logical reads, certo? 
USE DB_BPDisfavoring_4;
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Customers2GB_a
SET STATISTICS IO OFF
GO

-- Lendo a tabela Products4GB que estava no BP, e agora Logical ou Physical? 
-- Logical reads ? 
USE DB_BPDisfavoring_4
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Products4GB
SET STATISTICS IO OFF
GO

-- Quem saiu do BP? Páginas do DB DB_BPDisfavoring_1 e DB_BPDisfavoring_2 etc? 
USE master
GO
SELECT DB_NAME(database_id) AS [Database Name],
       CAST(COUNT(*) * 8 / 1024.0 AS DECIMAL(10, 2)) AS [CachedSizeMB],
       COUNT(page_id) AS PageCount
  FROM sys.dm_os_buffer_descriptors WITH (NOLOCK)
 WHERE database_id IN (DB_ID('DB_BPDisfavoring_1'),DB_ID('DB_BPDisfavoring_2'),DB_ID('DB_BPDisfavoring_3'), DB_ID('DB_BPDisfavoring_4'))
 GROUP BY DB_NAME(database_id)
GO


-- https://www.sqlskills.com/blogs/paul/buffer-pool-disfavoring/
-- Large table scans that are more than 10% of the buffer pool size will disfavor pages 
-- instead of forcing pages from other databases to be flushed from memory




-- Lendo a tabela de 2GB novamente... 
-- Physical reads...
USE DB_BPDisfavoring_4;
GO
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Customers2GB_a 
SET STATISTICS IO OFF
GO
-- Physical reads...
SET STATISTICS IO ON
SELECT COUNT(*) FROM dbo.Products4GB 
SET STATISTICS IO OFF
GO



-- Abrir perfmon
-- Selecionar "Buffer Manager:Page Life Expectancy" e "Buffer Manager:Page reads/sec"
-- Ver PLE




-- Bônus 1: Extended Event leaf_page_disfavored mostra quando a página 
-- foi marcada como leaf_page_disfavored

-- Bônus 2: Como fariamos para "desabilitar" esse compartamento ?
---------- Atualizar ROWCOUNT e PAGECOUNT antes de rodar o 
-- ------- Scan e depois corrigir o valor novamente... :-( 
/*
   UPDATE STATISTICS Products4GB WITH ROWCOUNT = 1, PAGECOUNT = 1
   GO
   -- Reset ROWCOUNT e PAGECOUNT para números originais...
   DBCC UPDATEUSAGE (DB_BPDisfavoring_4,'Products4GB') WITH COUNT_ROWS;
   GO
*/

-- WARNING                                                       WARNING
-- WARNING                                                       WARNING
-- WARNING                                                       WARNING
-- WARNING                                                       WARNING
-- WARNING Se você achou que estava muito complicado, se prepare WARNING
-- WARNING                                                       WARNING
-- WARNING                                                       WARNING
-- WARNING                                                       WARNING



-- Como identificar a data de último uso da página em cache? ... 
-- Lembre-se, as páginas mais velhas, serão removidas do cache primeiro...
-- Disfavoring, na verdade, seta a data de último uso da página com Data Atual - 1 hora, 
-- Por isso a chance do SQL reutilizar esse espaço é maior... por que o acesso a 
-- esse buffer das páginas são mais "velhos"

CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO

-- Colocar dados em cache
SELECT COUNT(*) FROM DB_BPDisfavoring_1.dbo.Products1
GO


-- Vejamos o BUF com último acesso (bUse1)...

-- Pegar um número de página (allocated_page_page_id) qualquer... 
SELECT TOP 5 database_id, DB_NAME(database_id) as [Database], 
       OBJECT_NAME(object_id, DB_ID('DB_BPDisfavoring_1')) AS ObjName, allocated_page_page_id , page_type_desc
FROM sys.dm_db_database_page_allocations(DB_ID('DB_BPDisfavoring_1'), OBJECT_ID('DB_BPDisfavoring_1.dbo.Products1'), NULL, NULL, 'Detailed')
GO

-- Ver se a página está em cache...
SELECT * FROM sys.dm_os_buffer_descriptors
WHERE database_id = DB_ID('DB_BPDisfavoring_1')
AND page_id = 8104
GO
DBCC TRACEON(3604)
DBCC PAGE (6, 1, 8104, 3)


-- Rodar DBCC Page na página... Mudar DBID, FILEID e PAGEID no comando de DBCC
-- Consultar BUF e o valor de bUse1 que tem a info com o timestamp da página em cache
-- Problema aqui é que minha leitura (DBCC), gerou atualização do BUF
-- Esse valor é em segundos com base no ms_ticks da sys.dm_os_sys_info
SELECT REPLACE(a.Object, 'BUF @', '') AS Object, a.Field, a.ObjectValue
FROM OPENROWSET('SQLNCLI', 'Server=razerfabiano\sql2017;Trusted_Connection=yes;',  
     'EXEC (''DBCC PAGE (6, 1, 8104, 3) WITH TABLERESULTS'')
      WITH RESULT SETS  
      (
         (
            ParentObject VARCHAR(1000) NULL,
            Object VARCHAR(4000) NULL,
            Field VARCHAR(1000) NULL,
            ObjectValue VARCHAR(MAX) NULL 
         )  
      )') AS a
CROSS JOIN sys.dm_os_sys_info
WHERE field = 'bUse1'
GO
-- Salvar o BUF 0x0000015924F11E00


-- bUse1 é utilizado com base na data em que o computador foi reiniciado
-- Vamos calcular quando foi isso com base no ms_ticks
SELECT DATEADD(SECOND, ((((ms_ticks) % 65536000) / 1000) * -1), GETDATE()) ms_ticks_count_starting_time
  FROM sys.dm_os_sys_info
GO
-- Essa data será nossa base pra saber a quanto tempo uma página está em cache

-- Dt do uso da página, de acordo com o bUse1 no BUF
DECLARE @dtComputerStart DATETIME = '2019-07-24 18:41:47.317', -- Resultado da query acima
        @bUse1 INT = 30192

SELECT DATEADD(SECOND, @bUse1, @dtComputerStart) AS DtLastAccess
GO

-- E o bUse1 no WinDbg, como está? 

dp 0x0000015928C493C0 -- BUF

/*
00000159`24f11e00  00000159`0f4e8000 00000000`00000000
00000159`24f11e10  00000159`24f11d50 00000000`00000000
00000159`24f11e20  00000000`00000000 00070001`00001fa8
00000159`24f11e30  00000159`0d580040 00000009`00000006
00000159`24f11e40  00000000`00000000 15ab215a`000067e0
00000159`24f11e50  00000000`00000001 00000000`00000000
00000159`24f11e60  00000000`0000008a 00000000`000011e0
00000159`24f11e70  00000000`00000000 00000000`00000000

*/

-- Convertendo 0x47ae para Int
SELECT CONVERT(INT, 0x67e0) -- 24773 



-- Ou seja, quando foi o último acesso mesmo? 
-- 1 hora atrás?
DECLARE @dtComputerStart DATETIME = '2019-07-24 18:41:47.133', -- Resultado da query acima
        @bUse1 INT = 26592

SELECT DATEADD(SECOND, @bUse1, @dtComputerStart) AS DtLastAccess
GO

-- DBCC chama BUF::Untouch() que marca a página como Disfavored...
-- Agora que já sabemos o buffer, vamos ler a página novamente...
-- Será que agora ele vai atualizar o bUse1 com o timestamp de agora? 

SELECT COUNT(*) FROM DB_BPDisfavoring_1.dbo.Products1
GO

-- E agora, como ficou o bUse1 no BUF?

dp 0x0000015928C493C0 -- BUF

/*
  0:112> dp 0x0000015928C493C0
  00000159`28c493c0  00000159`13e30000 00000000`00000000
  00000159`28c493d0  00000159`28c49310 00000000`00000000
  00000159`28c493e0  00000000`00000000 00080001`00001fa8
  00000159`28c493f0  00000159`0d580040 00000009`00000006
  00000159`28c49400  00000000`00000000 15ab215a`00006f64
  00000159`28c49410  00000000`00000000 00000000`00000000
  00000159`28c49420  00000000`00000000 00000000`0004e348
  00000159`28c49430  00000000`00000000 00000000`00000000
*/


-- Convertendo 0x47ae para Int
SELECT CONVERT(INT, 0x76d6) -- 28516 
GO

-- Agora foi? ...
DECLARE @dtComputerStart DATETIME = '2019-07-24 18:41:47.133', -- Resultado da query acima
        @bUse1 INT = 30422

SELECT DATEADD(SECOND, @bUse1, @dtComputerStart) AS DtLastAccess
GO


-- Fazer o teste com uma página da tabela Products4GB pra ver se 
-- o Untouch faz o disfavoring...



USE Northwind
GO

-- Criar tablea pra efetuar os testes
IF OBJECT_ID('OrdersBig_v1') IS NOT NULL
  DROP TABLE OrdersBig_v1
GO
SELECT TOP 18000000
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig_v1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
GO

sp_spaceused OrdersBig_v1 -- 446 MB
GO

CHECKPOINT;DBCC DROPCLEANBUFFERS;
-- Colocar os dados em cache
SELECT COUNT(*) FROM OrdersBig_v1
OPTION (MAXDOP 1)
GO


-- 63352 = WorkingSet ... Ver TaskManager, selecionar coluna "Working set (memory)"

-- physical_memory_in_use_kb = Uso de memória (BP) pelo SQL Server 
-- large_page_allocations_kb + locked_page_allocations_kb + WorkingSet = Total de memória utilizada
-- virtual_address_space_committed_kb - physical_memory_in_use_kb = MemToLeave? ReservedMemory?... NonBufferPoolMem
SELECT physical_memory_in_use_kb / 1024. AS Actual_Usage_mb,
       virtual_address_space_committed_kb / 1024. AS VAS_Committed,
       virtual_address_space_reserved_kb / 1024. AS VAS_Reserved,
       total_virtual_address_space_kb / 1024. AS VAS_Total,
       (large_page_allocations_kb + locked_page_allocations_kb + physical_memory_in_use_kb) / 1024. AS Actual_Physical_Memory_mb,
       (virtual_address_space_committed_kb - physical_memory_in_use_kb) / 1024. AS MemToLeave_MB
FROM sys.dm_os_process_memory
GO

-- Espaço utilizado pela TS
SELECT --physical_memory_kb / 1024.,
	      --committed_kb / 1024.,
       max_workers_count,
       s.TotalWorkers, 
       stack_size_in_bytes / 1024. /1024. AS stack_size_in_mb,
       (TotalWorkers * stack_size_in_bytes) / 1024. / 1024. AS ThreadStack_Size_in_MB
FROM sys.dm_os_sys_info
CROSS APPLY (SELECT SUM(CONVERT(FLOAT, current_workers_count)) AS TotalWorkers
              FROM sys.dm_os_schedulers) AS s
GO

-- Thread stack commited size...
SELECT SUM(CONVERT(FLOAT, stack_bytes_committed)) / 1024. / 1024. 
  FROM sys.dm_os_threads
GO

/*
  Abrir VMMap e ver Stack
  D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 2 (Memória parte 1)\Scripts\Outros\VMMap\
*/

-- sys.dm_os_virtual_address_dump mostra mesma coisa... 
-- Pegar um base address no VMMap e ver na DMV
-- Se necessário, incluir Zeros a esqueda no hexa... ex, de 0x44CD400000 para 0x00000044CD400000

0x0000005C35E12000
0x0000005C35E00000
0x0000000049C5E000
/* Map the process virtual address space by querying sys.dm_os_virtual_address_dump */
SELECT 
  region_base_address 'Base addr'
 ,region_size_in_bytes / 1024 /1024. size_mb
 ,case (region_state) when CONVERT(int, 0x1000) then 'COMMITTED'
    when CONVERT(int, 0x2000) then 'RESERVED'
    when CONVERT(int, 0x10000) then 'FREE' 
  end State
 ,case 
    when (region_current_protection = 0) then 'NONE'
    when (region_current_protection = CONVERT(int, 0x104)) then 'READ/WRITE/GUARD'
    when (region_current_protection ^ 1 = 0) then 'NO ACCESS'
    when (region_current_protection ^ 2 = 0) then 'READ'
    when (region_current_protection ^ 4 = 0) then 'READ/WRITE'
    when (region_current_protection ^ 8 = 0) then 'WRITE/COPY'
    when (region_current_protection ^ CONVERT(int, 0x20) = 0) then 'EXECUTE/READ'
    when (region_current_protection ^ CONVERT(int, 0x40) = 0) then 'EXECUTE/READ/WRITE'
    when (region_current_protection ^ CONVERT(int, 0x80) = 0) then 'EXECUTE/WRITE/COPY' 
  end Protection 
 ,case (region_type) 
    when 0 then 'FREE'
    when CONVERT(int, 0x20000) then 'PRIVATE'
    when CONVERT(int, 0x40000) then 'MAPPED'
    when CONVERT(int, 0x1000000) then 'IMAGE' end 'Region Type'
FROM sys.dm_os_virtual_address_dump
WHERE region_allocation_base_address = 0x0000005C35E00000
GO

-- Expandir stack no VMMap e ver bloco individual
SELECT 
  region_base_address 'Base addr'
 ,region_size_in_bytes / 1024 /1024. size_mb
 ,case (region_state) when CONVERT(int, 0x1000) then 'COMMITTED'
    when CONVERT(int, 0x2000) then 'RESERVED'
    when CONVERT(int, 0x10000) then 'FREE' 
  end State
 ,case 
    when (region_current_protection = 0) then 'NONE'
    when (region_current_protection = CONVERT(int, 0x104)) then 'READ/WRITE/GUARD'
    when (region_current_protection ^ 1 = 0) then 'NO ACCESS'
    when (region_current_protection ^ 2 = 0) then 'READ'
    when (region_current_protection ^ 4 = 0) then 'READ/WRITE'
    when (region_current_protection ^ 8 = 0) then 'WRITE/COPY'
    when (region_current_protection ^ CONVERT(int, 0x20) = 0) then 'EXECUTE/READ'
    when (region_current_protection ^ CONVERT(int, 0x40) = 0) then 'EXECUTE/READ/WRITE'
    when (region_current_protection ^ CONVERT(int, 0x80) = 0) then 'EXECUTE/WRITE/COPY' 
  end Protection 
 ,case (region_type) 
    when 0 then 'FREE'
    when CONVERT(int, 0x20000) then 'PRIVATE'
    when CONVERT(int, 0x40000) then 'MAPPED'
    when CONVERT(int, 0x1000000) then 'IMAGE' end 'Region Type'
FROM sys.dm_os_virtual_address_dump
WHERE region_base_address = 0x0000005C35E12000 -- pegar hexa no VMMap
GO


-- Somar tamanho do StackSize
-- Somente de areas utilizando 2MB (2097152 bytes) que é o tamanho da stack no x64
;WITH CTE_1
AS
(
SELECT 
  region_allocation_base_address 'Base addr'
 ,SUM(region_size_in_bytes) AS SizeInBytes
FROM sys.dm_os_virtual_address_dump
GROUP BY region_allocation_base_address
HAVING SUM(region_size_in_bytes) = 2097152 --2mb
)
SELECT SUM(SizeInBytes) / 1024./1024. SizeInMB
  FROM CTE_1
GO


-- DWA – DIRECT WINDOWS ALLOCATION
-- extend store procedure, OLE automation ( sp_OA ) , Link server etc.
SELECT *
  FROM sys.dm_os_loaded_modules
 --WHERE base_address = 0x00007FFAB0730000
GO

-- Ver no NMAP o allocation base address dentro de "Image"

-- Quanto de espaço utilizado por esse cara? 
SELECT base_address, description, name, SUM(region_size_in_bytes) / 1024./1024. AS size_mb
  FROM sys.dm_os_loaded_modules
 INNER JOIN sys.dm_os_virtual_address_dump
    ON sys.dm_os_virtual_address_dump.region_allocation_base_address = dm_os_loaded_modules.base_address
 GROUP BY base_address, description, name
 ORDER BY size_mb DESC
GO
-- Espaço total...
SELECT SUM(region_size_in_bytes) / 1024./1024. FROM sys.dm_os_virtual_address_dump
WHERE region_allocation_base_address IN (SELECT base_address FROM sys.dm_os_loaded_modules)
GO

------------------------------------------------
------------ DEMO 1 ThreadStackSize -------------
------------------------------------------------
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
-- 3000 threads = +- 6GB
EXEC sys.sp_configure N'max worker threads', N'3000'
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT 3000 * 2

-- 1 - Rodar "D:\Fabiano\Trabalho\FabricioLima\Cursos\SQL Server Internals - Módulo 2 (Memória parte 1)\Scripts\1 - Memory - sys.dm_os_process_memory\1 - Demo1 - sys.dm_os_process_memory\Demo1.ps1" 
-- para criar 3k workers
-- 2 - Verificar DMVs e memória no Task Manager, abrir resouce monitor e ver commited memory
-- 3 - Parar PS e Reiniciar SQL
-- 4 - Chamar "D:\Fabiano\Utilitarios\SysInternals\TestLimit\testlimit64.exe -d 7168 -c 1" para alocar 7GB de memória... 
---- não será possível criar uma nova thread
-- 5 - Algumas conexões/queries irão falhar... Verificar DMVs... Verificar errorlog
-- 6 - Abrir VMMap e ver tamanho da stack... Abrir resouce monitor e ver commited memory

-------------------------------------------------
------------ DEMO 2 ThreadStackSize -------------
-------------------------------------------------
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
EXEC sys.sp_configure N'max worker threads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO

-- 1 - Rodar "D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL26 - SQL Server - Mastering the database engine (former Internals)\Slides\Módulo 02 - Memória parte 1\Demo2 - sys.dm_os_process_memory" 
-- 2 - Verificar DMVs
-- 3 - Abrir VMMap e ver tamanho da stack... Abrir resouce monitor e ver commited memory
-- 4 - Watch commited memory subir até o PC morrer...


-- Cleanup
EXEC sys.sp_configure N'max worker threads', N'0'
GO
RECONFIGURE WITH OVERRIDE
GO
RECONFIGURE
GO
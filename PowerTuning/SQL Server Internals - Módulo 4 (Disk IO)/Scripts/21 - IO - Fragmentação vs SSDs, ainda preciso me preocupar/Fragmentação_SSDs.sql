----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

USE master
GO

-- +- 4-10 minutos pra rodar...
if exists (select * from sysdatabases where name='Test_Fabiano_SSD_Frag')
BEGIN
  ALTER DATABASE Test_Fabiano_SSD_Frag SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_SSD_Frag
end
GO
CREATE DATABASE Test_Fabiano_SSD_Frag
 ON  PRIMARY 
( NAME = N'Test_Fabiano_SSD_Frag', FILENAME = N'C:\DBs\Test_Fabiano_SSD_Frag.mdf' , SIZE = 5GB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_SSD_Frag_log', FILENAME = N'C:\DBs\Test_Fabiano_SSD_Frag_log.ldf' , SIZE = 500MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE Test_Fabiano_SSD_Frag
GO
IF OBJECT_ID('TabGUID') IS NOT NULL
  DROP TABLE TabGUID
GO
SELECT TOP 10
       CONVERT(UNIQUEIDENTIFIER, NEWID()) AS ID, 
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO TabGUID
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
 CROSS JOIN Northwind.dbo.Orders E
OPTION (MAXDOP 8)
GO
INSERT INTO TabGUID WITH(TABLOCK)
SELECT TOP 10000000
       CONVERT(UNIQUEIDENTIFIER, NEWID()) AS ID, 
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
 CROSS JOIN Northwind.dbo.Orders E
OPTION (MAXDOP 8)
GO
CREATE CLUSTERED INDEX ixClustered ON TabGUID(ID)
WITH (MAXDOP = 8)
GO
ALTER INDEX ixClustered ON TabGUID REBUILD
GO

IF OBJECT_ID('TabGUID_Fragmentado') IS NOT NULL
  DROP TABLE TabGUID_Fragmentado
GO
SELECT TOP 10
       CONVERT(UNIQUEIDENTIFIER, NEWID()) AS ID, 
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO TabGUID_Fragmentado
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
 CROSS JOIN Northwind.dbo.Orders E
OPTION (MAXDOP 8)
GO
CREATE CLUSTERED INDEX ixClustered ON TabGUID_Fragmentado(ID)
WITH (MAXDOP = 8)
GO
-- Gerando insert com TOP e Optimize for pra evitar o sort e gerar fragmentação...
-- Primeira comparação já está aqui... 
-- Esse insert demora +- 3 minutos pra rodar... 
-- O mesmo insert num HDD, demora 65 minutos... 
-- A diferença não é apenas na velocidade das escritas
-- mas no fato de que é MUITO mais "pesado" pra
-- fazer os I/Os não sequenciais no HDD, se comparado
-- ao SSD...
DECLARE @TOP INT = 10000000
INSERT INTO TabGUID_Fragmentado WITH(TABLOCK)
SELECT TOP (@TOP)
       CONVERT(UNIQUEIDENTIFIER, NEWID()) AS ID, 
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B
 CROSS JOIN Northwind.dbo.Orders C
 CROSS JOIN Northwind.dbo.Orders D
 CROSS JOIN Northwind.dbo.Orders E
OPTION (MAXDOP 8, OPTIMIZE FOR (@TOP = 100))
GO

CHECKPOINT
GO

USE Test_Fabiano_SSD_Frag
GO

-- Banco Test_Fabiano_SSD_Frag esta o SSD... 
-- Como esta a fragmentação da tabela OrdersBig ? 
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID('Test_Fabiano_SSD_Frag'), 
                                             OBJECT_ID('TabGUID'), 
                                             1, 
                                             NULL, 
                                             'DETAILED')
GO
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID('Test_Fabiano_SSD_Frag'), 
                                             OBJECT_ID('TabGUID_Fragmentado'), 
                                             1, 
                                             NULL, 
                                             'DETAILED')
GO
-- Fragmentação esta baixa... vamos começar gerando um pouco de frag...


-- Qual a diferença no tamanho das tabelas? 

sp_spaceused TabGUID -- 407624 KB
GO
sp_spaceused TabGUID_Fragmentado -- 584200 KB
GO


-- Qual a diferença de tempo pra ler os dados do disco? 
DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT TOP 50000 * FROM TabGUID
WHERE ID LIKE 'D%'
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
--Table 'TabGUID'. Scan count 1, logical reads 4117, physical reads 1, read-ahead reads 9160
-- SQL Server Execution Times:
--   CPU time = 141 ms,  elapsed time = 168 ms.
GO

DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT TOP 50000 * FROM TabGUID_Fragmentado
WHERE ID LIKE 'D%'
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
--Table 'TabGUID_Fragmentado'. Scan count 1, logical reads 5773, physical reads 4, read-ahead reads 52423
-- SQL Server Execution Times:
--   CPU time = 235 ms,  elapsed time = 508 ms.
GO


-- Qual a diferença pra fazer um delete de +- 625 mil linhas? 
DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
DELETE FROM TabGUID
WHERE ID LIKE 'D%'
SET STATISTICS IO, TIME OFF
GO
--Table 'TabGUID'. Scan count 9, logical reads 1926892, physical reads 1, read-ahead reads 42804
--(625163 rows affected)
-- SQL Server Execution Times:
--   CPU time = 3048 ms,  elapsed time = 1912 ms.

DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
DELETE FROM TabGUID_Fragmentado
WHERE ID LIKE 'D%'
SET STATISTICS IO, TIME OFF
GO
--Table 'TabGUID_Fragmentado'. Scan count 9, logical reads 2569639, physical reads 2, read-ahead reads 69919
--(623948 rows affected)
-- SQL Server Execution Times:
--   CPU time = 8469 ms,  elapsed time = 27413 ms.



-- Fragmentação importa... Ler e escrever no SSD ainda é muito mais lento que 
-- ler da memória... Read-ahead é mega prejudicado por causa
-- da fragmentação...

-- Lembrando também do overhead de +log +CPU e +latches por causa dos page-splits
-- ...


-- Pra fechar, e qual a diff pra ler os dados no HDD? 
USE Test_Fabiano_HDD_Frag
GO

-- Qual a diferença de tempo pra ler os dados do disco? 
DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT TOP 50000 * FROM TabGUID
WHERE ID LIKE 'D%'
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
--Table 'TabGUID'. Scan count 1, logical reads 4084, physical reads 1, read-ahead reads 9192
-- SQL Server Execution Times:
--   CPU time = 172 ms,  elapsed time = 862 ms.
GO

DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT TOP 50000 * FROM TabGUID_Fragmentado
WHERE ID LIKE 'D%'
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
--Table 'TabGUID_Fragmentado'. Scan count 1, logical reads 5947, physical reads 4, read-ahead reads 51463
-- SQL Server Execution Times:
--   CPU time = 203 ms,  elapsed time = 41936 ms.
GO

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

USE [master]
GO
if exists (select * from sysdatabases where name='Fabiano_Test_ReadAhead')
BEGIN
  ALTER DATABASE Fabiano_Test_ReadAhead SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Fabiano_Test_ReadAhead
end
GO

-- Criando banco pra testes
CREATE DATABASE Fabiano_Test_ReadAhead
 ON  PRIMARY 
( NAME = N'Fabiano_Test_ReadAhead_1', FILENAME = N'E:\Fabiano_Test_ReadAhead_1.mdf' , SIZE = 100MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Fabiano_Test_ReadAhead_log', FILENAME = N'C:\DBs\Fabiano_Test_ReadAhead_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

-- 20 segundos pra rodar
USE Fabiano_Test_ReadAhead
GO
DROP TABLE IF EXISTS Table1
SELECT TOP 10000  
       IDENTITY(BigInt, 1, 1) AS Col1, 
       ISNULL(CONVERT(VarChar(250), NEWID()), '') AS Col2,
       ISNULL(CONVERT(VarChar(7000), REPLICATE('x', 5000)), '') AS Col3
  INTO Table1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO

-- No caso da heap, o SQL verifica quais extents precisa ler analisando a IAM... 
-- Abrir o Process Monitor e ver o tamanho do I/O... heap = 512KB... 
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON
SELECT * FROM Fabiano_Test_ReadAhead.dbo.Table1
SET STATISTICS IO OFF
-- Table 'Table1'. Scan count 1, logical reads 10000, physical reads 0, read-ahead reads 10000
GO

-- Ainda no Process Monitor... Ver a stack da thread...


-- Criar o índice cluster...
-- 43 segundos pra rodar...
ALTER TABLE Table1 ADD CONSTRAINT xpkTable1 PRIMARY KEY(Col1)
GO

-- Agora o tamanho do I/O é um pouco menor...
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON
SELECT * FROM Fabiano_Test_ReadAhead.dbo.Table1
SET STATISTICS IO OFF
-- Table 'Table1'. Scan count 1, logical reads 10000, physical reads 0, read-ahead reads 10000
GO



-- Sem read-ahead como fica o I/O? 
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
DBCC TRACEON(652)
SET STATISTICS IO ON
SELECT * FROM Fabiano_Test_ReadAhead.dbo.Table1
SET STATISTICS IO OFF
-- Table 'Table1'. Scan count 1, logical reads 10002, physical reads 1256, read-ahead reads 0
DBCC TRACEOFF(652)
GO

-- Ué continua fazendo I/O de 64KB ? ... Pq?







-- É o ramp-up... SQL vai continuar fazendo isso até "esquentar o cache"...

-- Apenas 1GB de memória...
sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Populando o cache todo pra parar com o Rampup...
EXEC Test2.dbo.st_LimpaCache
GO
SELECT object_name,
       counter_name,
       cntr_value / 1024. AS MBs
  FROM sys.dm_os_performance_counters
 WHERE counter_name IN('Target Server Memory (KB)', 'Total Server Memory (KB)')
GO


-- E agora, sem read-ahead e sem Rampup, como fica o I/O? 
-- Agora sim... um I/O por pagina... :-( ... Ouch... 
DBCC TRACEON(652)
SET STATISTICS IO ON
SELECT * FROM Fabiano_Test_ReadAhead.dbo.Table1
SET STATISTICS IO OFF
-- Table 'Table1'. Scan count 1, logical reads 10002, physical reads 10002, read-ahead reads 0
DBCC TRACEOFF(652)
GO


-- Cleanup
sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
-- Set BP to 10GB
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO

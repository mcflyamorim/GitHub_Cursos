----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



-- Preparando demo 
USE master
GO

-- Apenas 1GB de memória... quero fazer I/O... não quero ler do disco :-) 
sp_configure 'show advanced options', 1;  
RECONFIGURE;
GO 
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO

/*
-- 30 segundos pra rodar...
-- Criando um banco pra me ajudar a limpar o BP data cache de apenas 1 banco
if exists (select * from sysdatabases where name='Test2')
BEGIN
  ALTER DATABASE Test2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test2
end
GO
CREATE DATABASE Test2
 ON  PRIMARY 
( NAME = N'Test2', FILENAME = N'C:\DBs\Test2.mdf' , SIZE = 5GB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test2_log', FILENAME = N'C:\DBs\Test2_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE Test2
GO
-- Criar 2 tabelas com +- 900MB
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
ALTER TABLE Products1 ADD CONSTRAINT xpk_Products1 PRIMARY KEY(ProductID)
GO
SELECT * INTO Products2 FROM Products1
GO
ALTER TABLE Products2 ADD CONSTRAINT xpk_Products2 PRIMARY KEY(ProductID)
GO
-- Meter migué pro SQL pra evitar que ele faça disfavoring das minhas leituras...
-- Quando eu ler essas tabelas, quero que ele remove as tabelas do banco Test1 e 
-- Não que fique concorrendo com ele mesmo...
UPDATE STATISTICS Products1 WITH ROWCOUNT = 1, PAGECOUNT = 1
UPDATE STATISTICS Products2 WITH ROWCOUNT = 1, PAGECOUNT = 1
GO

DROP PROC IF EXISTS st_LimpaCache
GO
CREATE PROC st_LimpaCache
AS
BEGIN
  -- Lendo as tabelas (+- 1.8GB) pra forçar que o SQL limpe o cache 
  -- do banco Test1
  DECLARE @i Int
  SELECT @i = COUNT(*) FROM Test2.dbo.Products1
  SELECT @i = COUNT(*) FROM Test2.dbo.Products2
END
GO
*/


-- 30 segundos pra rodar...
if exists (select * from sysdatabases where name='Test_Fabiano_Prefetch')
BEGIN
  ALTER DATABASE Test_Fabiano_Prefetch SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test_Fabiano_Prefetch
end
GO
CREATE DATABASE Test_Fabiano_Prefetch
 ON  PRIMARY 
( NAME = N'Test_Fabiano_Prefetch', FILENAME = N'E:\Test_Fabiano_Prefetch.mdf' , SIZE = 1GB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test_Fabiano_Prefetch_log', FILENAME = N'C:\DBs\Test_Fabiano_Prefetch_log.ldf' , SIZE = 50MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO
USE Test_Fabiano_Prefetch
GO
-- Criando tabela para testes...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixCustomerID ON OrdersBig (CustomerID, OrderDate)
GO




-- Removendo dados da tabela OrdersBig do cache
EXEC Test2.dbo.st_LimpaCache
GO

-- Confirmando se ramp-up já parou...
-- Quando target for atingido pela primeira vez, o SQL para de 
-- fazer o ramp-up (a cada 1 leitura, ao invés de enviar read de 8KB, manda 64KB... 
-- ou seja, 8 páginas)
-- Pra essa demo, o ramp-up não pode entrar, senão vai estragar o que quero fazer... 
-- :-)
SELECT object_name,
       counter_name,
       cntr_value / 1024. AS MBs
  FROM sys.dm_os_performance_counters
 WHERE counter_name IN('Target Server Memory (KB)', 'Total Server Memory (KB)')
GO


-- Removendo dados da tabela OrdersBig do cache
EXEC Test2.dbo.st_LimpaCache;
-- Colocando dados de ixCustomerID na memória...
SELECT COUNT(*) FROM OrdersBig WITH(INDEX=ixCustomerID)
SELECT * FROM OrdersBig WHERE OrderID = 1
GO

-- Abrir perfmon em e analisar contadores...
-- ...\Scripts\9 - IO - Prefetch\Perfmon.msc

-- Estressar o disco E:\
/*
  c:\sqlio\sqlio.exe -kR -t16 -dE -s9999 -b32
*/

-- Como fica a performance da query com o prefetch?
-- Número de page lookups/sec (páginas encontradas em cache) 
-- na média de 6k...
-- Read ahead/sec alto...
-- Used leaf page cookie alto... esse contador mostra páginas 
---- que foram lidas "antes" e foram utilizadas com sucesso...
SET STATISTICS IO ON
SELECT TOP 10000 * FROM OrdersBig WITH(FORCESEEK)
WHERE CustomerID >= 0
  AND OrderDate BETWEEN '20101201' AND '20201231'
OPTION (MAXDOP 1, QueryTraceOn 9130 
                 --,QueryTraceOn 8744 -- Desabilita prefetch
       )
SET STATISTICS IO OFF
-- Scan count 1, logical reads 30696, physical reads 0, read-ahead reads 0
GO

-- Removendo dados da tabela OrdersBig do cache
EXEC Test2.dbo.st_LimpaCache
GO
-- Colocando dados de ixCustomerID na memória...
SELECT COUNT(*) FROM OrdersBig WITH(INDEX=ixCustomerID)
SELECT * FROM OrdersBig WHERE OrderID = 1
GO

-- E sem o o prefetch?
-- Número de page lookups/sec (páginas encontradas em cache)
-- na média de 300... maioria dos I/Os tem que esperar 
-- no pageiolatch...
-- Readahead counter zerado...
SET STATISTICS IO ON
SELECT TOP 10000 * FROM OrdersBig WITH(FORCESEEK)
WHERE CustomerID >= 0
  AND OrderDate BETWEEN '20101201' AND '20201231'
OPTION (MAXDOP 1, QueryTraceOn 9130 
                 ,QueryTraceOn 8744 -- Desabilita prefetch
       )
SET STATISTICS IO OFF
-- Scan count 1, logical reads 16653, physical reads 2540, read-ahead reads 0
GO



-- Cleanup
EXEC sys.sp_configure N'max server memory (MB)', N'10240'
GO
RECONFIGURE WITH OVERRIDE
GO
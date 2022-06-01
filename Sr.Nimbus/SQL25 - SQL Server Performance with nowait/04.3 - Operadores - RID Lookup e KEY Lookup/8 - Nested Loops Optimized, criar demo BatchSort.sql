/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



-- Formatar disco antes de iniciar...

USE Master
GO
-- DROP DATABASE TestBatchSort

-- Criar banco de dados com 15GB...
CREATE DATABASE TestBatchSort ON PRIMARY 
( NAME = N'TestBatchSort', FILENAME = N'G:\TestBatchSort.mdf' , SIZE = 15360000KB, FILEGROWTH = 102400KB)
 LOG ON 
( NAME = N'TestBatchSort_log', FILENAME = N'G:\TestBatchSort_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE TestBatchSort SET RECOVERY SIMPLE
GO

USE TestBatchSort
GO
IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1
GO
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY, 
                       Col1 Char(1500) DEFAULT NEWID(),
                       Col2 Char(1500) DEFAULT NEWID(),
                       Col3 Char(1500) DEFAULT NEWID(),
                       Col4 BigInt NULL)
GO

-- Aproximadamente 24 minutos para rodar
DBCC TRACEON(610)
GO
INSERT INTO TestTab1 WITH(TABLOCK) (Col4)
SELECT TOP 10000 CHECKSUM(NEWID()) / 10000
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 200
DBCC TRACEOFF(610)
GO

-- Criar arquivo de banco de 450GB para encher o disco e forçar alocação do índice pro fim do disco
CREATE DATABASE TestBatchSortTMP ON PRIMARY 
( NAME = N'TestBatchSortTMP', FILENAME = N'G:\TestBatchSortTMP.mdf' , SIZE = 450560000KB, FILEGROWTH = 10%)
 LOG ON 
( NAME = N'TestBatchSortTMP_log', FILENAME = N'G:\TestBatchSortTMP_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

-- Incluir mais algumas linhas na tabela para preencher o espaço vazio do arquivo...
-- e gerar um novo auto growth no fim do disco...
-- Aproximadamente 00:05:48 para rodar
DBCC TRACEON(610)
GO
INSERT INTO TestTab1 WITH(TABLOCK) (Col4)
SELECT TOP 10000 CHECKSUM(NEWID()) / 10000
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 100
DBCC TRACEOFF(610)
GO

-- Aproximadamente 00:11:52 para rodar
CREATE INDEX ix_Col4 ON TestTab1(Col4) WITH(MAXDOP = 1)
GO
CHECKPOINT
GO

-- Apagar o banco temporário...
DROP DATABASE TestBatchSortTMP 
GO

-- Checking table size
sp_spaceused TestTab1
GO
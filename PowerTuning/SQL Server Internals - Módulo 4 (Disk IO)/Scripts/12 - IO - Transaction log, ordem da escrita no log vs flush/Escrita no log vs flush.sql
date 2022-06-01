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
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
end
GO

-- Criar banco de 10MB no pendrive (E:\) com IFI
-- 7 segundos pra rodar
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'E:\Test1.mdf' , SIZE = 50MB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'E:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE Test1
GO

-- Criando tabela pra usar nos testes
DROP TABLE IF EXISTS Tab1
CREATE TABLE Tab1 (Col1 INT, Col2 CHAR(7500))
INSERT Tab1 (Col1) VALUES(1)
GO

CHECKPOINT
GO
BEGIN TRAN

INSERT Tab1 (Col1) VALUES(2)

COMMIT
GO

-- Ver o que foi gerado no Log
SELECT * FROM ::fn_dblog(null, null)
--LOP_BEGIN_XACT
--LOP_INSERT_ROWS
--LOP_COMMIT_XACT
GO
CHECKPOINT
GO

-- Qual o estado da página? dirty?
SELECT b.* FROM sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
INNER JOIN sys.allocation_units AS a WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] = object_id('Tab1')
GO

-- Modificação, gera update no cabeçalho da página
-- em memória... pra informar o novo LSN
BEGIN TRAN

UPDATE Tab1 SET Col2 = 'Fabiano'
WHERE Col1 = 2


-- Qual o m_lsn do cabeçalho da página? 
DBCC TRACEON(3604)
DBCC PAGE (Test1,1,337,3)
DBCC TRACEOFF(3604)
-- m_lsn = (37:367:2)
GO

ROLLBACK
GO

-- Qual o m_lsn do cabeçalho da página? 
DBCC TRACEON(3604)
DBCC PAGE (Test1,1,337,3)
DBCC TRACEOFF(3604)
-- m_lsn = (37:367:3)
GO
CHECKPOINT
GO



-- E se checkpoint entrar?
BEGIN TRAN

UPDATE Tab1 SET Col2 = 'Fabiano'
WHERE Col1 = 2


-- Qual o estado da página? dirty?
SELECT b.* FROM sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
INNER JOIN sys.allocation_units AS a WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] = object_id('Tab1')


-- Qual o m_lsn do cabeçalho da página? 
DBCC TRACEON(3604)
DBCC PAGE (Test1,1,337,3)
DBCC TRACEOFF(3604)
-- m_lsn = (37:432:2)


CHECKPOINT

-- Antes de persistir o log, faz o flush da página...
-- Qual o estado da página? dirty?
SELECT b.* FROM sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
INNER JOIN sys.allocation_units AS a WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] = object_id('Tab1')

-- Mas como fica a página se fizer o rollback?
-- Vai desfazer a operação na página?
ROLLBACK
GO

-- Yep, olha ela suja denovo...
-- Desfaz apenas em memória...
SELECT b.* FROM sys.dm_os_buffer_descriptors AS b WITH (NOLOCK)
INNER JOIN sys.allocation_units AS a WITH (NOLOCK)
ON a.allocation_unit_id = b.allocation_unit_id
INNER JOIN sys.partitions AS p WITH (NOLOCK)
ON a.container_id = p.hobt_id
WHERE b.database_id = CONVERT(int,DB_ID())
AND p.[object_id] = object_id('Tab1')
GO

-- Qual o m_lsn do cabeçalho da página? 
DBCC TRACEON(3604)
DBCC PAGE (Test1,1,337,3)
DBCC TRACEOFF(3604)
-- m_lsn = (37:466:1)
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- Rodar em modo SQLCMD --

:CONNECT dellfabiano\SQL2019
GO

USE [master]
GO
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE [Test1] SET PARTNER OFF
END
if exists (select * from sysdatabases where name='Test1')
BEGIN
  --ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
end
GO

:CONNECT dellfabiano\SQL2017
GO
USE [master]
GO
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE [Test1] SET PARTNER OFF
END
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

-- Criando tabela com linha BEM pequena
DROP TABLE IF EXISTS Tab1
CREATE TABLE Tab1 (Col1 BIT DEFAULT 0)
GO
INSERT INTO Tab1 DEFAULT VALUES
GO 10

-- Altera o Recovery Model do Principal Server para FULL
ALTER DATABASE Test1 SET RECOVERY FULL
GO
EXEC xp_cmdShell 'del C:\DBs\Test1_Data.bak'
GO
EXEC xp_cmdShell 'del C:\DBs\Test1_Log.bak'
GO
-- Faz o backup para restaurar no Mirror Server
BACKUP DATABASE Test1 TO  DISK = N'C:\DBs\Test1_Data.bak'
WITH NOFORMAT, NOINIT,  NAME = N'Test1-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
BACKUP LOG Test1 TO DISK = N'C:\DBs\Test1_Log.bak'
WITH NOFORMAT, NOINIT,  NAME = N'Test1-Full Log Backup', 
SKIP, NOREWIND, NOUNLOAD,  STATS = 10
GO
--  Cria EndPoint no Principal Server
IF EXISTS (SELECT name FROM sys.database_mirroring_endpoints WHERE name='Mirroring')
  DROP ENDPOINT Mirroring
GO
CREATE ENDPOINT Mirroring
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022)
    FOR DATABASE_MIRRORING (ROLE = PARTNER);
GO

:CONNECT dellfabiano\SQL2019
GO
/* Cria EndPoint no Mirror Server / Rodar no Mirror Server */
IF EXISTS (SELECT name FROM sys.database_mirroring_endpoints WHERE name='Mirroring')
  DROP ENDPOINT Mirroring
GO
CREATE ENDPOINT Mirroring
    STATE = STARTED
    AS TCP ( LISTENER_PORT = 5023 )
    FOR DATABASE_MIRRORING (ROLE=PARTNER);
GO
IF (SELECT DB_ID('Test1')) IS NOT NULL
BEGIN
  USE Master
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
  DROP DATABASE Test1
END
GO
RESTORE DATABASE Test1 FROM DISK = N'C:\DBs\Test1_Data.bak' WITH  FILE = 1,  
MOVE N'Test1' TO N'E:\Test1_2.mdf',  
MOVE N'Test1_Log'  TO N'C:\DBs\Test1_1_2.ldf',  
NORECOVERY,  NOUNLOAD,  REPLACE,  STATS = 10
GO
RESTORE LOG [Test1] FROM DISK = N'C:\DBs\Test1_Log.bak' WITH  FILE = 1,
NORECOVERY,  NOUNLOAD,  STATS = 10
GO


:CONNECT dellfabiano\SQL2019
GO
USE Master
GO
 ALTER DATABASE Test1
   SET PARTNER = 'TCP://dellfabiano:5022'
GO

:CONNECT dellfabiano\SQL2017
GO
-- Configurar o mirror server como um PARTNER do principal server
-- Executar no Principal Server
ALTER DATABASE Test1 
  SET PARTNER = 'TCP://dellfabiano:5023'
GO
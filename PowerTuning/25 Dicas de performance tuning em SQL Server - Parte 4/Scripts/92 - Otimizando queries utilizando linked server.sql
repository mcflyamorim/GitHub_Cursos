-- Rodar em ::RazerFabiano\SQL2008R2 e ::RazerFabiano\SQL2017
USE NorthWind
GO

IF OBJECT_ID('Table1') IS NOT NULL
  DROP TABLE Table1

SET NOCOUNT ON
CREATE TABLE dbo.Table1 (
	ID INTEGER IDENTITY(1, 1) PRIMARY KEY,
	GUID UNIQUEIDENTIFIER,
	GUIDSTR VARCHAR(50)
)

DECLARE @I INTEGER
SET @I = 0

-- Insert some data into our test table.
WHILE @I < 100000
BEGIN
	INSERT INTO dbo.Table1 VALUES(NEWID(), NEWID())
	SET @I = @I + 1
END

-- ...and double-it.
INSERT INTO dbo.Table1
SELECT GUID, GUIDSTR
FROM dbo.Table1

-- ...and again.
INSERT INTO dbo.Table1
SELECT GUID, GUIDSTR
FROM dbo.Table1

-- Add an index on GUID, then on GUIDSTR
CREATE NONCLUSTERED INDEX idx_1 ON dbo.Table1 (
	GUID
)

CREATE NONCLUSTERED INDEX idx_2 ON dbo.Table1 (
	GUIDSTR
)

IF OBJECT_ID('Table2') IS NOT NULL
  DROP TABLE Table2

-- Copy the data into a second table, then add indexes as per the first.
SELECT *
INTO dbo.Table2
FROM dbo.Table1

CREATE UNIQUE CLUSTERED INDEX idx_0 ON dbo.Table2(
	ID
)
CREATE NONCLUSTERED INDEX idx_1 ON dbo.Table2 (
	GUID
)
CREATE NONCLUSTERED INDEX idx_2 ON dbo.Table2 (
	GUIDSTR
)
GO


-- Conectar em ::RazerFabiano\SQL2008R2

-- Criando usuário com db_datareader no banco NorthWind 
USE [master]
GO
CREATE LOGIN [TestUser1] WITH PASSWORD=N'@bc12345', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
USE [Northwind]
GO
CREATE USER [TestUser1] FOR LOGIN [TestUser1]
GO
USE [Northwind]
GO
EXEC sp_addrolemember N'db_datareader', N'TestUser1'
GO


-- Conectar em ::RazerFabiano\SQL2017
-- Criar linked server para SQL2008R2
USE [master]
GO
EXEC master.dbo.sp_dropserver @server=N'RazerFabiano\SQL2008R2', @droplogins='droplogins'
GO

EXEC master.dbo.sp_addlinkedserver @server = N'RazerFabiano\SQL2008R2', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'RazerFabiano\SQL2008R2',@useself=N'False',@locallogin=NULL,
@rmtuser=N'TestUser1',@rmtpassword='@bc12345'
GO


-- Conectar em ::RazerFabiano\SQL2017
USE Northwind
GO

SELECT	*
  FROM	dbo.Table1 T1
 INNER JOIN	"RazerFabiano\SQL2008R2".NorthWind.dbo.Table2 T2
    ON	T1.ID =	T2.ID
 WHERE	T2.GUIDSTR LIKE '123%'
OPTION (RECOMPILE)
GO


-- Conectar em ::RazerFabiano\SQL2008R2
-- Definir TestUser1 como sysadmin...

EXEC master..sp_addsrvrolemember @loginame = N'TestUser1', @rolename = N'sysadmin'
GO

--  fixed in SQL Server 2012 SP1
/*
DBCC SHOW_STATISTICS works with SELECT permission
In earlier releases of SQL Server, customers need administrative or ownership permissions to run DBCC SHOW_STATISTICS.
In order to view the statistics object, the user must own the table or the user must be a member of
the sysadmin fixed server role, the db_owner fixed database role, or the db_ddladmin fixed database role.


This restriction impacted the Distributed Query functionality in SQL Server because, in many cases, 
customers running distributed queries did not have administrative or ownership permissions against remote 
tables to be able to gather statistics as part of the compilation of the distributed query.

While such scenarios still execute, it often results in sub-optimal query plan choices that negatively impact performance. 
SQL Server 2012 SP1 modifies the permission restrictions and allows users with SELECT permission to use this command. 
Note that the following requirements exist for SELECT permissions to be sufficient to run the command:

Users must have permissions on all columns in the statistics object
Users must have permission on all columns in a filter condition (if one exists)

Customers using Distributed Query should notice that statistics can now be used when compiling queries from remote SQL Server
data sources where they have only SELECT permissions. Trace flag 9485 exists to revert the new permission 
check to SQL Server 2012 RTM behavior in case of regression in customer scenarios.
*/
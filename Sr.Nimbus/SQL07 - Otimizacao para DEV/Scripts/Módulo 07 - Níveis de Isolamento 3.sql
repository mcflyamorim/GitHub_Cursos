/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07 - Módulo 03
	
**************************************************************************************************/
-- Tipos de transação
use tempdb
go

CREATE TABLE Teste
(Codigo INT IDENTITY(1,1) NOT NULL,
 Nome VARCHAR(255) NOT NULL)
go

-- Default
INSERT INTO Teste VALUES ('Luciano Moreira')

BEGIN TRANSACTION
	INSERT INTO Teste VALUES ('Joao José')
COMMIT TRANSACTION

select * from sys.syslockinfo

exec sp_lock

select * from sys.dm_tran_locks
go



-- DEADLOCK
USE sql07
go

IF OBJECT_ID('dbo.T1') IS NOT NULL
  DROP TABLE dbo.T1
IF OBJECT_ID('dbo.T2') IS NOT NULL
  DROP TABLE dbo.T2
GO

CREATE TABLE dbo.T1
(
  keycol INT         NOT NULL PRIMARY KEY,
  col1   INT         NOT NULL,
  col2   VARCHAR(50) NOT NULL
)

INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 101, 'A')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(2, 102, 'B')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(3, 103, 'C')

CREATE TABLE dbo.T2
(
  keycol INT         NOT NULL PRIMARY KEY,
  col1   INT         NOT NULL,
  col2   VARCHAR(50) NOT NULL
)

INSERT INTO dbo.T2(keycol, col1, col2) VALUES(1, 201, 'X')
INSERT INTO dbo.T2(keycol, col1, col2) VALUES(2, 202, 'Y')
INSERT INTO dbo.T2(keycol, col1, col2) VALUES(3, 203, 'Z')
GO

SELECT * FROM dbo.T1
SELECT * FROM dbo.T2

set transaction isolation level read committed
-- Connection 1
BEGIN TRAN
  UPDATE dbo.T1 SET col1 = col1 + 1 WHERE keycol = 2
select @@trancount
-- Connection 2
GO
BEGIN TRAN
  UPDATE dbo.T2 SET col1 = col1 + 1 WHERE keycol = 2

exec sp_lock
  exec sp_who2

-- Connection 1
  SELECT col1 FROM dbo.T2
  exec sp_lock
  exec sp_who2
COMMIT TRAN


-- Connection 2
  SELECT col1 FROM dbo.T1 
COMMIT TRAN

rollback



USE Master
GO

/*
ALTER DATABASE SnapshotInternals
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
*/

IF EXISTS (SELECT database_id FROM sys.databases WHERE name = 'SnapshotInternals')
BEGIN
	DROP DATABASE SnapshotInternals
END

CREATE DATABASE SnapshotInternals
GO

/*
	Mostra que por padrão o SNAPSHOT ISOLATION LEVEL ou o READ COMMITTED SNAPSHOT não estão habilitados, com
	exceção da master e msdb.
*/
-- Como a model está com o snapshot desabilitado, todos novos bancos também ficarão com ele desatibitado por padrão
SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM Sys.Databases
go

USE SnapshotInternals
GO

IF EXISTS (SELECT * FROM sys.all_objects WHERE Type = 'U' and name = 'SnapIsolation')
BEGIN
	DROP TABLE SnapIsolation
END

CREATE TABLE SnapIsolation
(
	Codigo INT Identity NOT NULL PRIMARY KEY,
	Nome VARCHAR(200) NOT NULL,
	VersaoLinha VARCHAR(100) NULL
)
GO

/*
	Vai dar erro? Se sim, quando?
*/
SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	SELECT @@TRANCOUNT	
	INSERT INTO SnapIsolation VALUES ('Snapshot desabilitado', '00_0001')
	SELECT @@TRANCOUNT
-- COMMIT TRANSACTION

/*
	No momento que o insert é executado, o erro é exibido
	
Msg 3952, Level 16, State 1, Line 5
Snapshot isolation transaction failed accessing database 'SnapshotInternals' because snapshot isolation 
	is not allowed in this database. Use ALTER DATABASE to allow snapshot isolation.
*/

/*
	Demonstra o comportamento padrão, read committed
*/
SELECT @@SPID
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	INSERT INTO SnapIsolation VALUES ('Snapshot desabilitado', '01_0001')
	SELECT @@TRANCOUNT
		
	
/*
	Em outra conexão executar:

	SELECT @@SPID	
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED	
	SELECT * FROM SnapIsolation
*/
	SELECT * FROM sys.sysprocesses WHERE spid > 50
	
COMMIT TRANSACTION
go

/***************************************************************************************
 ***************************************************************************************
 
	Configura o snapshot_isolation
	Transaction level read consistency
*/
ALTER DATABASE SnapshotInternals
    SET ALLOW_SNAPSHOT_ISOLATION ON

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT OFF
GO

SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM Sys.Databases
go

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION
	SELECT @@TRANCOUNT	
	INSERT INTO SnapIsolation VALUES ('Snapshot habilitado', '02_0001')	
COMMIT TRANSACTION
-- Agora tudo funcionou direitinho, mas para que eu uso esse nível de isolamento?

-- Mostra o que eu tenho antes de iniciar a transação
SELECT * FROM SnapIsolation

BEGIN TRANSACTION
	INSERT INTO SnapIsolation VALUES ('Snapshot habilitado_Ex02', '03_0001')	
	SELECT * FROM SnapIsolation
	SELECT @@TRANCOUNT
	
/*
	Em outra conexão executar:
		
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRANSACTION	
		SELECT * FROM SnapIsolation
		SELECT @@TRANCOUNT
	COMMIT TRANSACTION	
*/

	-- Analisamos o que temos.
	SELECT * FROM SnapIsolation

	-- Verificar o que aconteceu com a outra conexão
	SELECT @@SPID
	SELECT * FROM sys.sysprocesses where spid > 50
	/*
		Com o RC, a outra conexão fica bloqueada.
	*/
	
/*
	Em outra conexão executar:
	
	select @@TRANCOUNT
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	BEGIN TRANSACTION	
		SELECT * FROM SnapIsolation
	COMMIT TRANSACTION
*/	
	
	SELECT * FROM SnapIsolation
	go
	
	UPDATE SnapIsolation
	SET VersaoLinha = '01_0003'
	WHERE Codigo = 1
	go
	
	SELECT * FROM SnapIsolation
	go
	
/*
	Em outra conexão executar a mesma consulta acima.
*/	
COMMIT TRANSACTION
/*
	E agora, o que vamos ver na outra conexão??
	R: Vemos o mesmo que estávamos vendo, pois a segunda transação ainda está aberta e retorna uma imagem
	consistente no tempo.
*/



/***************************************************************************************
 ***************************************************************************************
	
	Configura o read_committed snapshot - Não podem haver conexões no banco de dados
	Statement level read consistency	
*/
ALTER DATABASE SnapshotInternals SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
go

USE SnapshotInternals
go

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT ON
GO

ALTER DATABASE SnapshotInternals SET MULTI_USER
go

SELECT [Name], snapshot_isolation_state, snapshot_isolation_state_desc, is_read_committed_snapshot_on 
	FROM MASTER.Sys.Databases
	WHERE [Name] = 'SnapshotInternals'
go

/*
	Mostra a diferença entre o snapshot isolation level e o read committed snapshot
*/

SET TRANSACTION ISOLATION LEVEL SNAPSHOT
BEGIN TRANSACTION

	UPDATE SnapIsolation
	SET VersaoLinha = '01_0004'
	WHERE Codigo = 1
	
	SELECT * FROM SnapIsolation
	SELECT @@TRANCOUNT
	
	UPDATE SnapIsolation
	SET VersaoLinha = '01_0005'
	WHERE Codigo = 1
	
/*
	Em outra conexão executar:
	
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
		
	-- O SELECT é executado sem nenhum problema, mas a transação não concluída é ignorada.
	SELECT * FROM SnapIsolation
	
	
	-- Depois que a outra transação for concluída, executar o select novamente.
	-- O registro deve ser retornado, pois o snapshot é statemente level, não transaction level
	SELECT @@TRANCOUNT
	SELECT * FROM SnapIsolation
COMMIT TRANSACTION

*/		
	SELECT * FROM SnapIsolation
	go
	
/*
	Em outra conexão executar a mesma consulta acima.
*/	
COMMIT TRANSACTION -- (Depois)



/*
	Author: Luciano Caixeta Moreira
	Date: 02/26/2008
	Description: Shows how to version store is organized and maintained, using DMVs.
*/

USE Master
GO

/*
ALTER DATABASE SnapshotInternals
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE
*/

IF EXISTS (SELECT database_id FROM sys.databases WHERE name = 'SnapshotInternals')
BEGIN
	DROP DATABASE SnapshotInternals
END

CREATE DATABASE SnapshotInternals
GO

ALTER DATABASE SnapshotInternals
    SET ALLOW_SNAPSHOT_ISOLATION ON

ALTER DATABASE SnapshotInternals
    SET READ_COMMITTED_SNAPSHOT ON
GO

USE SnapshotInternals
GO

IF EXISTS (SELECT * FROM sys.all_objects WHERE Type = 'U' and name = 'SnapIsolation')
BEGIN
	DROP TABLE SnapIsolation
END

CREATE TABLE SnapIsolation
(
	Codigo INT Identity NOT NULL PRIMARY KEY,
	Nome VARCHAR(200) NOT NULL,
	VersaoLinha VARCHAR(100) NULL
)
GO

INSERT INTO SnapIsolation VALUES ('Registro 01', '01_0001')
INSERT INTO SnapIsolation VALUES ('Registro 02', '02_0001')
INSERT INTO SnapIsolation VALUES ('Registro 03', '03_0001')
INSERT INTO SnapIsolation VALUES ('Registro 04', '04_0001')
go

SELECT * FROM SnapIsolation
go

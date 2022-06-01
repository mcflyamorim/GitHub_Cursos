/********* Snip01 ***********

USE Master
go

IF NOT EXISTS (SELECT NAME FROM sys.databases WHERE name = 'SQL11')
	CREATE DATABASE SQL11
go

USE SQL11
go

IF OBJECT_ID('dbo.PessoaFisica') IS NOT NULL
	DROP TABLE dbo.PessoaFisica
GO

CREATE TABLE dbo.PessoaFisica(
	ID INT IDENTITY(1,1) NOT NULL,
	Nome VARCHAR(100) NULL,
	CPF CHAR(14) NULL,			
	DataNascimento DATE NULL,
	EstadoCivil VARCHAR(20) NULL,	
)
GO

CREATE UNIQUE CLUSTERED INDEX idxCL_PessoaFisica_CPF
ON dbo.PessoaFisica(CPF)
GO

*/


/********* Snip02 ***********

USE SQL11
go

IF OBJECT_ID('dbo.proc_InserePessoaFisica') IS NOT NULL
	DROP PROCEDURE dbo.proc_InserePessoaFisica
GO

CREATE PROCEDURE dbo.proc_InserePessoaFisica 
	@CPF CHAR(14)
	,@Nome VARCHAR(100)
	,@DataNascimento DATE = NULL
	,@EstadoCivil VARCHAR(20) = NULL
	,@MantemOriginal BIT = 0
AS		

	IF (@CPF IS NULL)
	BEGIN
		RAISERROR ('O parâmetro @CPF não pode ser NULL', 16, 1)
		RETURN -1
	END
		  
	IF (@Nome IS NULL)
	BEGIN	
		RAISERROR ('O parâmetro @Nome não pode ser NULL', 16, 1)
		RETURN -1
	END
	
	INSERT INTO dbo.PessoaFisica (CPF, Nome, DataNascimento, EstadoCivil)
		VALUES (@CPF, @Nome, @DataNascimento, @EstadoCivil)

	RETURN @@IDENTITY	
GO

*/


/********* Snip03 ***********

EXEC proc_InserePessoaFisica '111.111.111-12', 'Luti Nimbus', '1979-01-01', 'Casado'
go

SELECT * FROM dbo.PessoaFisica
go
-- Inseriu, parece tudo beleza? Teste ok!

*/

/********* Snip04 ***********

-- Ops, meu "teste" foi ruim!
DECLARE @Retorno INT
EXEC @Retorno = proc_InserePessoaFisica '111.111.111-11', 'Luti Nimbus', '1979-01-01', 'Casado'
PRINT @Retorno
go
SELECT * FROM dbo.PessoaFisica
go

*/

/********* Snip05 ***********

USE SQL11
go

SET NOCOUNT ON

-- SETUP

-- TESTES
DECLARE @Retorno INT


--*****************************************************************************
-- Registro mínimo
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-12', 
	@Nome = 'GB Nimbus'	
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 1 AND @Retorno = 1
	AND Nome = 'GB Nimbus' AND CPF = '111.111.111-12' 
	AND DataNascimento IS NULL AND EstadoCivil IS NULL)
	RAISERROR ('***Teste falhou!***  Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)


--*****************************************************************************
-- Registro básico de pessoa física
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-15', 
	@Nome = 'Luti Nimbus', 
	@DataNascimento = '1979-01-01', 
	@EstadoCivil = 'Casado'	
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 2 AND @Retorno = 2
	AND Nome = 'Luti Nimbus' AND CPF = '111.111.111-15' 
	AND DataNascimento = '1979-01-01' AND EstadoCivil = 'Casado')
	RAISERROR ('***Teste falhou!***  Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
	
--*****************************************************************************
-- Registro nome longo
-- Este tipo de teste normalmente é dispensável por exigir muitas combinações do tester
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-13', 
	@Nome = 'Sr. Fabraz Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus'	
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 3 AND @Retorno = 3
	AND Nome = 'Sr. Fabraz Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbus Nimbu'
	 AND CPF = '111.111.111-13' 
	AND DataNascimento IS NULL AND EstadoCivil IS NULL)
	RAISERROR ('***Teste falhou!***  Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)	

--*****************************************************************************
-- Verifica erro de parâmetros - @CPF
--*****************************************************************************
BEGIN TRY
	EXEC @Retorno = dbo.proc_InserePessoaFisica
		@CPF = NULL, 
		@Nome = 'GB Nimbus'	
	RAISERROR('***Teste falhou!***  Essa instrução nunca deve ser executada.', 16, 1)
END TRY
BEGIN CATCH
	IF ((ERROR_MESSAGE() <> 'O parâmetro @CPF não pode ser NULL') OR ERROR_PROCEDURE() <> 'proc_InserePessoaFisica')
	BEGIN
		PRINT ERROR_MESSAGE()
		RAISERROR ('Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
	END
END CATCH

--*****************************************************************************
-- Verifica erro de parâmetros - @Nome
--*****************************************************************************
BEGIN TRY
	EXEC @Retorno = dbo.proc_InserePessoaFisica
		@CPF = '111.111.111-12', 
		@Nome = NULL	
	RAISERROR('***Teste falhou!***  Essa instrução nunca deve ser executada.', 16, 1)
END TRY
BEGIN CATCH
	IF ((ERROR_MESSAGE() <> 'O parâmetro @Nome não pode ser NULL') OR ERROR_PROCEDURE() <> 'proc_InserePessoaFisica')
	BEGIN
		PRINT ERROR_MESSAGE()
		RAISERROR ('Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
	END
END CATCH

--*****************************************************************************
-- Verifica erro de parâmetros - @CPF e @Nome
--*****************************************************************************
BEGIN TRY
	EXEC @Retorno = dbo.proc_InserePessoaFisica
		@CPF = NULL, 
		@Nome = NULL
	RAISERROR('***Teste falhou!***  Essa instrução nunca deve ser executada.', 16, 1)
END TRY
BEGIN CATCH
	IF ((ERROR_MESSAGE() <> 'O parâmetro @CPF não pode ser NULL') OR ERROR_PROCEDURE() <> 'proc_InserePessoaFisica')
	BEGIN
		PRINT ERROR_MESSAGE()
		RAISERROR ('Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
	END
END CATCH

*/

/********* Snip06 ***********

SQLCMD -S lutixps\inst2012 -E -I -i "Setup BancoDados.sql"
SQLCMD -S lutixps\inst2012 -E -I -i "dbo.proc_InserePessoaFisica.sql"

*/

/********* Snip07 ***********

IF OBJECT_ID('dbo.RegistroDados') IS NOT NULL
	DROP TABLE dbo.RegistroDados
GO

CREATE TABLE dbo.RegistroDados(
	ID BIGINT IDENTITY(1,1) NOT NULL,
	Descricao VARCHAR(400) NULL	
)
GO

INSERT INTO dbo.RegistroDados (Descricao) VALUES ('Instalação do banco concluída.')
GO

CREATE TRIGGER trgI_PessoaFisica ON dbo.PessoaFisica
FOR INSERT 
AS
	INSERT INTO dbo.RegistroDados (Descricao) 
	SELECT 'Tabela PessoaFisica - ID: ' + CAST(INSERTED.ID AS VARCHAR) + 'Hora: ' + CAST(GETDATE() AS VARCHAR)
	FROM inserted		
GO

*/

/********* Snip08 ***********

--*****************************************************************************
-- Verifica erro de inserção duplicada de CPF
--*****************************************************************************
BEGIN TRY
	EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-15', 
	@Nome = 'Luti Nimbus', 
	@DataNascimento = '1979-01-01', 
	@EstadoCivil = 'Casado'
	
	RAISERROR('Teste falhou! Essa instrução nunca deve ser executada.', 16, 1)
END TRY
BEGIN CATCH
	IF ((ERROR_MESSAGE() <> 'Cannot insert duplicate key row in object ''dbo.PessoaFisica'' with unique index ''idxCL_PessoaFisica_CPF''. The duplicate key value is (111.111.111-15).') OR ERROR_PROCEDURE() <> 'proc_InserePessoaFisica')
	BEGIN
		PRINT ERROR_MESSAGE()
		RAISERROR ('Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
	END
END CATCH

*/

/********* Snip09 ***********

--*****************************************************************************
-- Atualiza dados da pessoa física
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-12', 
	@Nome = 'GB Nimbus',
	@DataNascimento = '1970-01-01', 
	@EstadoCivil = 'Casado'		
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 1 AND @Retorno = 1
	AND Nome = 'GB Nimbus' AND CPF = '111.111.111-12' 
	AND DataNascimento = '1970-01-01' AND EstadoCivil = 'Casado')
	RAISERROR ('Teste falhou! Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)

*/

/********* Snip10 ***********

--*****************************************************************************
-- Atualiza dados da pessoa física, mas verifica que nome não é alterado
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-12', 
	@Nome = 'GB Nimbus - Architect',
	@DataNascimento = '1971-01-01', 
	@EstadoCivil = 'Divorciado'		
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 1 AND @Retorno = 1
	AND Nome = 'GB Nimbus' AND CPF = '111.111.111-12' 
	AND DataNascimento = '1971-01-01' AND EstadoCivil = 'Divorciado')
	RAISERROR ('Teste falhou! Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)	

*/

/********* Snip11 ***********
	
--*****************************************************************************
-- Update = Novos valores NULLs não são considerados
--*****************************************************************************
EXEC @Retorno = dbo.proc_InserePessoaFisica
	@CPF = '111.111.111-12', 
	@Nome = 'GB Nimbus',
	@DataNascimento = NULL, 
	@EstadoCivil = NULL	
IF NOT EXISTS
(SELECT ID
  FROM dbo.PessoaFisica
  WHERE ID = 1 AND @Retorno = 1
	AND Nome = 'GB Nimbus' AND CPF = '111.111.111-12' 
	AND DataNascimento = '1971-01-01' AND EstadoCivil = 'Divorciado')
	RAISERROR ('Teste falhou! Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)	

*/

/********* Snip12 ***********

USE SQL11
go

IF OBJECT_ID('dbo.proc_InserePessoaFisica') IS NOT NULL
	DROP PROCEDURE dbo.proc_InserePessoaFisica
GO

CREATE PROCEDURE dbo.proc_InserePessoaFisica 
	@CPF CHAR(14)
	,@Nome VARCHAR(100)
	,@DataNascimento DATE = NULL
	,@EstadoCivil VARCHAR(20) = NULL
	,@MantemOriginal BIT = 0
AS		
	
	DECLARE @IDPessoaFisica INT	
	DECLARE @Resultado TABLE (Acao VARCHAR(30), IDPessoaFisica INT)
	
	IF (@CPF IS NULL)
	BEGIN
		RAISERROR ('O parâmetro @CPF não pode ser NULL', 16, 1)
		RETURN -1
	END
		  
	IF (@Nome IS NULL)
	BEGIN	
		RAISERROR ('O parâmetro @Nome não pode ser NULL', 16, 1)
		RETURN -1
	END
	
	INSERT INTO @Resultado
	SELECT * FROM 
	(	
		MERGE INTO dbo.PessoaFisica AS D
		USING (SELECT 
			@CPF AS CPF,
			@Nome AS Nome,
			@DataNascimento AS DataNascimento,
			@EstadoCivil AS EstadoCivil) AS O
		ON D.CPF = O.CPF
		WHEN MATCHED
			THEN UPDATE 
				SET 
					D.DataNascimento = COALESCE(O.DataNascimento, D.DataNascimento)
					, D.EstadoCivil = COALESCE(O.EstadoCivil, D.EstadoCivil)
		WHEN NOT MATCHED
			THEN INSERT (CPF, Nome, DataNascimento, EstadoCivil)
				VALUES (O.CPF, O.Nome, O.DataNascimento, O.EstadoCivil)
		OUTPUT $Action, INSERTED.ID) AS Resultado (Acao, IDPessoaFisica);
		
	IF (@@ROWCOUNT = 1 and EXISTS (SELECT Acao FROM @Resultado))	
	BEGIN
		SELECT @IDPessoaFisica = IDPessoaFisica FROM @Resultado	
	END	

	RETURN @IDPessoaFisica
GO

*/

/********* Snip13 ***********

USE Master
go

IF NOT EXISTS (SELECT NAME FROM sys.databases WHERE name = 'SQL11')
	CREATE DATABASE SQL11
go

USE SQL11
go

IF OBJECT_ID('dbo.PessoaFisica_Tabela') IS NOT NULL
	DROP TABLE dbo.PessoaFisica_Tabela
GO

IF OBJECT_ID('dbo.EstadoCivil') IS NOT NULL
	DROP TABLE dbo.EstadoCivil
GO

CREATE TABLE dbo.EstadoCivil(
	ID TINYINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	Nome VARCHAR(100) NULL
)
GO

INSERT INTO dbo.EstadoCivil VALUES ('Solteiro')
INSERT INTO dbo.EstadoCivil VALUES ('Casado')
INSERT INTO dbo.EstadoCivil VALUES ('Divorciado')
INSERT INTO dbo.EstadoCivil VALUES ('Viuvo')
GO

CREATE TABLE dbo.PessoaFisica_Tabela(
	ID INT IDENTITY(1,1) NOT NULL,
	Nome VARCHAR(100) NULL,
	CPF CHAR(14) NULL,			
	DataNascimento DATE NULL,
	IDEstadoCivil TINYINT NULL,	
)
GO

ALTER TABLE dbo.PessoaFisica_Tabela
ADD CONSTRAINT FK_PessoaFisica_Tabela_EstadoCivil_ID
FOREIGN KEY (IDEstadoCivil)
REFERENCES EstadoCivil(ID)
go

CREATE UNIQUE CLUSTERED INDEX idxCL_PessoaFisica_Tabela_CPF
ON dbo.PessoaFisica_Tabela(CPF)
GO


IF OBJECT_ID('dbo.RegistroDados') IS NOT NULL
	DROP TABLE dbo.RegistroDados
GO

CREATE TABLE dbo.RegistroDados(
	ID BIGINT IDENTITY(1,1) NOT NULL,
	Descricao VARCHAR(400) NULL	
)
GO

INSERT INTO dbo.RegistroDados (Descricao) VALUES ('Instalação do banco concluída.')
GO

CREATE TRIGGER trgI_PessoaFisica ON dbo.PessoaFisica_Tabela
FOR INSERT 
AS
	INSERT INTO dbo.RegistroDados (Descricao) 
	SELECT 'Tabela PessoaFisica - ID: ' + CAST(INSERTED.ID AS VARCHAR) + 'Hora: ' + CAST(GETDATE() AS VARCHAR)
	FROM inserted		
GO

IF OBJECT_ID('dbo.PessoaFisica') IS NOT NULL
	DROP VIEW dbo.PessoaFisica
GO

CREATE VIEW dbo.PessoaFisica
AS
	SELECT 
		P.ID,
		P.CPF,
		P.Nome,
		P.DataNascimento,
		E.Nome AS EstadoCivil		
	FROM dbo.PessoaFisica_Tabela AS P
	LEFT OUTER JOIN dbo.EstadoCivil AS E
	ON P.IDEstadoCivil = E.ID
go	

*/

/********* Snip14 ***********

CREATE PROCEDURE dbo.proc_InserePessoaFisica 
	@CPF CHAR(14)
	,@Nome VARCHAR(100)
	,@DataNascimento DATE = NULL
	,@EstadoCivil VARCHAR(20) = NULL
	,@MantemOriginal BIT = 0
AS		
	
	DECLARE @IDPessoaFisica INT
	DECLARE @IDEstadoCivil TINYINT
	DECLARE @Resultado TABLE (Acao VARCHAR(30), IDPessoaFisica INT)
	
	IF (@CPF IS NULL)
	BEGIN
		RAISERROR ('O parâmetro @CPF não pode ser NULL', 16, 1)
		RETURN -1
	END
		  
	IF (@Nome IS NULL)
	BEGIN	
		RAISERROR ('O parâmetro @Nome não pode ser NULL', 16, 1)
		RETURN -1
	END
	 
	IF (@EstadoCivil IS NOT NULL)
	BEGIN
		SELECT @IDEstadoCivil = ID
		FROM dbo.EstadoCivil
		WHERE Nome = @EstadoCivil
	END	 
	
	INSERT INTO @Resultado
	SELECT * FROM 
	(	
		MERGE INTO dbo.PessoaFisica_Tabela AS D
		USING (SELECT 
			@CPF AS CPF,
			@Nome AS Nome,
			@DataNascimento AS DataNascimento,
			@IDEstadoCivil AS IDEstadoCivil) AS O
		ON D.CPF = O.CPF
		WHEN MATCHED
			THEN UPDATE 
				SET 
					D.DataNascimento = COALESCE(O.DataNascimento, D.DataNascimento)
					, D.IDEstadoCivil = COALESCE(O.IDEstadoCivil, D.IDEstadoCivil)
		WHEN NOT MATCHED
			THEN INSERT (CPF, Nome, DataNascimento, IDEstadoCivil)
				VALUES (O.CPF, O.Nome, O.DataNascimento, O.IDEstadoCivil)
		OUTPUT $Action, INSERTED.ID) AS Resultado (Acao, IDPessoaFisica);
		
	IF (@@ROWCOUNT = 1 and EXISTS (SELECT Acao FROM @Resultado))	
	BEGIN
		SELECT @IDPessoaFisica = IDPessoaFisica FROM @Resultado	
	END	

	RETURN @IDPessoaFisica
GO

*/

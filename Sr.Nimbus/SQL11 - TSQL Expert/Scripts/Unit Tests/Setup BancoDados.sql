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
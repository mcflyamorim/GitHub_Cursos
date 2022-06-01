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
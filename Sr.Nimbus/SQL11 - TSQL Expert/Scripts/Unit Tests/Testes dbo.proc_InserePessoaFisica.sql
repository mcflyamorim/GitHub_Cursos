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

--*****************************************************************************
-- Verifica erro de inserção duplicada de CPF
--*****************************************************************************
--BEGIN TRY
--	EXEC @Retorno = dbo.proc_InserePessoaFisica
--	@CPF = '111.111.111-15', 
--	@Nome = 'Luti Nimbus', 
--	@DataNascimento = '1979-01-01', 
--	@EstadoCivil = 'Casado'
	
--	RAISERROR('Teste falhou! Essa instrução nunca deve ser executada.', 16, 1)
--END TRY
--BEGIN CATCH
--	IF ((ERROR_MESSAGE() <> 'Cannot insert duplicate key row in object ''dbo.PessoaFisica'' with unique index ''idxCL_PessoaFisica_CPF''. The duplicate key value is (111.111.111-15).') OR ERROR_PROCEDURE() <> 'proc_InserePessoaFisica')
--	BEGIN
--		PRINT ERROR_MESSAGE()
--		RAISERROR ('Problema com o teste da procedure Dados.proc_InserePessoaFisica', 16, 1)
--	END
--END CATCH


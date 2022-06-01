USE Northwind
GO


-- Criar tabela  Cadastro_Clientes que será utilizada nos testes
-- 30/35 segundos para rodar script
SET NOCOUNT ON
IF OBJECT_ID('Cadastro_Clientes') IS NOT NULL
  DROP TABLE Cadastro_Clientes
GO
CREATE TABLE Cadastro_Clientes (ID       BigInt IDENTITY(1,1),
                                CPF_CNPJ Char(14) DEFAULT CONVERT(Char(14), CONVERT(VarChar(200),NEWID())) NOT NULL,
                                RG       VarChar(20) DEFAULT CONVERT(VarChar(20), CONVERT(VarChar(200),NEWID())) NOT NULL,
                                Empresa  BigInt CONSTRAINT df_Empresa DEFAULT (ABS(Checksum(NEWID())) / 10000000.0) NOT NULL)
GO

ALTER TABLE Cadastro_Clientes ADD Nome Char(80)
ALTER TABLE Cadastro_Clientes ADD SobreNome VarChar(80)

------------------ DateTime Columns ---------------------
ALTER TABLE Cadastro_Clientes ADD DT_Cadastro DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_Alteracao DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_UltimaCompra DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_Fundacao DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_Nascimento DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_Obito DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_Aniversario DateTime
/* 8 bytes */
ALTER TABLE Cadastro_Clientes ADD DT_ExpedicaoRG DateTime
/* 8 bytes */

---------- Endereço, VarChar/Integer ---------------
ALTER TABLE Cadastro_Clientes ADD Rua VarChar(80)
ALTER TABLE Cadastro_Clientes ADD Bairro VarChar(80)
ALTER TABLE Cadastro_Clientes ADD Cidade VarChar(80)
ALTER TABLE Cadastro_Clientes ADD Estado VarChar(80)
ALTER TABLE Cadastro_Clientes ADD Numero Integer
ALTER TABLE Cadastro_Clientes ADD Telefone1 VarChar(20)
ALTER TABLE Cadastro_Clientes ADD Telefone2 VarChar(20)
ALTER TABLE Cadastro_Clientes ADD Telefone3 VarChar(20)

----------------- Valores Numeric -------------------
ALTER TABLE Cadastro_Clientes ADD Valor_Ultima_Compra Numeric(18,2)
ALTER TABLE Cadastro_Clientes ADD Valor_Medio_Compra Numeric(18,2)
ALTER TABLE Cadastro_Clientes ADD Salario Numeric(18,2)
ALTER TABLE Cadastro_Clientes ADD Percentual_Participacao_Empresa Numeric(8,4)
ALTER TABLE Cadastro_Clientes ADD Faturamento_Anual_Liquido Numeric(18,2)
ALTER TABLE Cadastro_Clientes ADD Faturamento_Anual_Bruto Numeric(18,2)
ALTER TABLE Cadastro_Clientes ADD Faturamento_Medio_Mensal Numeric(18,2)

ALTER TABLE Cadastro_Clientes ADD Numero_Funcionarios BigInt
ALTER TABLE Cadastro_Clientes ADD Ano_Fundacao BigInt
ALTER TABLE Cadastro_Clientes ADD Mes_Fundacao BigInt
ALTER TABLE Cadastro_Clientes ADD Profissao VarChar(80)
ALTER TABLE Cadastro_Clientes ADD Tipo_Residencia Char(80)
ALTER TABLE Cadastro_Clientes ADD Anos_Moradia BigInt
ALTER TABLE Cadastro_Clientes ADD Quantidade_Dependentes BigInt
GO

------------- Popular tabela --------------------
BEGIN TRAN
GO
INSERT INTO Cadastro_Clientes (Nome,
                               SobreNome,
                               DT_Cadastro,
                               DT_Alteracao,
                               DT_UltimaCompra,
                               DT_Fundacao,
                               DT_Nascimento,
                               DT_Obito,
                               DT_Aniversario,
                               DT_ExpedicaoRG,
                               Rua,
                               Bairro,
                               Cidade,
                               Estado,
                               Numero,
                               Telefone1,
                               Telefone2,
                               Telefone3,
                               Valor_Ultima_Compra,
                               Valor_Medio_Compra,
                               Salario,
                               Percentual_Participacao_Empresa,
                               Faturamento_Anual_Liquido,
                               Faturamento_Anual_Bruto,
                               Faturamento_Medio_Mensal,
                               Numero_Funcionarios,
                               Ano_Fundacao,
                               Mes_Fundacao,
                               Profissao,
                               Tipo_Residencia,
                               Anos_Moradia,
                               Quantidade_Dependentes)
  VALUES(Convert(VarChar(80),NEWID()), -- Nome - nchar(80)
         Convert(VarChar(80),NEWID()), -- SobreNome - nvarchar(80)
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_Cadastro - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_Alteracao - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_UltimaCompra - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_Fundacao - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_Nascimento - datetime
         NULL, -- DT_Obito - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_Aniversario - datetime
         GetDate() - ABS(Checksum(NEWID())) / 100000, -- DT_ExpedicaoRG - datetime
         Convert(VarChar(80),NEWID()), -- Rua - varchar(80)
         Convert(VarChar(80),NEWID()), -- Bairro - varchar(80)
         Convert(VarChar(80),NEWID()), -- Cidade - varchar(80)
         Convert(VarChar(80),NEWID()), -- Estado - varchar(80)
         ABS(Checksum(NEWID())) / 10000000.0, -- Numero - int
         '14-8888-1111', -- Telefone1 - varchar(20)
         NULL, -- Telefone2 - varchar(20)
         NULL, -- Telefone3 - varchar(20)
         0, -- Valor_Ultima_Compra - numeric
         ABS(Checksum(NEWID())) / 100000.0, -- Valor_Medio_Compra - numeric
         NULL, -- Salario - numeric
         ABS(Checksum(NEWID())) / 1000000.0, -- Percentual_Participacao_Empresa - numeric
         ABS(Checksum(NEWID())) / 100000.0, -- Faturamento_Anual_Liquido - numeric
         NULL, -- Faturamento_Anual_Bruto - numeric
         NULL, -- Faturamento_Medio_Mensal - numeric
         5, -- Numero_Funcionarios - bigint
         2009, -- Ano_Fundacao - bigint
         1, -- Mes_Fundacao - bigint
         NULL, -- Profissao - varchar(80)
         'Alugada', -- Tipo_Residencia - char(80)
         0, -- Anos_Moradia - bigint
         NULL)  -- Quantidade_Dependentes - bigint
GO 10000

UPDATE Cadastro_Clientes SET Valor_Ultima_Compra = 0
WHERE ID < 80000

COMMIT TRAN
GO
ALTER TABLE Cadastro_Clientes ADD CONSTRAINT XPK_Cadastro_Clientes
                                  PRIMARY KEY CLUSTERED(CPF_CNPJ, RG, Empresa) WITH FILLFACTOR = 80
GO

-- Qtas páginas? Como reduzir o número de páginas lidas?
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
SET STATISTICS IO ON
SELECT COUNT(*)
  FROM Cadastro_Clientes
SET STATISTICS IO OFF
GO

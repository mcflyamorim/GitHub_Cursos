/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

SET NOCOUNT ON;
GO
USE Master
GO
-- Caso exista um banco chamado DB_Lipo, apaga ele.
IF (SELECT DB_ID('DB_Lipo')) IS NOT NULL
BEGIN
  USE Master
  ALTER DATABASE DB_Lipo SET SINGLE_USER WITH ROLLBACK IMMEDIATE
  DROP DATABASE DB_Lipo
END
GO

-- Cria o banco de dados DB_Lipo
IF (SELECT DB_ID('DB_Lipo')) IS NULL
BEGIN
  CREATE DATABASE DB_Lipo
END
GO

USE DB_Lipo
GO

-- Criar uma tabela chamada Cadastro_Clientes
-- que será utilizada nos testes
IF OBJECT_ID('Cadastro_Clientes') IS NOT NULL
BEGIN
  DROP TABLE Cadastro_Clientes
END
GO
CREATE TABLE Cadastro_Clientes (ID       BigInt IDENTITY(1,1),
                                CPF_CNPJ Char(14) DEFAULT CONVERT(Char(14), CONVERT(VarChar(200),NEWID())) NOT NULL,
                                RG       VarChar(20) DEFAULT CONVERT(VarChar(20), CONVERT(VarChar(200),NEWID())) NOT NULL,
                                Empresa  BigInt CONSTRAINT df_Empresa DEFAULT (ABS(Checksum(NEWID())) / 10000000.0) NOT NULL)
GO

ALTER TABLE Cadastro_Clientes ADD Nome NChar(80)
/* 160 bytes */

ALTER TABLE Cadastro_Clientes ADD SobreNome NVarChar(80)
/* De 2 a 160 bytes */

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

ALTER TABLE Cadastro_Clientes ADD [*] Tinyint
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
GO 100000

UPDATE Cadastro_Clientes SET Valor_Ultima_Compra = 0
WHERE ID < 80000

COMMIT TRAN
GO
ALTER TABLE Cadastro_Clientes DROP CONSTRAINT df_Empresa
GO

-------------------------- Índices --------------------------
ALTER TABLE Cadastro_Clientes ADD CONSTRAINT XPK_Cadastro_Clientes
                                  PRIMARY KEY NONCLUSTERED(CPF_CNPJ, RG, Empresa) WITH FILLFACTOR = 30
CREATE CLUSTERED INDEX ix0 ON Cadastro_Clientes (Ano_Fundacao, Mes_Fundacao, Tipo_Residencia) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix1 ON Cadastro_Clientes (Nome, SobreNome, ID) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix2 ON Cadastro_Clientes (Nome) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix3 ON Cadastro_Clientes (SobreNome) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix4 ON Cadastro_Clientes (ID) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix5 ON Cadastro_Clientes (Ano_Fundacao) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix6 ON Cadastro_Clientes (Ano_Fundacao) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix7 ON Cadastro_Clientes (Faturamento_Anual_Liquido) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix9 ON Cadastro_Clientes (DT_UltimaCompra) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix10 ON Cadastro_Clientes (Nome, SobreNome) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix11 ON Cadastro_Clientes (Nome, SobreNome) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix12 ON Cadastro_Clientes (Nome, SobreNome, ID) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix13 ON Cadastro_Clientes (Tipo_Residencia) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix14 ON Cadastro_Clientes (DT_Cadastro) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix15 ON Cadastro_Clientes (DT_Cadastro) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix16 ON Cadastro_Clientes (RG) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix17 ON Cadastro_Clientes (Empresa, Nome, SobreNome, CPF_CNPJ, RG, Bairro, Cidade, Estado) WITH FILLFACTOR = 30;
CREATE NONCLUSTERED INDEX ix18 ON Cadastro_Clientes (Salario) WITH FILLFACTOR = 30;
GO

-- Tamanho da tabela
sp_SpaceUsed Cadastro_Clientes, True
/*
name	             |rows	  |reserved	  |data	     |index_size	|unused
Cadastro_Clientes	|100000 |1446640 KB |200000 KB |124453 KB  |2104 KB
*/
 
/* Índice Cluster */
/* Índice Cluster não único (UNIQUIFIER)*/
/* Índices Repetidos */
/* Índices Não Utilizados */
/* Péssima escolha de Índice Cluster(Primary Key) */
/* FillFactor */
/* INCLUDE */
/* Sparse Columns */ -- All Versions
/* Filtered Index */ -- All Versions
/* DataTypes - DateTime para SmallDateTime */
/* DataTypes - SmallDateTime para Date */
/* DataTypes - BigInt para TinyInt, SmallInt, Int */
/* DataTypes - NVarChar, NChar para VarChar, Char */
/* DataTypes - Char para VarChar */
/* DataTypes - Storage format VarDecimal, SQL2005 SP2*/ -- Enterprise Only
/* Page e Row Compression */ -- Enterprise Only



-- Nunca usar select * nas suas consultas, exceção a consulta abaixo :-)
SELECT "*" FROM Cadastro_Clientes
GO

-- Maneira correta
SELECT ID,
       CPF_CNPJ,
       RG,
       Empresa,
       Nome,
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
       Quantidade_Dependentes
  FROM Cadastro_Clientes
GO

/* Índice Cluster, Índice Cluster não único (UNIQUIFIER), Péssima escolha de Índice Cluster(Primary Key) */
-- Recriar o índice cluster o menor possível e sem repetição --
-- Boas práticas, pequeno, estático, e único --
sp_SpaceUsed Cadastro_Clientes, True
GO
DROP INDEX Cadastro_Clientes.ix0
CREATE CLUSTERED INDEX ix0 ON Cadastro_Clientes (ID) WITH FILLFACTOR = 30;
GO
sp_SpaceUsed Cadastro_Clientes, True
GO

/* Índices Repetidos */
-- Remover todos índices repetidos --

DROP ALL DUPLICATED INDEX FROM DB_Lipo
GO

-- A consulta abaixo ajuda a localizar os índices duplicados, mas não é 100% --
WITH CTE_index_list AS 
(
  SELECT tbl.[name] AS TableName,
	        idx.[name] AS IndexName,
	        INDEXPROPERTY( tbl.[id], idx.[name], 'IsClustered') AS IsClustered,
	        INDEX_COL( tbl.[name], idx.indid, 1 ) AS col1,
	        INDEX_COL( tbl.[name], idx.indid, 2 ) AS col2,
	        INDEX_COL( tbl.[name], idx.indid, 3 ) AS col3,
	        INDEX_COL( tbl.[name], idx.indid, 4 ) AS col4,
	        INDEX_COL( tbl.[name], idx.indid, 5 ) AS col5,
	        INDEX_COL( tbl.[name], idx.indid, 6 ) AS col6,
	        INDEX_COL( tbl.[name], idx.indid, 7 ) AS col7
    FROM SYSINDEXES idx
   INNER JOIN SYSOBJECTS tbl ON idx.[id] = tbl.[id]
   WHERE indid > 0 
  	  AND INDEXPROPERTY( tbl.[id], idx.[name], 'IsStatistics') = 0
)
	
SELECT l1.tablename,
       l1.IsClustered,
	      l1.indexname, 
	      l2.indexname AS duplicateIndex, 
	      l1.col1, 
	      l1.col2, 
	      l1.col3, 
	      l1.col4, 
	      l1.col5, 
	      l1.col6, 
	      l1.col7
  FROM CTE_index_list l1 
 INNER JOIN CTE_index_list l2 ON l1.tablename = l2.tablename
  	AND l1.indexname <> l2.indexname
	  AND l1.col1 = l2.col1
	  AND COALESCE(l1.col2,'') = COALESCE(l2.col2,'')
	  AND COALESCE(l1.col3,'') = COALESCE(l2.col3,'')
	  AND COALESCE(l1.col4,'') = COALESCE(l2.col4,'')
	  AND COALESCE(l1.col5,'') = COALESCE(l2.col5,'')
	  AND COALESCE(l1.col6,'') = COALESCE(l2.col6,'')
	  AND COALESCE(l1.col7,'') = COALESCE(l2.col7,'')
 ORDER BY	l1.tablename,
	         l1.indexname
GO
sp_SpaceUsed Cadastro_Clientes, True
GO
DROP INDEX Cadastro_Clientes.ix15
DROP INDEX Cadastro_Clientes.ix14
DROP INDEX Cadastro_Clientes.ix12
DROP INDEX Cadastro_Clientes.ix11
DROP INDEX Cadastro_Clientes.ix10
DROP INDEX Cadastro_Clientes.ix4
DROP INDEX Cadastro_Clientes.ix5
DROP INDEX Cadastro_Clientes.ix6
GO
sp_SpaceUsed Cadastro_Clientes, True
GO

/* Índices Não Utilizados */
-- Analisar bem caso a caso, as DMVs podem ajudar, mas não confie nelas 100% --
SELECT object_schema_name(indexes.object_id) + '.' + object_name(indexes.object_id) as objectName,
       indexes.name, case when is_unique = 1 then 'UNIQUE ' else '' end + indexes.type_desc, 
       ddius.user_seeks, 
       ddius.user_scans, 
       ddius.user_lookups, 
       ddius.user_updates
  FROM sys.indexes
  LEFT OUTER JOIN sys.dm_db_index_usage_stats ddius
    ON indexes.object_id = ddius.object_id
   AND indexes.index_id = ddius.index_id
   AND ddius.database_id = db_id()
 WHERE sys.indexes.object_id = Object_ID('Cadastro_Clientes')
ORDER BY ddius.user_seeks + ddius.user_scans + ddius.user_lookups DESC

-- Somente as consultas que são executadas na base irão te responder --
sp_SpaceUsed Cadastro_Clientes, True
GO
DROP INDEX Cadastro_Clientes.ix13
GO
sp_SpaceUsed Cadastro_Clientes, True
GO

/* FillFactor */
-- Defina o fillfactor corretamente, fillfactor é igual ao espaço que será UTILIZADO, 
-- o resto será deixado para futuras atualizações na página --

sp_SpaceUsed Cadastro_Clientes, True
GO
ALTER INDEX ALL ON Cadastro_Clientes REBUILD WITH (FILLFACTOR = 80, PAD_INDEX = ON);
GO
sp_SpaceUsed Cadastro_Clientes, True
GO

/* INCLUDE */
-- Defina como chave do índice apenas as colunas que serão utilizadas como filtro --
sp_SpaceUsed Cadastro_Clientes, True
GO
DROP INDEX Cadastro_Clientes.ix17
CREATE NONCLUSTERED INDEX ix17 ON Cadastro_Clientes (Empresa) INCLUDE(Nome, SobreNome, CPF_CNPJ, RG, Bairro, Cidade, Estado) 
WITH (FILLFACTOR = 80, PAD_INDEX = ON);
GO
sp_SpaceUsed Cadastro_Clientes, True
GO

/* Sparse Columns */ -- All Versions
-- Colunas que contém muitos valores NULL ou Zero, definir como Sparse, --
-- isso faz com que o NULL/Zero não ocupe espaço nenhum --
DROP INDEX Cadastro_Clientes.ix8 -- Objetos que dependem das columnas que serão alteradas para SPASE tem que ser recriados.
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Obito ADD SPARSE
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN Telefone2 ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Telefone3 ADD SPARSE
DROP INDEX Cadastro_Clientes.ix18
ALTER TABLE Cadastro_Clientes ALTER COLUMN Salario ADD SPARSE
CREATE NONCLUSTERED INDEX ix18 ON Cadastro_Clientes (Salario) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN Faturamento_Anual_Bruto ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Faturamento_Medio_Mensal ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Profissao ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Quantidade_Dependentes ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Valor_Ultima_Compra ADD SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Anos_Moradia ADD SPARSE
GO
ALTER INDEX ALL ON Cadastro_Clientes REBUILD WITH (FILLFACTOR = 80, PAD_INDEX = ON, DATA_COMPRESSION = NONE);
GO

/* Filtered Index */ -- All Versions
sp_SpaceUsed Cadastro_Clientes, true
GO
DROP INDEX Cadastro_Clientes.ix8
DROP INDEX Cadastro_Clientes.ix18
CREATE NONCLUSTERED INDEX ix18 ON Cadastro_Clientes (Salario) 
 WHERE Salario IS NOT NULL
  WITH (FILLFACTOR = 80, PAD_INDEX = ON);
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito)
 WHERE DT_Obito IS NOT NULL
  WITH (FILLFACTOR = 80, PAD_INDEX = ON);
GO
sp_SpaceUsed Cadastro_Clientes, true
GO

/* Hash Index */

-- Consulta lenta, sem índice
SELECT * FROM Cadastro_Clientes WITH(index=0)
 WHERE Nome = '1D46EE72-2E12-456D-A8D2-1E38C2DDED73'
   AND SobreNome = '8EC6B173-2982-4D52-9B0E-2F2BABF97B31'
GO
   
CREATE INDEX ix_TesteSemHashNomeSobrenome ON Cadastro_Clientes(Nome, Sobrenome)
GO

SELECT * FROM Cadastro_Clientes WITH(index=ix_TesteSemHashNomeSobrenome)
 WHERE Nome = '1D46EE72-2E12-456D-A8D2-1E38C2DDED73'
   AND SobreNome = '8EC6B173-2982-4D52-9B0E-2F2BABF97B31'
GO

-- Vejamos o tamanho dos índices
SELECT Object_Name(p.Object_Id) As Tabela,
       I.Name As Indice, 
       Total_Pages,
       Total_Pages * 8 / 1024.00 As MB
  FROM sys.Partitions AS P
 INNER JOIN sys.Allocation_Units AS A 
    ON P.Hobt_Id = A.Container_Id
 INNER JOIN sys.Indexes AS I 
    ON P.object_id = I.object_id 
   AND P.index_id = I.index_id
 WHERE p.Object_Id = Object_Id('Cadastro_Clientes')
GO

-- ALTER TABLE Cadastro_Clientes DROP COLUMN Hash_Nome_SobreNome
ALTER TABLE Cadastro_Clientes ADD Hash_Nome_SobreNome AS BINARY_CHECKSUM(Nome, SobreNome)
GO
-- DROP INDEX ix_TesteComHashNomeSobrenome ON Cadastro_Clientes
CREATE INDEX ix_TesteComHashNomeSobrenome ON Cadastro_Clientes(Hash_Nome_SobreNome) 
GO

-- Cuidado pois o hash pode gerar colisões
SELECT Hash_Nome_SobreNome, Count(*)
  FROM Cadastro_Clientes
 GROUP BY Hash_Nome_SobreNome
HAVING Count(*) > 1
 ORDER BY 2 DESC
GO

SELECT * FROM Cadastro_Clientes WITH(index=ix_TesteComHashNomeSobrenome)
 WHERE Hash_Nome_SobreNome = BINARY_CHECKSUM('1D46EE72-2E12-456D-A8D2-1E38C2DDED73',
                                             '8EC6B173-2982-4D52-9B0E-2F2BABF97B31')
   AND Nome = '1D46EE72-2E12-456D-A8D2-1E38C2DDED73'
   AND SobreNome = '8EC6B173-2982-4D52-9B0E-2F2BABF97B31'
GO

-- Vejamos o tamanho dos índices
SELECT Object_Name(p.Object_Id) As Tabela,
       I.Name As Indice, 
       Total_Pages,
       Total_Pages * 8 / 1024.00 As MB
  FROM sys.Partitions AS P
 INNER JOIN sys.Allocation_Units AS A 
    ON P.Hobt_Id = A.Container_Id
 INNER JOIN sys.Indexes AS I 
    ON P.object_id = I.object_id 
   AND P.index_id = I.index_id
 WHERE p.Object_Id = Object_Id('Cadastro_Clientes')
GO


/* DataTypes - DateTime para SmallDateTime */
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Cadastro SmallDateTime
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Alteracao SmallDateTime
DROP INDEX Cadastro_Clientes.ix9
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_UltimaCompra SmallDateTime
CREATE NONCLUSTERED INDEX ix9 ON Cadastro_Clientes (DT_UltimaCompra) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Fundacao SmallDateTime
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Nascimento SmallDateTime
DROP INDEX Cadastro_Clientes.ix8
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Obito SmallDateTime
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Aniversario SmallDateTime
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_ExpedicaoRG SmallDateTime
GO

/* DataTypes - SmallDateTime para Date */
GO
DROP INDEX Cadastro_Clientes.ix9
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_UltimaCompra Date
CREATE NONCLUSTERED INDEX ix9 ON Cadastro_Clientes (DT_UltimaCompra) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Fundacao Date
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Nascimento Date
DROP INDEX Cadastro_Clientes.ix8
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Obito Date
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Aniversario Date
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_ExpedicaoRG Date
GO

/* DataTypes - BigInt para TinyInt, SmallInt, Int */
ALTER TABLE Cadastro_Clientes DROP CONSTRAINT XPK_Cadastro_Clientes
DROP INDEX Cadastro_Clientes.ix17
ALTER TABLE Cadastro_Clientes ALTER COLUMN Empresa TinyInt NOT NULL
ALTER TABLE Cadastro_Clientes ADD CONSTRAINT XPK_Cadastro_Clientes
PRIMARY KEY NONCLUSTERED(CPF_CNPJ, RG, Empresa)
WITH (FILLFACTOR = 80, PAD_INDEX = ON);
CREATE NONCLUSTERED INDEX ix17 ON Cadastro_Clientes (Empresa) INCLUDE(Nome, SobreNome, CPF_CNPJ, RG, Bairro, Cidade, Estado) 
WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN Empresa TinyInt NOT NULL
ALTER TABLE Cadastro_Clientes ALTER COLUMN Numero SmallInt
ALTER TABLE Cadastro_Clientes ALTER COLUMN Numero_Funcionarios SmallInt
ALTER TABLE Cadastro_Clientes ALTER COLUMN Ano_Fundacao SmallInt
ALTER TABLE Cadastro_Clientes ALTER COLUMN Mes_Fundacao TinyInt
ALTER TABLE Cadastro_Clientes ALTER COLUMN Anos_Moradia TinyInt
ALTER TABLE Cadastro_Clientes ALTER COLUMN Quantidade_Dependentes TinyInt
GO

/* DataTypes - NVarChar, NChar para VarChar, Char */
DROP INDEX Cadastro_Clientes.ix1
DROP INDEX Cadastro_Clientes.ix2
DROP INDEX Cadastro_Clientes.ix3
DROP INDEX Cadastro_Clientes.ix17
ALTER TABLE Cadastro_Clientes ALTER COLUMN SobreNome VarChar(80)
ALTER TABLE Cadastro_Clientes ALTER COLUMN Nome VarChar(80)
CREATE NONCLUSTERED INDEX ix1 ON Cadastro_Clientes (Nome, SobreNome, ID) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
CREATE NONCLUSTERED INDEX ix2 ON Cadastro_Clientes (Nome) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
CREATE NONCLUSTERED INDEX ix3 ON Cadastro_Clientes (SobreNome) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
CREATE NONCLUSTERED INDEX ix17 ON Cadastro_Clientes (Empresa) INCLUDE(Nome, SobreNome, CPF_CNPJ, RG, Bairro, Cidade, Estado) 
WITH (FILLFACTOR = 80, PAD_INDEX = ON);
GO

/* DataTypes - Char para VarChar */
ALTER TABLE Cadastro_Clientes ALTER COLUMN Tipo_Residencia VarChar(80)
GO
sp_SpaceUsed Cadastro_Clientes, true
GO
ALTER INDEX ALL ON Cadastro_Clientes REBUILD WITH (DATA_COMPRESSION = NONE)
GO
sp_SpaceUsed Cadastro_Clientes, true
GO

/* DataTypes - Storage format VarDecimal, SQL2005 SP2*/ -- Enterprise Only
sp_SpaceUsed Cadastro_Clientes, true
GO
EXEC sp_db_vardecimal_storage_format 'DB_Lipo', 'ON';
GO
EXEC sp_tableoption 'Cadastro_Clientes', 
   'vardecimal storage format', 'ON';
GO
sp_SpaceUsed Cadastro_Clientes, true
GO

/* Page e Row Compression */ -- Enterprise Only
sp_SpaceUsed Cadastro_Clientes, true
GO
DROP INDEX Cadastro_Clientes.ix8 -- Objetos que dependem das columnas que serão alteradas para SPASE tem que ser recriados.
ALTER TABLE Cadastro_Clientes ALTER COLUMN DT_Obito DROP SPARSE
CREATE NONCLUSTERED INDEX ix8 ON Cadastro_Clientes (DT_Obito) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN Telefone2 DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Telefone3 DROP SPARSE
DROP INDEX Cadastro_Clientes.ix18
ALTER TABLE Cadastro_Clientes ALTER COLUMN Salario DROP SPARSE
CREATE NONCLUSTERED INDEX ix18 ON Cadastro_Clientes (Salario) WITH (FILLFACTOR = 80, PAD_INDEX = ON);
ALTER TABLE Cadastro_Clientes ALTER COLUMN Faturamento_Anual_Bruto DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Faturamento_Medio_Mensal DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Profissao DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Quantidade_Dependentes DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Valor_Ultima_Compra DROP SPARSE
ALTER TABLE Cadastro_Clientes ALTER COLUMN Anos_Moradia DROP SPARSE
GO
EXEC sp_tableoption 'Cadastro_Clientes', 
   'vardecimal storage format', 'OFF';
GO
EXEC sp_estimate_data_compression_savings 'dbo', 'Cadastro_Clientes', 1, NULL, 'ROW';
GO
EXEC sp_estimate_data_compression_savings 'dbo', 'Cadastro_Clientes', 1, NULL, 'PAGE';
GO
ALTER INDEX ALL ON Cadastro_Clientes REBUILD WITH (DATA_COMPRESSION = PAGE)
GO
sp_SpaceUsed Cadastro_Clientes, true
GO

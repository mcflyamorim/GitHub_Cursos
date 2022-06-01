USE NorthWind
GO

IF OBJECT_ID('Test') IS NOT NULL
  DROP TABLE Test
GO

-- Cria uma tabela de Test com uma chave composta colunas ID Int, PassaportNumber Char(11) Primary Key
CREATE TABLE Test (ID               Int Identity(1,1), 
                   PassaportNumber Char(11),
                   FirstName       VarChar(200),
                   LastName        VarChar(200),
                   Address         VarChar(200),
                   Neighborhood    VarChar(200),
                   City            VarChar(200),
                   PRIMARY KEY(ID, PassaportNumber, FirstName))
GO

IF OBJECT_ID('TestIdentity') IS NOT NULL
  DROP TABLE TestIdentity
GO
-- Cria uma tabela de Test com uma coluna ID Identity e Primary Key
CREATE TABLE TestIdentity (ID              Int Identity(1,1) PRIMARY KEY, 
                           PassaportNumber Char(11),
                           FirstName       VarChar(200),
                           LastName        VarChar(200),
                           Address         VarChar(200),
                           Neighborhood    VarChar(200),
                           City            VarChar(200))
GO

SET NOCOUNT ON
BEGIN TRANSACTION
GO
INSERT INTO Test(PassaportNumber, FirstName, LastName, Address, Neighborhood, City) 
            VALUES('11111111111', NEWID(), 'Neves Amorim', NEWID(), NEWID(), NEWID())
GO 10000
COMMIT
GO

INSERT INTO TestIdentity(PassaportNumber, FirstName, LastName, Address, Neighborhood, City)
SELECT PassaportNumber, FirstName, LastName, Address, Neighborhood, City
  FROM Test
GO

ALTER INDEX ALL ON Test REBUILD
ALTER INDEX ALL ON TestIdentity REBUILD
GO

CREATE NONCLUSTERED INDEX ix_FirstNameLastName ON Test(FirstName, LastName)
CREATE NONCLUSTERED INDEX ix_LastName          ON Test(LastName)
CREATE NONCLUSTERED INDEX ix_Address           ON Test(Address)
GO

CREATE NONCLUSTERED INDEX ix_FirstNameLastName ON TestIdentity(FirstName, LastName)
CREATE NONCLUSTERED INDEX ix_LastName          ON TestIdentity(LastName)
CREATE NONCLUSTERED INDEX ix_Address           ON TestIdentity(Address)
GO


/* ESTÁTICOS */

-- Agora vamos ver quantas leituras de páginas são necessárias para atualizar 
-- 2000 linhas das tabelas, Vamos ligar as estatiscitas de IO para ver o resultado
-- se você exibir o Plano de execução repare que o update na tabela Test
-- irá atualizar os indices non-cluster da tabela.
SET STATISTICS IO ON

update Test set FirstName = 'Fabio'
where ID < 2000
/*
Table 'Test'. Scan count 1, logical reads 54132
Table 'Worktable'. Scan count 1, logical reads 4102
*/
GO
update TestIdentity set FirstName = 'Fabio'
where ID < 2000
/*
Table 'TestIdentity'. Scan count 1, logical reads 14377
*/
SET STATISTICS IO OFF

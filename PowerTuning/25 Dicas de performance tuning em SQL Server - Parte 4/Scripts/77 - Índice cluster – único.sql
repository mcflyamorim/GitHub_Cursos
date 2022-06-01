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

SET NOCOUNT ON
BEGIN TRAN
GO
-- Inserir 10000 mil linhas
INSERT INTO Test(PassaportNumber, FirstName, LastName, Address, Neighborhood, City) 
            VALUES('11111111111', NEWID(), 'Neves Amorim', NEWID(), NEWID(), NEWID())
GO 10000
COMMIT
GO

ALTER INDEX ALL ON Test REBUILD
GO

-- Índices noncluster...
CREATE NONCLUSTERED INDEX ix_FirstNameLastName ON Test(FirstName, LastName)
CREATE NONCLUSTERED INDEX ix_LastName          ON Test(LastName)
CREATE NONCLUSTERED INDEX ix_Address           ON Test(Address)
GO


/* UNICO */

--*******************************************************************--
------********* Pergunta........... IDENTITY é único???????????????????
--*******************************************************************--


/*
  Para vizualizar a funcionalidade de incluir mais um valor de 4 bytes 
  nos registros duplicados afim
  de torná-los únicos vamos alterar a primary key da tabela Test.
*/

-- Consultando o nome da primary key
exec sp_pkeys Test
GO


-- Apaga a primary key para recria-la como não cluster.
ALTER TABLE Test DROP CONSTRAINT PK__Test__10BB4E4C926DFDB4

-- Recria a primary key como não cluster
ALTER TABLE Test ADD CONSTRAINT PK__Test PRIMARY KEY NONCLUSTERED(ID, PassaportNumber, FirstName)

-- Cria um indice cluster com base na coluna PassaportNumber
CREATE CLUSTERED INDEX ix_PassaportNumber ON Test(PassaportNumber)

/*
  Para vizualizar o valor que o SQL incluiu em cada valor duplicado vamos utilizar o comando
  DBCC PAGE
*/
-- Pega o endereço físico do Nivel raiz do indice coluna Root da tabela SysIndexes
SELECT dbo.fn_HexaToDBCCPAGE(Root)
  FROM SysIndexes
 WHERE ID = Object_id('Test') 
   AND Name = 'ix_PassaportNumber'

DBCC TRACEON(3604)
GO
DBCC PAGE (Northwind,1,243200,3)

/*  Resultado
FileId	|PageId	|Row	|Level	|ChildFileId	|ChildPageId	|PassaportNumber (key)	  |UNIQUIFIER (key)	|KeyHashValue
1	     |2738	  |0	  |2	    |1	          |2736	       |NULL	       |NULL	            |(1d0151a9cf2f)
1	     |2738	  |1	  |2	    |1	          |2737	       |11111111111	|11894	           |(930152642c7b)
1	     |2738	  |2	  |2	    |1	          |2739	       |11111111111	|23454	           |(bd0117b642ad)
1	     |2738	  |3	  |2	    |1	          |2740	       |11111111111	|35014	           |(e601bd2493e9)
1	     |2738	  |4	  |2	    |1	          |2741	       |11111111111	|46574	           |(0f021bded106)
*/

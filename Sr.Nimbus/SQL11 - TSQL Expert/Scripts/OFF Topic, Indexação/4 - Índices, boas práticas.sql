/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

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
-- Inclui 50000 mil de linhas nas tabelas
INSERT INTO Test(PassaportNumber, FirstName, LastName, Address, Neighborhood, City) 
            VALUES('11111111111', NEWID(), 'Neves Amorim', NEWID(), NEWID(), NEWID())
GO 50000

INSERT INTO TestIdentity(PassaportNumber, FirstName, LastName, Address, Neighborhood, City)
SELECT PassaportNumber, FirstName, LastName, Address, Neighborhood, City
  FROM Test
GO

ALTER INDEX ALL ON Test REBUILD
ALTER INDEX ALL ON TestIdentity REBUILD

GO
-- Vamos criar alguns indices nonclustered para cada tabela
CREATE NONCLUSTERED INDEX ix_FirstNameLastName ON Test(FirstName, LastName)
CREATE NONCLUSTERED INDEX ix_LastName          ON Test(LastName)
CREATE NONCLUSTERED INDEX ix_Address           ON Test(Address)
GO

CREATE NONCLUSTERED INDEX ix_FirstNameLastName ON TestIdentity(FirstName, LastName)
CREATE NONCLUSTERED INDEX ix_LastName          ON TestIdentity(LastName)
CREATE NONCLUSTERED INDEX ix_Address           ON TestIdentity(Address)
GO

/* PEQUENO */

-- Ao comparar o tamanho das tabelas já podemos observar que a tabela Test 
-- é maior que a tabela TestIdentity justamente por causa do index_size.
sp_spaceUsed Test
GO
sp_spaceUsed TestIdentity

-- A tabela Test é maior porque nos indices non-cluster é incluido os dados do indice cluster
-- para comprovar isso podemos utilizar o comando abaixo. 
-- Repare que é exibida a informação das colunas Address, ID, PassaportNumber e FirstName
DBCC SHOW_STATISTICS('Test', ix_Address)

/* ESTÁTICOS */

-- Agora vamos ver quantas leituras de páginas são necessárias para atualizar 
-- 2000 linhas das tabelas, Vamos ligar as estatiscitas de IO para ver o resultado
-- se você exibir o Plano de execução repare que o update na tabela Test
-- irá atualizar os indices non-cluster da tabela.
SET STATISTICS IO ON

update Test set FirstName = 'Fabio'
where ID < 2000
/*
Table 'Test'. Scan count 1, logical reads 55793, physical reads 0, read-ahead reads 15, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 4, logical reads 12552, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/
GO
update TestIdentity set FirstName = 'Fabio'
where ID < 2000
/*
Table 'TestIdentity'. Scan count 1, logical reads 14497, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
*/
SET STATISTICS IO OFF


/* UNICO */

--*******************************************************************--
------********* Pergunta........... IDENTITY é único???????????????????
--*******************************************************************--


/*
  Para vizualizar a funcionalidade de incluir mais um valor de 4 bytes 
  nos registros duplicados afim
  de torná-los únicos vamos alterar a primary key da tabela Test.
*/

-- Pega o FirstName da primary key
exec sp_pkeys Test

-- Apaga a primary key para recria-la como não cluster.
ALTER TABLE Test DROP CONSTRAINT PK__Test__10BB4E4C1CBC4616
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
DBCC PAGE (Northwind,1,12802,3)

/*  Resultado
FileId	|PageId	|Row	|Level	|ChildFileId	|ChildPageId	|PassaportNumber (key)	  |UNIQUIFIER (key)	|KeyHashValue
1	     |2738	  |0	  |2	    |1	          |2736	       |NULL	       |NULL	            |(1d0151a9cf2f)
1	     |2738	  |1	  |2	    |1	          |2737	       |11111111111	|11894	           |(930152642c7b)
1	     |2738	  |2	  |2	    |1	          |2739	       |11111111111	|23454	           |(bd0117b642ad)
1	     |2738	  |3	  |2	    |1	          |2740	       |11111111111	|35014	           |(e601bd2493e9)
1	     |2738	  |4	  |2	    |1	          |2741	       |11111111111	|46574	           |(0f021bded106)
*/

-- Podemos ver que foi gerada uma coluna "UNIQUIFIER (key)", Bunito esse FirstName né? Uniquifier :-)

-- Sequencial --
/*
  Nota: Evitar page splits
  
  Page splits Não só causam fragmentação, mas geram muito mais LOG
  
*/

IF OBJECT_ID('BigTable') IS NOT NULL
  DROP TABLE BigTable
GO
CREATE TABLE BigTable (Col1 Integer, 
                        Col2 Char(1100));
GO
CREATE CLUSTERED INDEX Cluster_BigTable_Col1 ON BigTable(Col1);
GO

INSERT INTO BigTable VALUES (1, 'a');
INSERT INTO BigTable VALUES (2, 'a');
INSERT INTO BigTable VALUES (3, 'a');
INSERT INTO BigTable VALUES (4, 'a');
INSERT INTO BigTable VALUES (6, 'a');
INSERT INTO BigTable VALUES (7, 'a');
GO

/* 
  Visualiznado quantas páginas de dados foram alocadas 
  para a tabela.
  Apenas uma página de dados foi alocada
*/
DBCC IND (NorthWind, BigTable, 1)
GO

/*
  Quanto espaço livre tem na página?
  Olhar a m_freeCnt no cabeçalho da página.
  
  m_freeCnt = 1418
*/
DBCC TRACEON (3604)
DBCC PAGE (NorthWind, 1,37298,3)
/*
  Só temos mais 1418 bytes livres na página, ou seja
  só cabe mais uma linha.
*/

/*
  Força o CheckPoint
  Como o banco esta em recovery model simple
  limpamos o LOG, para poder analisar com a ::fn_dblog
*/ 
CHECKPOINT
GO

/*
  Quando espaço um simples INSERT ocupa no Log
  de transações?
*/
BEGIN TRAN

-- Inserir um registro sequencial
INSERT INTO BigTable VALUES (8, 'a');
GO

-- Consulta a quantidade de logs utilizados
SELECT database_transaction_log_bytes_used
  FROM sys.dm_tran_database_transactions
 WHERE database_id = DB_ID('NorthWind');
GO

-- Consulta quais eventos foram gerados no Log
SELECT * FROM ::fn_dblog(null, null)

COMMIT TRAN
GO

/*
  Quando espaço um PageSplit ocupa no Log
  de transações?
*/
BEGIN TRAN
-- Inserir o registro 5 que esta faltando na tabela
-- para manter a ordem dos dados, o SQL precisa fazer o 
-- Split
INSERT INTO BigTable VALUES (5, 'a');
GO

-- Consulta a quantidade de logs utilizados
SELECT database_transaction_log_bytes_used
  FROM sys.dm_tran_database_transactions
 WHERE database_id = DB_ID('NorthWind');
GO

-- Consulta quais eventos foram gerados no Log
SELECT * FROM ::fn_dblog(null, null)

COMMIT TRAN
GO

/*
  PageSplit gerou praticamente 6 vezes mais log que um simples insert
*/
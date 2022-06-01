USE NorthWind
GO

-- Sequencial --
/*
  Nota: Evitar page splits
  
  Page splits não só causam fragmentação, mas geram muito mais LOG
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
  
  m_freeCnt = 1334
*/
DBCC TRACEON (3604)
DBCC PAGE (NorthWind, 1, 251600, 3)
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
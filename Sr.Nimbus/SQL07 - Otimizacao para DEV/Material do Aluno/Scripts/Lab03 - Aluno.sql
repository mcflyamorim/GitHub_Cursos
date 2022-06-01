/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07	
	Laboratório 03 (Versão aluno)
	
**************************************************************************************************/
/*
	Questão 01
*/
-- 1.1) Setup
-- Utilize o script abaixo para criar a tabela T1 no banco de dados Tempdb.
USE tempdb
GO

IF OBJECT_ID('dbo.T1') IS NOT NULL
  DROP TABLE dbo.T1

CREATE TABLE dbo.T1
(
  keycol INT         NOT NULL PRIMARY KEY,
  col1   INT         NOT NULL,
  col2   VARCHAR(50) NOT NULL
)

INSERT INTO dbo.T1(keycol, col1, col2) VALUES(1, 101, 'A')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(2, 102, 'B')
INSERT INTO dbo.T1(keycol, col1, col2) VALUES(3, 103, 'C')

CREATE INDEX idx_col1 ON dbo.T1(col1)
GO

-- 1.2) Fim do setup

-- Em conexões distintas, execute os batches abaixo.
-- Conexão 01
USE tempdb
GO
WHILE 1 = 1
  UPDATE dbo.T1 SET col1 = 203 - col1 WHERE keycol = 2
GO

-- Conexão 02
USE tempdb
GO
DECLARE @i AS VARCHAR(10)
WHILE 1 = 1
  SET @i = (SELECT col2 FROM dbo.T1 WITH (index = idx_col1)
            WHERE col1 = 102)
GO


/*
	Exercício 02
*/


/*
	Exercício 03
*/
USE AdventureWorks2008
go

-- (1)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail  
-- ANALISE OS BLOQUEIOS....
ROLLBACK


-- (2)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail
WHERE ProductID = 710
-- ANALISE OS BLOQUEIOS....
ROLLBACK


-- (3)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail  WITH (HOLDLOCK, XLOCK)
-- ANALISE OS BLOQUEIOS....
ROLLBACK


-- (4)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail  WITH (HOLDLOCK, XLOCK)
WHERE SalesOrderID BETWEEN 72400 AND 75000
-- ANALISE OS BLOQUEIOS....
ROLLBACK


-- (5)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail  WITH (HOLDLOCK, PAGLOCK, XLOCK)
WHERE SalesOrderID BETWEEN 72400 AND 75000
-- ANALISE OS BLOQUEIOS....
ROLLBACK


-- (6)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
SELECT * 
FROM Sales.SalesOrderDetail  WITH (HOLDLOCK, XLOCK)
WHERE SalesOrderID BETWEEN 72500 AND 75000
-- ANALISE OS BLOQUEIOS....
ROLLBACK

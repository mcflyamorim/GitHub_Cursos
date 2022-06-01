/*
	Seletividade
*/
USE SQL07
go

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa')
	DROP TABLE Pessoa
go

CREATE TABLE Pessoa
(Codigo BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 Nome CHAR(100) NOT NULL,
 Idade tinyint NULL,
 Codigo2 INT NULL)
go

INSERT INTO Pessoa (Nome, Idade)
SELECT F.Fname + ' ' + L.LName, 0
FROM tempdb.dbo.FirstName AS F
CROSS JOIN tempdb.dbo.LastName AS L
go

UPDATE Pessoa
	SET Codigo2 = Codigo
GO

SELECT * 
FROM Pessoa
WHERE Codigo2 < 200
go

CREATE NONCLUSTERED INDEX idxNCL_Pessoa_Codigo2
ON Pessoa (Codigo2)

SELECT * 
FROM Pessoa
WHERE Codigo2 < 200
go

SELECT * 
FROM Pessoa
WHERE Codigo2 < 300
go


/*
	Cover index e manipulação de dados...
*/
USE SQL07
GO

select Codigo, Nome from Pessoa
where Nome = 'Luciano Moreira'
GO

-- Por curiosidade...
CREATE NONCLUSTERED INDEX idx_teste
ON PESSOA (Nome, Codigo)
go

-- Existe motivo para criar esse índice dessa forma?
-- R: Código é o índice cluster
-- Duplica o dado?

select Codigo, Nome, IDADE from Pessoa
where Nome LIKE 'Lucian%'

CREATE NONCLUSTERED INDEX idx_CoverRuim
ON Pessoa (Nome)
INCLUDE (Idade)

SET STATISTICS IO ON

select Codigo, Nome, IDADE from Pessoa
where Nome LIKE 'Lucian%'

select Codigo, Nome, IDADE 
from Pessoa WITH(INDEX(1))
where Nome LIKE 'Lucian%'


SELECT * FROM sys.sysindexes
WHERE ID = OBJECT_ID('Pessoa')
go

DBCC IND (Inside, Pessoa, 3)

DBCC TRACEON(3604)
DBCC PAGE(5, 1, 2226, 3)


/*
	FILTERED INDEXES DEMO
*/

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa')
	DROP TABLE Pessoa
go

/*
	Temos índice cluster aqui...
*/
CREATE TABLE Pessoa
(Codigo BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 Nome CHAR(100) NOT NULL,
 Idade TINYINT NULL)
go

INSERT INTO Pessoa (Nome, Idade)
SELECT F.Fname + ' ' + L.LName, 0
FROM FirstName AS F
CROSS JOIN LastName AS L
GO

DECLARE @i INT
SET @i = 1

WHILE (@i <= 60346)
BEGIN
	UPDATE Pessoa 
	SET Idade = (CASE WHEN @i % 100 < 10 THEN @i % 100 ELSE NULL END)
	WHERE Codigo = @i

	SET @i = @i + 1
END

select top 1000 * from Pessoa

SELECT AU.* 
FROM SYS.Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')

CREATE NONCLUSTERED INDEX idx_Idade
ON Pessoa (Idade)
go

SELECT AU.* 
FROM SYS.Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

SELECT AU.* 
FROM SYS.system_internals_Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

-- Navegando pela estrutura...
DBCC TRACEON(3604)
DBCC PAGE(5, 1, 1016, 3)

DBCC IND (Inside, Pessoa, 2)

DBCC PAGE(5, 1, 775, 3)

-- P: Quando esse índice seria utilizado?
SELECT * FROM Pessoa
WHERE Idade = 9
go

SELECT Codigo, Idade FROM Pessoa
WHERE Idade = 9

SET STATISTICS IO ON

DROP INDEX Pessoa.Idx_Idade
GO

--CREATE NONCLUSTERED INDEX idx_Idade
--ON Pessoa (Idade)
--INCLUDE (Nome)
--WHERE Idade IS NOT NULL
--go

CREATE NONCLUSTERED INDEX idx_Idade
ON Pessoa (Idade)
WHERE Idade IS NOT NULL
go

SELECT AU.* 
FROM SYS.Allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
GO

SELECT Codigo, Idade FROM Pessoa
WHERE Idade = 9


select COUNT(idade)
from Pessoa

select COUNT(idade)
from Pessoa
where Idade is not null


-- Boa diferença, não é?

/*
	Outros exemplos...
*/

-- COVER INDEX É EXCELENTE!
use AdventureWorks2008
go

sp_help 'sALES.SALESORDERHEADER'


DROP INDEX Sales.SalesOrderHeader.Idx_Teste
create nonclustered index idx_teste
ON Sales.SalesOrderHeader(SalesOrderNumber, RevisionNumber, OrderDate, DueDate, ShipDate, Status,
PurchaseOrderNumber, AccountNumber)


SELECT object_name(P.object_id), index_id, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Sales.SalesOrderHeader')
go

-- Fim da ação goiaba




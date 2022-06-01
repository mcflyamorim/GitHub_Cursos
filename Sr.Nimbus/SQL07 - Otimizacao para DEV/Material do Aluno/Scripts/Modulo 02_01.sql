/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07 - Módulo 02
	
**************************************************************************************************/

/*
	Index internals...
	Mostra como navegar pela estrutura de índices utilizando o DBCC PAGE
	
	Autor: Luciano Caixeta Moreira
*/

USE Master
go

USE SQL07
go

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'Pessoa')
	DROP TABLE Pessoa
go

/*
	Temos índice cluster aqui...
*/
CREATE TABLE Pessoa
(Codigo BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 Nome CHAR(100) NOT NULL,
 Idade tinyint NULL)
go

INSERT INTO Pessoa (Nome, Idade)
SELECT F.Fname + ' ' + L.LName, 0
FROM tempdb.dbo.FirstName AS F
CROSS JOIN tempdb.dbo.LastName AS L

SELECT TOP 300 * FROM Pessoa
go

SELECT * FROM sys.indexes
WHERE Object_ID = object_id('Pessoa')

SELECT AU.* 
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

/*
	Quais são os valores para first_page, root_page e first_iam_page?

	0xD90000000100	0x450C00000100	0xDA0000000100
*/

SELECT DB_ID()
-- Fazer um replace com "DBCC PAGE(18," por "DBCC PAGE(YY," onde YY = DB_ID atual

-- Vamos analisar a first page?
DBCC TRACEON(3604)
DBCC PAGE(18, 1, 217, 3)
go

SELECT * 
FROM Pessoa
ORDER BY Nome desc

/*
	Verifique para ver se os dados estão corretos.
	Lembre-se que o nível folha é uma lista duplamente encadeada
	
	Next page e prev page?
*/

/* Next */
DBCC PAGE(18, 1, 220, 3)
go

/* Previous */
DBCC PAGE(18, 1, 93, 3)
go


-- Vamos analisar a root page?
-- 0x7D0200000100 = 637

/* Previous */
DBCC PAGE(18, 1, 3141, 3)
go

set statistics io on

SELECT * FROM Pessoa
WHERE Codigo = 20000

-- Navegando pela estrutura para ver como o SQL Server faz
DBCC PAGE(18, 1, 3142, 3)
go

DBCC PAGE(18, 1, 2959, 3)
go

DBCC PAGE(18, 1, 471, 3)
go

/*
Parte 02 - CL + NCL
*/
dbcc dropcleanbuffers

select * from Pessoa
where Nome = 'Luciano Moreira'
GO

CREATE NONCLUSTERED INDEX idx_Nome
ON Pessoa (Nome)
go

SELECT * FROM sys.sysindexes
WHERE ID = object_id('Pessoa')

SELECT object_name(P.object_id), index_id, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('Pessoa')
go

/*
	Quais são os valores para first_page, root_page e first_iam_page?

	0x300E00000100	0x720E00000100	0xE90000000100
*/

SET STATISTICS IO ON

/*
	Vamos ver quantas leituras foram feitas?
	Mostrar também o plano de execução!
*/
-- dbcc dropcleanbuffers
select * from Pessoa
where Nome = 'Luciano Moreira'

/*
	Hhhhuummm, 6 leituras de páginas. Porque? Alguém arrisca?

	Vamos navegar a partir do nó raiz do índice não cluster e verificar o que o SQL Server está fazendo	
*/

DBCC PAGE(18, 1, 3698, 3)
go

DBCC PAGE(18, 1, 3761, 3)
go

DBCC PAGE(18, 1, 3909, 3)
go


/*
	P1: O que temos no nível folha do índice cluster?
	P2: O que o SQL Server precisa fazer?
*/



/*
	R1: Ponteiros para os dados! RID ou Cluster key.
	R2: Navegar pela outra estrutura para encontrar as colunas faltantes na consulta.
*/

DBCC PAGE(18, 1, 3141, 3)
go

DBCC PAGE(18, 1, 219, 3)
go

DBCC PAGE(18, 1, 2677, 3)
go

select Codigo, Nome from Pessoa
where Nome = 'Luciano Moreira'

USE Inside

-- Qual a diferença entre os planos abaixo? E Pq?
select Codigo, Nome, Idade from Pessoa
where Nome LIKE 'Luciano%'

select Codigo, Nome
from Pessoa
where Nome LIKE 'Luciano%'

select Codigo, Nome 
from Pessoa with(index(1))
where Nome LIKE 'Luciano%'
go

-- NON SARG
select Codigo, Nome, Idade from Pessoa
where left(Nome, 7) = 'Luciano'


-- PARA REGISTRO do 100%
select Codigo, Nome
from Pessoa

select Codigo, Nome 
from Pessoa with(index(1))
go

select Codigo, Nome, Idade 
from Pessoa
where Nome LIKE 'Lucian%'

select Codigo, Nome, Idade 
from Pessoa WITH(INDEX(3))
where Nome LIKE 'Lucian%'

select COUNT(*)
from dbo.Pessoa


select COUNT(Idade)
from dbo.Pessoa

SELECT CODIGO, NOME
FROM dbo.Pessoa
ORDER BY Codigo

SELECT CODIGO, NOME
FROM dbo.Pessoa with(index(3))
ORDER BY Codigo



/*
	E se estivermos trabalhando com uma heap?
*/

IF Exists (SELECT * FROM SYS.Tables WHERE [name] = 'PessoaHeap')
	DROP TABLE PessoaHeap
go

CREATE TABLE PessoaHeap
(Codigo BIGINT IDENTITY(1,1) NOT NULL,
 Nome CHAR(100) NOT NULL,
 Idade TINYINT NULL)
go

INSERT INTO PessoaHeap (Nome, Idade)
SELECT F.Fname + ' ' + L.LName, 0
FROM FirstName AS F
CROSS JOIN LastName AS L


CREATE NONCLUSTERED INDEX idx_Nome
ON PessoaHeap (Nome)
go

SELECT * FROM sys.indexes
WHERE Object_ID = object_id('PessoaHeap')

SELECT object_name(P.object_id), index_id, AU.*
FROM sys.system_internals_allocation_units AS AU
INNER JOIN SYS.Partitions AS P
ON AU.Container_id = P.Partition_id
WHERE Object_ID = object_id('PessoaHeap')
go

select * from PessoaHeap
where Nome in ('Luciano Moreira','Luciano Silva', 'Luciano Souza', 'Luciano Caixeta')

/*
0x680B00000100	0xEA0B00000100	0x210B00000100
*/
0x9A0B00000100
0100

DBCC PAGE(18, 1, 3050, 3)
go

DBCC PAGE(18, 1, 2985, 3)
go

DBCC PAGE(18, 1, 3133, 3)
go

DBCC PAGE(18, 1, 2636, 2)
go

0x	08340000	0100	2A00

/*
0xCC15000001002A00
Alguém chuta a tradução desse endereço?



0x	CC150000			0100		2A00
	Bookmark pointer	FileID		Slot #

*/

DBCC PAGE(8, 1, 2100, 1)
go

/*
	Note que a referência é para o slot # -> Lembrou da primeira demonstração?
*/

select * 
from sys.dm_db_index_usage_stats

select * from Pessoa
go 10

select * 
from sys.dm_db_index_usage_stats
where [object_id] = object_id('Pessoa')
go

select * 
from sys.dm_db_index_operational_stats(5, object_id('Pessoa'), 1, 1)
go

select *
from sys.dm_db_index_physical_stats(5, object_id('Pessoa'), 1, 1, 'DETAILED')

select Codigo, Nome
from Pessoa
where Nome = 'Luciano Moreira'

select * from Pessoa
where Nome in ('Luciano Moreira','Luciano Silva', 'Luciano Souza', 'Luciano Caixeta')

select Codigo, Nome from Pessoa
where Nome in ('Luciano Moreira','Luciano Silva', 'Luciano Souza', 'Luciano Caixeta')


-- Veremos daqui a pouco...
select 
	OBJECT_NAME(object_id),
	*
from sys.dm_db_index_usage_stats 
where object_id = object_id('Pessoa')
GO

SELECT TOP 10 *
FROM sys.dm_db_missing_index_group_stats
go

SELECT TOP 10 *
FROM sys.dm_db_missing_index_group_stats
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans)DESC
go

SELECT TOP 10 *
FROM sys.dm_db_missing_index_groups
go

SELECT TOP 10 *
FROM sys.dm_db_missing_index_details
go

SELECT migs.group_handle, mid.*
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle)
WHERE migs.group_handle = 2
go
/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07	
	Módulo 01
	
**************************************************************************************************/

USE master
go

IF (DB_ID('SQL07') IS NOT NULL)
	DROP DATABASE SQL07
go

CREATE DATABASE SQL07
  ON PRIMARY 
	(NAME = N'SQL07_Data01', 
	FILENAME = N'C:\Temp\SQL07_Data01.mdf',
	SIZE = 500MB,
	MAXSIZE = 10GB,
	FILEGROWTH = 100MB)	
  LOG ON 
  (NAME = N'SQL07_Log', 
	FILENAME = N'C:\Temp\SQL07_log.ldf',
	SIZE = 10MB,
	MAXSIZE = 300MB,
	FILEGROWTH = 100MB)	
go

/*
	Consultas e análise de planos
*/
USE Northwind
go

SET SHOWPLAN_TEXT ON
go

SELECT *
FROM Products AS P
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

SET SHOWPLAN_TEXT OFF
GO
SET SHOWPLAN_ALL ON
go

SELECT *
FROM Products AS P
INNER JOIN Categories AS C
ON C.CategoryID = P.CategoryID
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

SET SHOWPLAN_ALL OFF
go
SET STATISTICS PROFILE ON
go

SELECT *
FROM Products AS P
INNER JOIN Categories AS C
ON C.CategoryID = P.CategoryID
WHERE P.UnitPrice < 20
ORDER BY P.ProductName
GO

SET STATISTICS PROFILE OFF
go
SET STATISTICS XML ON
go

select * from products
select * from Suppliers
select * from [Order Details]

SELECT ProductName, p.UnitPrice, s.CompanyName, S.Country, OD.quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE P.CategoryID in (1,2,3) and p.Unitprice < 20
and S.Country = 'uk' and OD.Quantity < 30
GO

SET STATISTICS XML OFF
go

-- Display execution plan
SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE

Select ProductName, OD.UnitPrice, Quantity
from products as p INNER JOIN [order details] AS OD
ON P.UnitPrice = OD.UnitPrice
go

SET STATISTICS IO Off
SET STATISTICS TIME Off

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

SELECT * FROM dbo.Shippers
GO


--
--	SET Based vs. Procedural...
--
USE AdventureWorks2008
go

/*
	Cenario: Promoção para o melhor vendedor, usando multiplicadores de 
	acordo com o tipo do produto
*/

SELECT *
FROM Production.Product

SELECT ProductID, [Name], ProductNumber, LEFT(ProductNumber, '2') AS Iniciais
FROM Production.Product
-- Regra de bônus: (BK * 4, FR * 3, HL * 2)

SELECT * FROM Sales.SalesOrderDetail
SELECT * FROM Sales.SalesOrderHeader

DROP TABLE #VendasProduto
go

SET STATISTICS time on

/*
	Primeira solução - visão procedural...
*/
SELECT SalesOrderID, OrderQty, LEFT(ProductNumber, '2') AS Tipo
INTO #VendasProduto
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Production.Product AS P
ON SOD.ProductID = P.ProductID

-- SELECT * FROM #VENDASProduto

UPDATE #VendasProduto
SET OrderQty = OrderQty * 4
WHERE Tipo = 'BK'

UPDATE #VendasProduto
SET OrderQty = OrderQty * 3
WHERE Tipo = 'FR'

UPDATE #VendasProduto
SET OrderQty = OrderQty * 2
WHERE Tipo = 'HL'

SELECT TOP 1 SalesPersonID, SUM(OrderQty) AS Total
FROM #VendasProduto AS VP
INNER JOIN Sales.SalesOrderHeader AS SOH
ON VP.SalesOrderID = SOH.SalesOrderID
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID
ORDER BY Total DESC
-- Vendedor: 277 - 64235

DROP TABLE #VendasProduto

/*
	Segunda solução - set based, mas sem cálculo das diferenças...
*/
SELECT TOP 1 
	SalesPersonID, 
	SUM(OrderQty) AS Total
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Production.Product AS P
ON SOD.ProductID = P.ProductID
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SOD.SalesOrderID = SOH.SalesOrderID
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID
ORDER BY Total DESC

-- 276	27229				OOOPPPPSSSS

/*
	Terceira solução - Agora certinho...
*/
SELECT TOP 1 SalesPersonID, 
	SUM(OrderQty * 
	(CASE LEFT(ProductNumber, '2')
		WHEN 'BK' THEN 4
		WHEN 'FR' THEN 3
		WHEN 'HL' THEN 2
		ELSE 1
		END)
	) AS Total
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Production.Product AS P
ON SOD.ProductID = P.ProductID
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SOD.SalesOrderID = SOH.SalesOrderID
WHERE SalesPersonID IS NOT NULL
GROUP BY SalesPersonID
ORDER BY Total DESC

/*
	Listar os dois vendedores que mais venderam para cada "categoria" de produto
*/
USE AdventureWorks2008
go

IF EXISTS (SELECT [name] FROM Sys.Objects where [name] = 'vw_VendasPessoaCategoria')
	DROP VIEW dbo.vw_VendasPessoaCategoria
go

CREATE VIEW vw_VendasPessoaCategoria
AS
SELECT	
		LEFT(P.ProductNumber, 2) as PseudoCat,
		SalesPersonID,
		SUM (OrderQty) AS Total
	FROM Sales.SalesOrderDetail AS SOD
	INNER JOIN Production.Product AS P
	ON SOD.ProductID = P.ProductID
	INNER JOIN Sales.SalesOrderHeader AS SOH
	ON SOD.SalesOrderID = SOH.SalesOrderID
	WHERE SalesPersonID IS NOT NULL
	GROUP BY LEFT(P.ProductNumber, 2), SalesPersonID
go

select * from vw_VendasPessoaCategoria

SELECT *
FROM 	
	(SELECT
		*,
		RANK() OVER (PARTITION BY V.PseudoCat order by V.Total DESC) AS Ranking
	FROM vw_VendasPessoaCategoria AS V) AS T1
WHERE T1.Ranking <= 2
GO

SELECT	
	LEFT(P.ProductNumber, 2) as PseudoCat,
	SalesPersonID,
	SUM (OrderQty) AS Total
into #TabelaTemporaria
FROM Sales.SalesOrderDetail AS SOD
INNER JOIN Production.Product AS P
ON SOD.ProductID = P.ProductID
INNER JOIN Sales.SalesOrderHeader AS SOH
ON SOD.SalesOrderID = SOH.SalesOrderID
WHERE SalesPersonID IS NOT NULL
GROUP BY LEFT(P.ProductNumber, 2), SalesPersonID
GO

SELECT *
FROM 	
	(SELECT
		*,
		RANK() OVER (PARTITION BY V.PseudoCat order by V.Total DESC) AS Ranking
	FROM #TabelaTemporaria AS V) AS T1
WHERE T1.Ranking <= 2
GO

WITH Consulta1 AS  
(
SELECT	
		LEFT(P.ProductNumber, 2) as PseudoCat,
		SalesPersonID,
		SUM (OrderQty) AS Total
	FROM Sales.SalesOrderDetail AS SOD
	INNER JOIN Production.Product AS P
	ON SOD.ProductID = P.ProductID
	INNER JOIN Sales.SalesOrderHeader AS SOH
	ON SOD.SalesOrderID = SOH.SalesOrderID
	WHERE SalesPersonID IS NOT NULL
	GROUP BY LEFT(P.ProductNumber, 2), SalesPersonID
)
SELECT *
FROM 	
	(SELECT
		*,
		RANK() OVER (PARTITION BY V.PseudoCat order by V.Total DESC) AS Ranking
	FROM Consulta1 AS V) AS T1
WHERE T1.Ranking <= 2


SET STATISTICS TIME OFF
/*
	Demonstração 01
	Modelagem de auto-incremento com trigger
*/
USE SQL07
go

IF OBJECT_ID('ControleID') IS NOT NULL
	DROP TABLE ControleID
go

CREATE TABLE ControleID
(NomeTabela VARCHAR(100) NOT NULL UNIQUE,
 Identificador BIGINT NOT NULL)
GO

INSERT INTO ControleID VALUES ('TabelaID', 0)
go

IF OBJECT_ID('TabelaIdentity') IS NOT NULL
	DROP TABLE TabelaIdentity
go	

CREATE TABLE TabelaIdentity
(Codigo BIGINT IDENTITY(1,1) NOT NULL,
 Filler VARCHAR(8000) NOT NULL)
go

IF OBJECT_ID('TabelaID') IS NOT NULL
	DROP TABLE TabelaID
go	

CREATE TABLE TabelaID
(Codigo BIGINT NOT NULL,
 Filler VARCHAR(8000) NOT NULL)
go

IF OBJECT_ID('trg_InsertID') IS NOT NULL
	DROP TRIGGER trg_InsertID
go	

CREATE TRIGGER trg_InsertID ON TabelaID
INSTEAD OF INSERT
AS
	DECLARE @proximo BIGINT
	
	SELECT @proximo = count(*) FROM INSERTED
	IF (@proximo > 1)
	BEGIN	
		print 'mais de um'
		ROLLBACK
	END
	
	SELECT @proximo = Identificador + 1 FROM ControleID WITH (ROWLOCK, XLOCK, HOLDLOCK)
		WHERE NomeTabela = 'TabelaID' 
	
	UPDATE ControleID
		SET Identificador = @proximo
	WHERE NomeTabela = 'TabelaID'
	
	INSERT INTO TabelaID (Codigo, Filler) 
	SELECT @proximo, Filler
	FROM INSERTED
go


INSERT INTO TabelaID (Filler) VALUES ('SQL07 - Teste de desempenho')
INSERT INTO TabelaIdentity (Filler) VALUES ('SQL07 - Teste de desempenho')
go

SELECT * FROM TabelaID
SELECT * FROM TabelaIdentity
go

SET STATISTICS IO Off
SET STATISTICS TIME Off

INSERT INTO TabelaID (Filler) VALUES ('SQL07 - Teste de desempenho')
go 100000

INSERT INTO TabelaIdentity (Filler) VALUES ('SQL07 - Teste de desempenho')
go 100000


/*
	Trabalhando com o Identity
	IDENTITY
*/

IF (OBJECT_ID('Funcionario') IS NOT NULL)
	DROP TABLE Funcionario
go

CREATE TABLE Funcionario
(
	Codigo INT IDENTITY(1000, 10) NOT NULL,
	Nome VARCHAR(200) NOT NULL,
	CNPJ CHAR(14) NULL
)
go

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Ronaldo Fenômeno', NULL)
GO
INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Nilmar', '000.000.000-00')
GO

SELECT * 
FROM Funcionario
go

IF (OBJECT_ID('Funcionario') IS NOT NULL)
	DROP TABLE Funcionario
go

CREATE TABLE Funcionario
(
	Codigo INT IDENTITY(1000, -1) NOT NULL,
	Nome VARCHAR(200) NOT NULL,
	CNPJ CHAR(14) NULL
)
go

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Ronaldo Fenômeno', NULL)
GO
INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Nilmar', '000.000.000-00')
GO

SELECT * 
FROM Funcionario
go

SELECT IDENT_CURRENT('Funcionario')
SELECT IDENT_SEED('Funcionario')
SELECT IDENT_INCR('Funcionario')


SET IDENTITY_INSERT dbo.Funcionario ON

INSERT INTO Funcionario (Codigo, Nome, CNPJ) VALUES (300, 'Dodô', null)
GO

SELECT * 
FROM Funcionario
go

SELECT IDENT_CURRENT('Funcionario')
SELECT IDENT_SEED('Funcionario')
SELECT IDENT_INCR('Funcionario')

SELECT * 
FROM Funcionario
go

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Lúcio', null)
GO

SET IDENTITY_INSERT dbo.Funcionario OFF

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Lúcio', null)
GO

SELECT * 
FROM Funcionario
go

TRUNCATE TABLE Funcionario
go

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Lúcio', null)
GO

SELECT * 
FROM Funcionario
go

-- Mudar o seed atual?
DBCC CHECKIDENT('Funcionario', RESEED, 501)
go

INSERT INTO Funcionario (Nome, CNPJ) VALUES ('Romário', null)
GO

SELECT * 
FROM Funcionario
go

-- Somente verifica o valor
DBCC CHECKIDENT ('Funcionario', NORESEED)


/*
	Cuidando com a modelagem...
*/

IF (OBJECT_ID('TabelaGrande') IS NOT NULL)
	DROP TABLE TabelaGrande
go

CREATE TABLE TabelaGrande
(
	Codigo INT IDENTITY(1, 1) NOT NULL,
	Nome CHAR(200) NOT NULL,
	Descricao CHAR(800) NULL,
	Numero01 BIGINT NULL DEFAULT(1),	
	Numero02 DECIMAL(38, 2) DEFAULT(1)
)
go

INSERT INTO TabelaGrande (Nome, Descricao) VALUES ('SQL07', 'Recursos de otimização para o desenvolvedor')
go 1000

select * from TabelaGrande
go

SELECT * 
FROM SYS.sysindexes
WHERE id = OBJECT_ID('TabelaGrande')

SELECT DB_ID()

-- 0x6E0000000100 = 110

DBCC TRACEON(3604)
DBCC PAGE(18, 1, 190,2)
GO

-- 7 registros por página!
SET STATISTICS IO ON

SELECT * FROM TabelaGrande
go


IF (OBJECT_ID('TabelaGrande2') IS NOT NULL)
	DROP TABLE TabelaGrande2
go

CREATE TABLE TabelaGrande2
(
	Codigo INT IDENTITY(1, 1) NOT NULL,
	Nome NCHAR(200) NOT NULL,
	Descricao NCHAR(800) NULL,
	Numero01 BIGINT NULL DEFAULT(1),	
	Numero02 DECIMAL(38, 2) DEFAULT(1)
)
go

INSERT INTO TabelaGrande2 (Nome, Descricao) VALUES ('SQL07', 'Recursos de otimização para o desenvolvedor')
go 1000

SELECT * 
FROM SYS.sysindexes
WHERE id = OBJECT_ID('TabelaGrande2')

SELECT DB_ID()

-- 0xAE0000000100 = 174

DBCC TRACEON(3604)
DBCC PAGE(18, 1, 174,2)
GO

-- Quantos registros por página?
SET STATISTICS IO ON


IF (OBJECT_ID('TabelaGrande3') IS NOT NULL)
	DROP TABLE TabelaGrande3
go

CREATE TABLE TabelaGrande3
(
	Codigo INT IDENTITY(1, 1) NOT NULL,
	Nome NVARCHAR(200) NOT NULL,
	Descricao NVARCHAR(800) NULL,
	Numero01 BIGINT NULL DEFAULT(1),	
	Numero02 DECIMAL(38, 2) DEFAULT(1)
)
go

INSERT INTO TabelaGrande3 (Nome, Descricao) VALUES ('SQL07', 'Recursos de otimização para o desenvolvedor')
go 1000


SET STATISTICS IO ON

SELECT * FROM TabelaGrande3
go



/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07	
	Laboratório 02 (Versão aluno)
	
**************************************************************************************************/

/*
	Questão 01
*/
USE tempdb
go

IF OBJECT_ID('Vendas') IS NOT NULL
	DROP TABLE Vendas
go

IF OBJECT_ID('DetalhesVenda') IS NOT NULL
	DROP TABLE DetalhesVenda
go

SELECT *
INTO dbo.Vendas
FROM Northwind.dbo.Orders
go

SELECT *
INTO dbo.DetalhesVenda
FROM Northwind.dbo.[Order Details]
go

ALTER TABLE dbo.DetalhesVenda
ADD Codigo INT IDENTITY(1,1) PRIMARY KEY
GO

SELECT * FROM dbo.Vendas
SELECT * FROM dbo.DetalhesVenda
go


-- Consulta 01
SELECT TOP 100 * FROM dbo.Vendas ORDER BY OrderDate DESC
-- Consulta 02
SELECT * FROM dbo.Vendas WHERE OrderID = 11074
-- Consulta 03
SELECT * FROM dbo.DetalhesVenda WHERE OrderID = 11074
go


/*
	Questão 02
*/
USE Northwind
go

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO


/*
	Questão 03
*/

-- 3.1) Início do setup
USE tempdb
go

--	Cria a tabela SaldoConta com chave primária e um índice não clusterizado
if exists(select [name] from sysobjects where xtype = 'U' and [name] = 'SaldoConta')
	DROP TABLE SaldoConta
go

CREATE TABLE SaldoConta (
CodigoCliente INT NOT NULL,
DataSaldo DATETIME NOT NULL,
SaldoAtual MONEY NOT NULL,
NomeBanco CHAR(100) NOT NULL,
OutraInformacao CHAR(100) NULL
)
go

ALTER TABLE SaldoConta
ADD CONSTRAINT PK_SaldoConta
PRIMARY KEY (CodigoCliente, DataSaldo)
go

CREATE NONCLUSTERED INDEX idx_DataSaldo
ON SaldoConta (DataSaldo)
go

--	Insere 10.000 clientes com diferentes saldos diferentes.
DECLARE @Cont INT
SET @Cont = 0

WHILE @Cont < 10000
BEGIN

	INSERT INTO SaldoConta VALUES (@Cont, '20070131', ((RAND() * 1000) * DATEPART(ss, GETDATE())), 'Qualquer um', 'SQL Server 2008')
	SET @Cont = @Cont + 1
END
go

-- 3.1) Fim do setup

-- Se fizermos a consulta neste momento, teremos aproximadamente 288 leitura de páginas
SET STATISTICS IO ON

SELECT * FROM dbo.SaldoConta
-- Table 'SaldoConta'. Scan count 1, logical reads 288, ...


-- Durante a noite, o dinheio em conta rende um valor variável...
DECLARE @SaldoAtual MONEY
DECLARE @Cont INT
SET @Cont = 0

WHILE @Cont < 10000
BEGIN

	SELECT @SaldoAtual = SaldoAtual FROM SaldoConta WHERE CodigoCliente = @Cont
	-- Esse meu banco é massa, o dinheiro somente aumenta nas contas...
	INSERT INTO SaldoConta VALUES (@Cont, '20070201', @SaldoAtual + ((RAND() * 10) * DATEPART(ss, GETDATE())), 'BANCO DO LUTI', 'Keep walking')
	SET @Cont = @Cont + 1
END
go


-- Se dobrou o número de registros, esperamos que sejam feitas aproximadamente 288 * 2 = 576 leituras de páginas.
SELECT * FROM dbo.SaldoConta

-- Porém o resultado foi: Table 'SaldoConta'. Scan count 1, logical reads 863
-- Qual o problema e como resolvê-lo?



/*
	Questão 04
*/
USE tempdb
go

IF OBJECT_ID('RegistroPessoal') IS NOT NULL
	DROP TABLE RegistroPessoal
GO

CREATE TABLE RegistroPessoal
(Identificador UNIQUEIDENTIFIER NOT NULL PRIMARY KEY DEFAULT(NEWID()),
 Nome VARCHAR(200) NOT NULL,
 Idade SMALLINT NOT NULL,
 CPF CHAR(11) NOT NULL,
 RG VARCHAR(50) NULL,
 DataEmissaoRG DATETIME NULL,
 Sexo CHAR(1) NOT NULL,
 DataNascimento DATETIME NULL 
 )
 
CREATE NONCLUSTERED INDEX idx_NCL_RegistroPessoal_Sexo
ON RegistroPessoal (Sexo)
go

CREATE NONCLUSTERED INDEX idx_NCL_RegistroPessoal_CoverIndex1
ON RegistroPessoal (Idade, CPF)
go

CREATE NONCLUSTERED INDEX idx_NCL_RegistroPessoal_CoverIndex2
ON RegistroPessoal (DataNascimento, CPF)
INCLUDE (Idade, RG, DataEmissaoRG, Nome, Sexo)
go

CREATE NONCLUSTERED INDEX idx_NCL_RegistroPessoal_Nome
ON RegistroPessoal (Nome)
go



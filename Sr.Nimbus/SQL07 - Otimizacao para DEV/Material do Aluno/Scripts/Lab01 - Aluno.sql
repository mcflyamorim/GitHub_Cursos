/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07	
	Laboratório 01 (Versão aluno)
	
**************************************************************************************************/

/*
	Setup do banco de dados
	Execute o script abaixo para preparar o banco de dados para os exercícios.
*/

-- 0.1) Início do setup
USE master
go

IF (DB_ID('SQL07') IS NOT NULL)
	DROP DATABASE SQL07
go

CREATE DATABASE SQL07
go

-- Cria as tabelas necessárias para o exercício
USE SQL07
GO

IF OBJECT_ID('dbo.Nums') IS NOT NULL
  DROP TABLE dbo.Nums
GO

CREATE TABLE dbo.Nums(n INT NOT NULL PRIMARY KEY)
DECLARE @max AS INT, @rc AS INT
SET @max = 1000000
SET @rc = 1

INSERT INTO Nums VALUES(1)
WHILE @rc * 2 <= @max
BEGIN
  INSERT INTO dbo.Nums SELECT n + @rc FROM dbo.Nums
  SET @rc = @rc * 2
END

INSERT INTO dbo.Nums 
  SELECT n + @rc FROM dbo.Nums WHERE n + @rc <= @max
GO

-- Drop Data Tables if Exist
IF OBJECT_ID('dbo.Orders') IS NOT NULL
  DROP TABLE dbo.Orders
GO
IF OBJECT_ID('dbo.Customers') IS NOT NULL
  DROP TABLE dbo.Customers
GO
IF OBJECT_ID('dbo.Employees') IS NOT NULL
  DROP TABLE dbo.Employees
GO
IF OBJECT_ID('dbo.Shippers') IS NOT NULL
  DROP TABLE dbo.Shippers
GO

-- Data Distribution Settings
DECLARE
  @numorders   AS INT,
  @numcusts    AS INT,
  @numemps     AS INT,
  @numshippers AS INT,
  @numyears    AS INT,
  @startdate   AS DATETIME

SELECT
  @numorders   =   1000000,
  @numcusts    =     20000,
  @numemps     =       500,
  @numshippers =         5,
  @numyears    =         4,
  @startdate   = '20030101'

-- Creating and Populating the Customers Table
CREATE TABLE dbo.Customers
(
  custid   CHAR(11)     NOT NULL,
  custname NVARCHAR(50) NOT NULL
)

INSERT INTO dbo.Customers(custid, custname)
  SELECT
    'C' + RIGHT('000000000' + CAST(n AS VARCHAR(10)), 10) AS custid,
    N'Cust_' + CAST(n AS VARCHAR(10)) AS custname
  FROM dbo.Nums
  WHERE n <= @numcusts

ALTER TABLE dbo.Customers ADD
  CONSTRAINT PK_Customers PRIMARY KEY(custid)

-- Creating and Populating the Employees Table
CREATE TABLE dbo.Employees
(
  empid     INT          NOT NULL,
  firstname NVARCHAR(25) NOT NULL,
  lastname  NVARCHAR(25) NOT NULL
)

INSERT INTO dbo.Employees(empid, firstname, lastname)
  SELECT n AS empid,
    N'Fname_' + CAST(n AS NVARCHAR(10)) AS firstname,
    N'Lname_' + CAST(n AS NVARCHAR(10)) AS lastname
  FROM dbo.Nums
  WHERE n <= @numemps

ALTER TABLE dbo.Employees ADD
  CONSTRAINT PK_Employees PRIMARY KEY(empid)

-- Creating and Populating the Shippers Table
CREATE TABLE dbo.Shippers
(
  shipperid   VARCHAR(5)   NOT NULL,
  shippername NVARCHAR(50) NOT NULL
)

INSERT INTO dbo.Shippers(shipperid, shippername)
  SELECT shipperid, N'Shipper_' + shipperid AS shippername
  FROM (SELECT CHAR(ASCII('A') - 2 + 2 * n) AS shipperid
        FROM dbo.Nums
        WHERE n <= @numshippers) AS D

ALTER TABLE dbo.Shippers ADD
  CONSTRAINT PK_Shippers PRIMARY KEY(shipperid)

-- Creating and Populating the Orders Table
CREATE TABLE dbo.Orders
(
  orderid   INT        NOT NULL,
  custid    CHAR(11)   NOT NULL,
  empid     INT        NOT NULL,
  shipperid VARCHAR(5) NOT NULL,
  orderdate DATETIME   NOT NULL,
  filler    CHAR(155)  NOT NULL DEFAULT('a')
)

INSERT INTO dbo.Orders(orderid, custid, empid, shipperid, orderdate)
  SELECT n AS orderid,
    'C' + RIGHT('000000000'
            + CAST(
                1 + ABS(CHECKSUM(NEWID())) % @numcusts
                AS VARCHAR(10)), 10) AS custid,
    1 + ABS(CHECKSUM(NEWID())) % @numemps AS empid,
    CHAR(ASCII('A') - 2
           + 2 * (1 + ABS(CHECKSUM(NEWID())) % @numshippers)) AS shipperid,
      DATEADD(day, n / (@numorders / (@numyears * 365.25)), @startdate)
        -- late arrival with earlier date
        - CASE WHEN n % 10 = 0
            THEN 1 + ABS(CHECKSUM(NEWID())) % 30
            ELSE 0 
          END AS orderdate
  FROM dbo.Nums
  WHERE n <= @numorders
  ORDER BY CHECKSUM(NEWID())

CREATE CLUSTERED INDEX idx_cl_od ON dbo.Orders(orderdate)

CREATE NONCLUSTERED INDEX idx_nc_sid_od_cid
  ON dbo.Orders(shipperid, orderdate, custid)

CREATE UNIQUE INDEX idx_unc_od_oid_i_cid_eid
  ON dbo.Orders(orderdate, orderid)
  INCLUDE(custid, empid)

ALTER TABLE dbo.Orders ADD
  CONSTRAINT PK_Orders PRIMARY KEY NONCLUSTERED(orderid),
  CONSTRAINT FK_Orders_Customers
    FOREIGN KEY(custid)    REFERENCES dbo.Customers(custid),
  CONSTRAINT FK_Orders_Employees
    FOREIGN KEY(empid)     REFERENCES dbo.Employees(empid),
  CONSTRAINT FK_Orders_Shippers
    FOREIGN KEY(shipperid) REFERENCES dbo.Shippers(shipperid)
GO

-- 0.2) Fim do setup


-- Verifica se os registros foram criados corretamente...
SELECT * FROM DBO.Customers		-- 20.000 registros
SELECT * FROM DBO.Employees		-- 500 registros
SELECT * FROM DBO.Orders		-- 1.000.000 registros
SELECT * FROM DBO.Shippers		-- 5 registros
go


/*
	Exercício 1
*/
-- 01.a
SET STATISTICS IO ON

SELECT * FROM dbo.Orders
go


-- 02.b
SELECT * FROM dbo.Orders ORDER BY orderdate
go

SELECT * FROM dbo.Orders ORDER BY orderid
go

EXEC sp_help 'dbo.Orders'


-- 02.C
SELECT TOP 100 * 
FROM dbo.Orders AS O
INNER JOIN dbo.Customers AS C
ON O.custid = C.custid
ORDER BY orderdate DESC
go


/*
	Exercício 2
*/

-- 2.1) Passos de setup do exercício...

-- Apaga os índices da tabela orders
DROP INDEX Orders.idx_nc_sid_od_cid
DROP INDEX Orders.idx_unc_od_oid_i_cid_eid

-- Cria novos índices...
CREATE NONCLUSTERED INDEX idx_nc_sid_od
  ON dbo.Orders(shipperid, orderdate);
GO

-- sp_help 'orders';

-- Insere alguns registros
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('B', 'Shipper_B');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('D', 'Shipper_D');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('F', 'Shipper_F');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('H', 'Shipper_H');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('X', 'Shipper_X');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('Y', 'Shipper_Y');
INSERT INTO dbo.Shippers(shipperid, shippername) VALUES('Z', 'Shipper_Z');

INSERT INTO dbo.Orders(orderid, custid, empid, shipperid, orderdate)
  VALUES(1000001, 'C0000000001', 1, 'B', '20000101');
INSERT INTO dbo.Orders(orderid, custid, empid, shipperid, orderdate)
  VALUES(1000002, 'C0000000001', 1, 'D', '20000101');
INSERT INTO dbo.Orders(orderid, custid, empid, shipperid, orderdate)
  VALUES(1000003, 'C0000000001', 1, 'F', '20000101');
INSERT INTO dbo.Orders(orderid, custid, empid, shipperid, orderdate)
  VALUES(1000004, 'C0000000001', 1, 'H', '20000101');
GO

-- 2.2) Fim do setup

-- Abordagem 1: Cursores...
DECLARE
  @sid     AS VARCHAR(5),
  @od      AS DATETIME,
  @prevsid AS VARCHAR(5),
  @prevod  AS DATETIME;

DECLARE ShipOrdersCursor CURSOR FAST_FORWARD FOR
  SELECT shipperid, orderdate
  FROM dbo.Orders
  ORDER BY shipperid, orderdate;

OPEN ShipOrdersCursor;

FETCH NEXT FROM ShipOrdersCursor INTO @sid, @od;

SELECT @prevsid = @sid, @prevod = @od;

WHILE @@fetch_status = 0
BEGIN
  IF @prevsid <> @sid AND @prevod < '20010101' PRINT @prevsid;
  SELECT @prevsid = @sid, @prevod = @od;
  FETCH NEXT FROM ShipOrdersCursor INTO @sid, @od;
END

IF @prevod < '20010101' PRINT @prevsid;

CLOSE ShipOrdersCursor;

DEALLOCATE ShipOrdersCursor;
go


-- De que outras formas você pode conseguir o mesmo resultado com 
-- uma abordagem set-based?
-- Tente mais de uma!



/*
	Exercício 3
*/

-- 3.1) Execute o script a partir daqui...
USE SQL07
go

IF OBJECT_ID('TabelaA') IS NOT NULL
	DROP TABLE TabelaA
go	

CREATE TABLE TabelaA
(Codigo INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
 Nome CHAR(1000) NOT NULL,
 Chave NUMERIC(17,0) NULL)
go

INSERT INTO TabelaA (Nome, Chave) VALUES ('Curso SQL07', RAND() * 1000000000000000)
go 100000
go

WITH Repetidos AS (
	SELECT Chave, MIN(Codigo) AS Codigo
	FROM dbo.TabelaA
	group by Chave 
	having COUNT(*) > 1
)
DELETE FROM dbo.TabelaA
FROM dbo.TabelaA AS A
INNER JOIN Repetidos AS R
ON A.Chave = R.Chave
	AND A.Codigo = R.Codigo
go 5

IF OBJECT_ID('TabelaB') IS NOT NULL
	DROP TABLE TabelaB
go	

CREATE TABLE TabelaB
(Chave VARCHAR(20) NOT NULL PRIMARY KEY,
 Descricao CHAR(1000) NOT NULL)
go

INSERT INTO TabelaB
SELECT Chave, NEWID() 
FROM dbo.TabelaA
go

-- Vamos criar um índice para nos ajudar...
CREATE UNIQUE NONCLUSTERED INDEX idx_TabelaA_Chave
ON TabelaA (Chave)
go

-- 3.2) Pare a execução do script aqui...

-- Execute a consulta abaixo e analize o plano de execução.
-- 3.3) Como podemos alterar a consulta ou a modelagem para uma resposta mais eficiente?
SELECT A.Chave, A.Nome, B.Descricao
FROM dbo.TabelaA AS A
INNER JOIN dbo.TabelaB AS B
ON A.Chave = B.Chave
GO


-- Dica: o Merge Join é um tipo de join utilizado pelo SQL Server que parte da premissa que 


/*
	Exercício 4
*/


/*
	Exercício 5
*/
/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO
----------------------------------------
---------- Tabelas temporárias ---------
----------------------------------------
----------------------------------------
-------- Variáveis do tipo table -------
----------------------------------------
IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Teste 1
-- Variáveis do tipo table não mantém estatísticas
DECLARE @Tab TABLE(OrderID  Int, 
                   ProductID Int, 
                   Quantity Int
                   PRIMARY KEY(OrderID, ProductID))
             
INSERT INTO @Tab(OrderID, ProductID, Quantity)
SELECT OrderID, ProductID, Quantity 
  FROM Order_DetailsBig

-- Qual é a estimativa de linhas a serem retornadas?
SELECT * FROM @Tab
WHERE Quantity = 100

-- E com option(recompile)?
-- Consegue estimar baseado na densidade...
SELECT * FROM @Tab
WHERE Quantity = 100
OPTION (RECOMPILE)

-- SQL2012SP2 ou SQL2014CU3 adicionaram TF 2453 que 
-- faz mesma coisa que o OPTION(RECOMPILE)
-- http://support.microsoft.com/kb/2952444

/*
Note this trace flag must be ON at runtime. You cannot use this trace flag with QUERYTRACEON. 
This trace flag must be used with caution because it can increase number of query recompiles which 
could cost more than savings from better query optimization.
*/


-- Teste com tabela temporária
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL 
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (OrderID  Int, 
                   ProductID Int, 
                   Quantity Int
                   PRIMARY KEY(OrderID, ProductID))
             
INSERT INTO #TMP(OrderID, ProductID, Quantity)
SELECT OrderID, ProductID, Quantity 
  FROM Order_DetailsBig

/*
  Estimativa correta 100 linhas
  AUTO_CREATE_STATISTICS cria a estatística durante 
  a criação do plano de execução
*/
SELECT * FROM #TMP
WHERE Quantity = 100
GO


-- Teste 2
-- Variável do tipo table pode gerar plano ruim até com 1 linha
USE Northwind
GO

-- Apagar todos os índices de OrdersBig
-- DROP INDEX OrdersBig.ixCustomerID
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO

-- Pode optar por um Scan em OrdersBig
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
DECLARE @Tab1 TABLE(ID Int, Col1 VarChar(500) DEFAULT NEWID())
INSERT INTO @Tab1(ID) VALUES(1)

SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 INNER JOIN @Tab1
    ON [@Tab1].ID = OrdersBig.CustomerID
SET STATISTICS IO OFF
GO

-- Seek + Lookup em OrdersBig
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
IF OBJECT_ID('tempdb.dbo.#Tab1') IS NOT NULL
  DROP TABLE #Tab1
GO
CREATE TABLE #Tab1 (ID Int, Col1 VarChar(500) DEFAULT NEWID())
INSERT INTO #Tab1(ID) VALUES(1)

SET STATISTICS IO ON
SELECT * 
  FROM OrdersBig
 INNER JOIN #Tab1
    ON [#Tab1].ID = OrdersBig.CustomerID
SET STATISTICS IO OFF
GO

-- Teste 3
-- Variáveis do tipo table geram menos log
DECLARE @TMP TABLE (ID Int)

BEGIN TRAN
INSERT INTO @TMP VALUES(1)
ROLLBACK TRAN

-- Retorna o que?
SELECT * FROM @TMP

-- O que foi gerado no log?

-- Consulta espaço utilizado no Log
-- Variável do tipo table 
DECLARE @TMP TABLE (ID Int)

BEGIN TRAN
DECLARE @i Int = 0
WHILE @i < 500000
BEGIN
  INSERT INTO @TMP VALUES(@i)
  SET @i += 1
END

SELECT SUM(database_transaction_log_bytes_used) / 1024. / 1024. MBsUsed
  FROM tempdb.sys.dm_tran_database_transactions
 WHERE database_id = DB_ID('tempdb');

ROLLBACK TRAN


-- Tabela temporária
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int)

BEGIN TRAN
DECLARE @i Int = 0
WHILE @i < 500000
BEGIN
  INSERT INTO #TMP VALUES(@i)
  SET @i += 1
END

SELECT SUM(database_transaction_log_bytes_used) / 1024. / 1024. MBsUsed
  FROM tempdb.sys.dm_tran_database_transactions
 WHERE database_id = DB_ID('tempdb');

ROLLBACK TRAN




-- Exemplos abaixo... Bônus...


-- Teste 4
-- Tabelas temporárias geram mais recompilação das procs
IF OBJECT_ID('st_TestRecompile') IS NOT NULL
  DROP PROC st_TestRecompile
GO
CREATE PROC st_TestRecompile @CustomerID Integer, @i Int
AS
BEGIN
  -- Preciso disso na proc?
  IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
    DROP TABLE #TMP

  CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY, OrderID Int, CustomerID Int)

  DECLARE @y Int = 0 --SQL2008
  DECLARE @temp Int

  WHILE @y < @i
  BEGIN
    INSERT INTO #TMP(OrderID, CustomerID)
    SELECT Orders.OrderID, Customers.CustomerID
      FROM Orders
     INNER JOIN Customers
        ON Orders.CustomerID = Customers.CustomerID
     WHERE Orders.CustomerID = @CustomerID

    -- Usando a #TMP para gerar o recompile
    -- para gerar o auto update statistics e causar o recompile...
    SELECT @temp = COUNT(*) 
      FROM #TMP a
     WHERE a.CustomerID = 999
    OPTION (QueryTraceOn 8757) -- desabilita trivial plan

    SET @y += 1;
  END

  SELECT * FROM #TMP
END
GO

-- Test Proc
-- Monitorar evento de recompile no profiler e contadores 
-- SQL Statistics: SQL Compilations/Sec e SQL Recompilations/Sec

-- Gera 3 recompile
EXEC st_TestRecompile @CustomerID = 1, @i = 190

-- Gera 5 recompile
EXEC st_TestRecompile @CustomerID = 1, @i = 600

-- Gera 7 recompile
EXEC st_TestRecompile @CustomerID = 1, @i = 1000

-- Gera varios recompile
-- Aprox. 20 segundos para rodar
EXEC st_TestRecompile @CustomerID = 1, @i = 10000
GO


-- Alterando para usar variável do tipo table
IF OBJECT_ID('st_TestRecompileVariveldoTipoTable') IS NOT NULL
  DROP PROC st_TestRecompileVariveldoTipoTable
GO
CREATE PROC st_TestRecompileVariveldoTipoTable @CustomerID Integer, @i Int
AS
BEGIN

  DECLARE @TMP TABLE  (ID Int IDENTITY(1,1) PRIMARY KEY, OrderID Int, CustomerID Int)

  DECLARE @y Int = 0 --SQL2008
  DECLARE @temp Int

  WHILE @y < @i
  BEGIN
    INSERT INTO @TMP
    SELECT Orders.OrderID, Customers.CustomerID
      FROM Orders
     INNER JOIN Customers
        ON Orders.CustomerID = Customers.CustomerID
     WHERE Orders.CustomerID = @CustomerID

    -- Usando a #TMP para gerar o recompile
    -- para gerar o auto update statistics e causar o recompile...
    SELECT @temp = COUNT(*) 
      FROM @TMP a
     WHERE a.CustomerID = 999
    OPTION (QueryTraceOn 8757) -- desabilita trivial plan

    SET @y += 1;
  END

  SELECT * FROM @TMP
END
GO

-- Não gera recompile
EXEC st_TestRecompileVariveldoTipoTable @CustomerID = 1, @i = 190

-- Não gera recompile
-- Aprox. 26 segundos para rodar
EXEC st_TestRecompileVariveldoTipoTable @CustomerID = 1, @i = 10000
GO

-- Teste 5
-- Definindo 2 índices..
DECLARE @TMP TABLE (ID Int PRIMARY KEY, Col1 Int UNIQUE)

-- Ver planos
SELECT * FROM @TMP
WHERE ID = 1
SELECT * FROM @TMP
WHERE Col1 = 1
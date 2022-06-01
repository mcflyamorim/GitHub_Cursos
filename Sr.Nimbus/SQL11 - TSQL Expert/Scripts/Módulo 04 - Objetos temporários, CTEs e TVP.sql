/*
  Sr.Nimbus - T-SQL Expert
         Módulo 04
  http://www.srnimbus.com.br
*/

USE Northwind
GO

----------------------------------------
------- Common Table Expressions -------
----------------------------------------

-- Teste 1
-- Quais os 3 países que mais geraram pedidos em 1997?
WITH VendasPorPais AS
(
	 SELECT ShipCountry, Ano = YEAR(OrderDate), PedidosNoAno = COUNT(*)
	   FROM Orders 
	  GROUP BY ShipCountry, YEAR(OrderDate)
)
SELECT TOP 3 * 
  FROM VendasPorPais
 WHERE Ano = 1997
 ORDER BY PedidosNoAno DESC


-- Teste 2
-- Evitando acesso a functions mais de uma vez com CTEs
IF OBJECT_ID('fn_QtdePedidosPorCliente') IS NOT NULL 
  DROP FUNCTION dbo.fn_QtdePedidosPorCliente
GO
CREATE FUNCTION dbo.fn_QtdePedidosPorCliente(@CustomerID Int) 
RETURNS Int
AS 
BEGIN 
  DECLARE @Total Int
  
  SELECT @Total = Count(OrdersBig.OrderID)
    FROM OrdersBig
   WHERE CustomerID = @CustomerID
  
  RETURN @Total 
END
GO
SELECT CASE 
         WHEN dbo.fn_QtdePedidosPorCliente(CustomerID) BETWEEN 40 AND 50 THEN 'A'
         WHEN dbo.fn_QtdePedidosPorCliente(CustomerID) BETWEEN 51 AND 60 THEN 'B'
         WHEN dbo.fn_QtdePedidosPorCliente(CustomerID) BETWEEN 61 AND 70 THEN 'C'
         WHEN dbo.fn_QtdePedidosPorCliente(CustomerID) BETWEEN 71 AND 80 THEN 'D'
         ELSE 'E'
       END AS Status,
       *
  FROM Customers
GO

WITH CTE_1
AS
(
  SELECT *,  dbo.fn_QtdePedidosPorCliente(CustomerID) AS fn_QtdePedidosPorCliente
    FROM Customers
)
SELECT CASE 
         WHEN fn_QtdePedidosPorCliente BETWEEN 40 AND 50 THEN 'A'
         WHEN fn_QtdePedidosPorCliente BETWEEN 51 AND 60 THEN 'B'
         WHEN fn_QtdePedidosPorCliente BETWEEN 61 AND 70 THEN 'C'
         WHEN fn_QtdePedidosPorCliente BETWEEN 71 AND 80 THEN 'D'
         ELSE 'E'
       END AS Status,
       *
  FROM CTE_1
GO

-- Teste 3
-- Recursividade
WITH Hierarquia AS
(
  -- 1º SELECT: âncora – início da recursão
  SELECT	EmployeeID, 
         CONVERT(VarChar(MAX), FirstName + ' ' + LastName) AS Nome, 
         NivelHierarquico = 1
	   FROM Employees
	  WHERE ReportsTo IS NULL	
   UNION ALL	
  -- 2º SELECT: recursivo – gera linhas a partir da linha âncora, e 
  -- depois gera linhas para cada linha gerada na execução anterior
  SELECT E.EmployeeID, 
         CONVERT(VarChar(MAX), REPLICATE('----', NivelHierarquico + 1) + FirstName + ' ' + LastName) AS Nome,
         NivelHierarquico + 1
    FROM Hierarquia H 
   INNER JOIN Employees E
      ON H.EmployeeID = E.ReportsTo
)
SELECT * FROM Hierarquia

-- Teste 4
-- Criando uma tabela de sequencial usando recursividade
WITH Sequencial AS
(
  SELECT 1 as ID
   UNION ALL
  SELECT ID + 1
    FROM Sequencial
   WHERE ID < 100
)
SELECT * 
  FROM Sequencial
--OPTION (MAXRECURSION 32767)


-- Exercício ROW VALUED CONSTRUCTORS...



----------------------------------------
---------- Tabelas temporárias ---------
----------------------------------------

----------------------------------------
-------- Variáveis do tipo table -------
----------------------------------------

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
GO

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
-- DROP INDEX ix_CustomerID ON OrdersBig
CREATE INDEX ix_CustomerID ON OrdersBig(CustomerID)
GO

-- Preparando demo, atualizando coluna CustomerID com poucos valores
-- distintos (densidade alta)
UPDATE OrdersBig SET CustomerID = ABS(CHECKSUM(NEWID())) / 100000000
GO

-- Scan em OrdersBig
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
DECLARE @Tab1 TABLE(ID Int, Col1 VarChar(500) DEFAULT NEWID())
INSERT INTO @Tab1(ID) VALUES(500)

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
INSERT INTO #Tab1(ID) VALUES(500)

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


----------------------------------------
-------- Tabled Valued Parameter -------
----------------------------------------

-- Teste 1

-- Criando novo TYPE
-- DROP TYPE OrderIDs
CREATE TYPE OrderIDs AS TABLE (ID INT NOT NULL PRIMARY KEY,
                               OrderID INT);
GO

-- Utilizado como variável
DECLARE @TVP AS OrderIDs;

INSERT INTO @TVP(ID, OrderID)
VALUES(1, 12345),(2, 123456),(3, 1234567);

SELECT * FROM @TVP;
GO

-- Table-valued parameters
IF OBJECT_ID('st_Inserir_Orders') IS NOT NULL
  DROP PROC st_Inserir_Orders;
GO
CREATE PROC dbo.st_Inserir_Orders(@TVP AS OrderIDs READONLY)
AS
BEGIN
  SELECT OrderID, CustomerID, OrderDate, Value
    FROM OrdersBig
   WHERE EXISTS(SELECT * 
                  FROM @TVP
                 WHERE [@TVP].OrderID = OrdersBig.OrderID)
END
GO
DECLARE @TVP AS OrderIDs;
INSERT INTO @TVP(ID, OrderID)
VALUES(1, 12345),(2, 123456),(3, 1234567);

EXEC dbo.st_Inserir_Orders @TVP = @TVP;
GO

-- Teste 2
-- TVP + Merge para manter tabela atualizada

-- Criando tabela para testes
IF OBJECT_ID('tmpProducts') IS NOT NULL
  DROP TABLE tmpProducts
GO
CREATE TABLE tmpProducts (ID   Int PRIMARY KEY,
                          Col1 VarChar(80));
GO
INSERT INTO tmpProducts (ID, Col1)
VALUES (1, 'Teste Valor 1'), (3, 'Teste Valor 3');
GO

SELECT * FROM tmpProducts
GO


-- DROP TYPE TVPtmpProducts
CREATE TYPE TVPtmpProducts AS TABLE (ID   Int PRIMARY KEY,
                                     Col1 VarChar(80))
GO


IF OBJECT_ID('st_TestTVPtmpProducts') IS NOT NULL
  DROP PROC st_TestTVPtmpProducts
GO
CREATE PROC st_TestTVPtmpProducts (@TVPtmpProducts AS TVPtmpProducts READONLY)
AS
BEGIN
   MERGE tmpProducts
   USING @TVPtmpProducts
      ON [@TVPtmpProducts].ID = [tmpProducts].ID
    WHEN MATCHED 
     AND [tmpProducts].Col1 <> [@TVPtmpProducts].Col1 THEN
  UPDATE SET [tmpProducts].Col1 = [@TVPtmpProducts].Col1
    WHEN NOT MATCHED BY TARGET THEN 
  INSERT VALUES ([@TVPtmpProducts].ID, [@TVPtmpProducts].Col1);

  SELECT * FROM tmpProducts
END
GO

DECLARE @TVPtmpProducts AS TVPtmpProducts
INSERT @TVPtmpProducts (ID, Col1)
VALUES (1, 'Teste Valor 1 Alterado'), -- Linha Já Existe  = Update
       (2, 'Teste Valor 2 Insert'),   -- Linha Não Existe = Insert
       (3, 'Teste Valor 3 Alterado'), -- Linha Já Existe  = Update
       (4, 'Teste Valor 4 Insert');   -- Linha Não Existe = Insert

EXEC st_TestTVPtmpProducts @TVPtmpProducts = @TVPtmpProducts
GO

-- Como simular isso no SQL Server 2005?
-- Prepare o coração ;-)
-- http://sqlblog.com/blogs/rob_farley/archive/2011/10/20/table-valued-parameters-in-sql-2005.aspx

-- Criando tabela para testes
IF OBJECT_ID('tmpProducts') IS NOT NULL
  DROP TABLE tmpProducts
GO
CREATE TABLE tmpProducts (ID   Int PRIMARY KEY,
                           Col1 VarChar(80));
GO
INSERT INTO tmpProducts (ID, Col1)
VALUES (1, 'Teste Valor 1'), (3, 'Teste Valor 3');
GO

SELECT * FROM tmpProducts
GO

-- Criar view que será utilizada para definição do "TYPE"
IF OBJECT_ID('vw_SimulaTVPtmpProducts') IS NOT NULL
  DROP VIEW vw_SimulaTVPtmpProducts
GO
CREATE VIEW vw_SimulaTVPtmpProducts
AS
SELECT CONVERT(Int, 0) AS ID,
       CONVERT(VarChar(80), '') AS Col1
 WHERE 1=0
GO

SELECT * FROM vw_SimulaTVPtmpProducts
GO

-- Ao invés de criar uma Proc, criamos uma INSTEAD OF TRIGGER para gerenciar o código
IF OBJECT_ID('tr_TestTVPtmpProducts') IS NOT NULL
  DROP TRIGGER tr_TestTVPtmpProducts
GO
CREATE TRIGGER tr_TestTVPtmpProducts 
ON vw_SimulaTVPtmpProducts INSTEAD OF INSERT
AS
BEGIN
   -- Para rodar no SQL2005 teriamos que remover o MERGE e usar 
   -- um comando para INSERT e outro para UPDATE
   MERGE tmpProducts
   USING Inserted
      ON Inserted.ID = tmpProducts.ID
    WHEN MATCHED 
     AND tmpProducts.Col1 <> Inserted.Col1 THEN
  UPDATE SET tmpProducts.Col1 = Inserted.Col1
    WHEN NOT MATCHED BY TARGET THEN 
  INSERT VALUES (Inserted.ID, Inserted.Col1);

  SELECT * FROM tmpProducts
END
GO

INSERT vw_SimulaTVPtmpProducts (ID, Col1)
VALUES (1, 'Teste Valor 1 Alterado'), -- Linha Já Existe  = Update
       (2, 'Teste Valor 2 Insert'),   -- Linha Não Existe = Insert
       (3, 'Teste Valor 3 Alterado'), -- Linha Já Existe  = Update
       (4, 'Teste Valor 4 Insert');   -- Linha Não Existe = Insert
GO
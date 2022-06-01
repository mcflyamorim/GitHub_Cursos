/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


-------------------------------
----------- Mitos -------------
-------------------------------

--COUNT(1) versus COUNT(*)
--O que é melhor? 
SELECT COUNT(1)
  FROM Products
GO
SELECT COUNT(*)
  FROM Products
GO
SELECT COUNT(ProductID) -- PK
  FROM Products
GO

--JOIN versus SubQuery
--O que é melhor? 
SELECT TOP 10 CustomersBig.ContactName, OrdersBig.OrderID
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
GO
SELECT TOP 10 CustomersBig.ContactName, Tab.OrderID
  FROM CustomersBig
 INNER JOIN (SELECT OrderID, CustomerID FROM OrdersBig) AS Tab
    ON CustomersBig.CustomerID = Tab.CustomerID
GO

--DISTINCT versus GROUP BY
--O que é melhor? 
SELECT Col1
  FROM ProductsBig
 GROUP BY Col1
GO
SELECT DISTINCT Col1
  FROM ProductsBig
 GROUP BY Col1
GO

--SET versus SELECT
--O que é melhor?
DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
  SET @V1 = ''
  SET @V2 = ''
  SET @V3 = ''
  SET @V4 = ''
  SET @V5 = ''
  SET @V6 = ''
  SET @V7 = ''
  SET @V8 = ''
  SET @V9 = ''
  SET @V10 = ''
 	SET @i = @i + 1                   
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

GO

DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
SELECT @V1 = '',
       @V2 = '',
       @V3 = '',
       @V4 = '',
       @V5 = '',
       @V6 = '',
       @V7 = '',
       @V8 = '',
       @V9 = '',
       @V10 = '',
       @i = @i + 1;
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

--TOP 1 ORDER BY DESC versus MAX
--Qual é melhor?
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(OrderDate)
GO
SELECT MAX(OrdersBig.OrderDate)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.CustomerID = 10
GO
SELECT TOP 1 OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.CustomerID = 10
 ORDER BY OrdersBig.OrderDate DESC
GO

--UNION versus UNION ALL
--O que é melhor? 

SELECT * FROM Orders
UNION ALL
SELECT * FROM Orders
GO

SELECT * FROM Orders
UNION
SELECT * FROM Orders
GO

------------------------------
----------- Tuning -----------
------------------------------

------------------------------------------------
-- Variáveis do mesmo tipo da coluna da tabela --
-------------------------------------------------

USE Northwind
GO
DROP INDEX ix_ProductName ON ProductsBig
CREATE INDEX ix_ProductName ON ProductsBig(ProductName)
GO

DECLARE @Nome NVarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO

DECLARE @Nome VarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO


----------------------------------
-- Cuidado com case + subquries --
----------------------------------
SELECT TOP 10000
       ContactName,
       CASE (SELECT SUM(Value) FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID)
         WHEN 1 THEN 'Cliente Grande'
         WHEN 2 THEN 'Cliente Médio'
         WHEN 3 THEN 'Cliente Pequeno'
         ELSE 'Nennum'
       END AS Status_Cliente
  FROM CustomersBig
GO

SELECT TOP 10000
       ContactName,
       (SELECT CASE SUM(Value) 
                 WHEN 1 THEN 'Cliente Grande'
                 WHEN 2 THEN 'Cliente Médio'
                 WHEN 3 THEN 'Cliente Pequeno'
                 ELSE 'Nennum'
               END AS Status_Cliente       
          FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID) AS Status_Cliente
  FROM CustomersBig
GO
-------------------------------
-------- Prefetching ----------
-------------------------------
USE TestPrefetching
GO
IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1
GO
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY, 
                       Col1 Char(5000), 
                       Col2 Char(1250),
                       Col3 Char(1250),
                       Col4 Numeric(18,2))
GO
-- 6 mins to run
INSERT INTO TestTab1 (Col1, Col2, Col3, Col4)
SELECT TOP 1000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 30
CREATE INDEX ix_Col4 ON TestTab1(Col4)
GO
IF OBJECT_ID('TestTab2') IS NOT NULL
  DROP TABLE TestTab2
GO
CREATE TABLE TestTab2 (ID Int IDENTITY(1,1) PRIMARY KEY,
                       ID_Tab1 Int,
                       Col1 Char(5000), 
                       Col2 Char(1250),
                       Col3 Char(1250))
GO
INSERT INTO TestTab2 (ID_Tab1, Col1, Col2, Col3)
SELECT TOP 1000 0, NEWID(), NEWID(), NEWID()
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 10
CREATE INDEX ix_ID_Tab1 ON TestTab2(ID_Tab1)
GO

DECLARE @MenorValor Int = 1, @MaiorValor Int = 5000, @i Int
SET @i = @MenorValor + ABS(CHECKSUM(NEWID())) % (@MaiorValor - @MenorValor)
;WITH CTE_1
AS
(
  SELECT ID, @MenorValor + ABS(CHECKSUM(NEWID())) % (@MaiorValor - @MenorValor) AS Col1
    FROM TestTab1
)
UPDATE TestTab2 SET ID_Tab1 = CTE_1.Col1
  FROM TestTab2
 INNER JOIN CTE_1
    ON CTE_1.ID = TestTab2.ID
GO
UPDATE STATISTICS TestTab1 WITH FULLSCAN
UPDATE STATISTICS TestTab2 WITH FULLSCAN
CREATE STATISTICS Stats1 ON TestTab1 (Col4) WITH FULLSCAN
GO
DBCC SHRINKFILE (N'TestPrefetching_log' , 0)
GO
CHECKPOINT
GO
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
GO

-- Checking table size
sp_spaceused TestTab1
GO
sp_spaceused TestTab2
GO

-- Stress with SQLIO
-- sqlio -kR -t16 -dC -s600 -b64

-- OPTIMIZED WITH UNORDERED PREFETCH
-- Using Prefetch
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT TestTab1.Col4, TestTab2.Col1
  FROM TestTab1
 INNER JOIN TestTab2
    ON TestTab1.ID = TestTab2.ID_Tab1
 WHERE TestTab1.Col4 < 0.8
OPTION (RECOMPILE)
GO
-- 9 seconds
-- TraceFlag 8744 to disable prefetch
-- Prefetch disabled
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT TestTab1.Col4, TestTab2.Col1
  FROM TestTab1
 INNER JOIN TestTab2
    ON TestTab1.ID = TestTab2.ID_Tab1
 WHERE TestTab1.Col4 < 0.8
OPTION (RECOMPILE, QUERYTRACEON 8744)


-- Another test forcing bad scenario
-- 9 seconds
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT TestTab1.Col4, TestTab2.Col1
  FROM TestTab1 WITH(index=ix_Col4)
 INNER JOIN TestTab2
    ON TestTab1.ID = TestTab2.ID_Tab1
 WHERE TestTab1.Col4 < 50
OPTION (RECOMPILE, LOOP JOIN)
GO
-- 2:22
CHECKPOINT
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
SELECT TestTab1.Col4, TestTab2.Col1
  FROM TestTab1 WITH(index=ix_Col4)
 INNER JOIN TestTab2
    ON TestTab1.ID = TestTab2.ID_Tab1
 WHERE TestTab1.Col4 < 50
OPTION (RECOMPILE, LOOP JOIN, QUERYTRACEON 8744)
GO


DROP PROC st_Test1
GO
CREATE PROC st_Test1 @i Numeric(18,2)
AS
BEGIN
  SELECT *
    FROM TestTab1
   INNER JOIN TestTab2
      ON TestTab1.ID = TestTab2.ID_Tab1
   WHERE TestTab1.Col4 < @i
  DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS
END
GO

-- First plan, no prefetching
-- Estimating less than 25 rows in the outer inner table, 
-- a plan without prefecthing is created...
-- 4 secs
EXEC st_Test1 @i = 0.05
GO
-- Reuse plan with no prefetching
-- 26 secs
EXEC st_Test1 @i =  0.8
GO

-- Asking to recompile
-- 3 seconds
EXEC st_Test1 @i = 0.8 WITH RECOMPILE
GO




-- Correlation...

-- Como melhorar esta consulta?
SET STATISTICS IO ON
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       Order_DetailsBig.Shipped_Date, 
       Order_DetailsBig.Quantity
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate BETWEEN '20110101' AND '20110131'
SET STATISTICS IO OFF

-- DROP INDEX ix_OrderDate ON [dbo].[OrdersBig]
CREATE NONCLUSTERED INDEX ix_OrderDate ON [dbo].[OrdersBig] ([OrderDate]) INCLUDE ([OrderID],[Value])

SET STATISTICS IO ON
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       Order_DetailsBig.Shipped_Date, 
       Order_DetailsBig.Quantity
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate BETWEEN '20110101' AND '20110131'
SET STATISTICS IO OFF
GO

-- DROP INDEX ix_Shipped_Date ON Order_DetailsBig
CREATE NONCLUSTERED INDEX ix_Shipped_Date ON Order_DetailsBig(Shipped_Date) INCLUDE(Quantity)
GO

SET STATISTICS IO ON
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       Order_DetailsBig.Shipped_Date, 
       Order_DetailsBig.Quantity
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate BETWEEN '20110101' AND '20110131'
SET STATISTICS IO OFF
GO


IF OBJECT_ID('vw_AggOrder_DetailsBig') IS NOT NULL
  DROP VIEW vw_AggOrder_DetailsBig
GO
CREATE VIEW vw_AggOrder_DetailsBig
WITH SCHEMABINDING
AS
SELECT DATEDIFF(DAY, CONVERT(Date, '19000101', 112), OrdersBig.OrderDate) / 30 as OrdersBig_OrderDate,
       DATEDIFF(DAY, CONVERT(Date, '19000101', 112), Order_DetailsBig.Shipped_Date) / 30 as Order_DetailsBig_Shipped_Date,
        COUNT_BIG(*) AS Cnt
  FROM dbo.OrdersBig
 INNER JOIN dbo.Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 GROUP BY DATEDIFF(DAY, CONVERT(Date, '19000101', 112), OrdersBig.OrderDate) / 30,
          DATEDIFF(DAY, CONVERT(Date, '19000101', 112), Order_DetailsBig.Shipped_Date) / 30
GO
CREATE UNIQUE CLUSTERED INDEX ixvw_AggOrder_DetailsBig ON vw_AggOrder_DetailsBig(OrdersBig_OrderDate, Order_DetailsBig_Shipped_Date)
GO

DECLARE @DataAtual Date = '20110101',
        @DataLimite Date = '20110131',
        @DataLimiteShipped Date

SELECT *
  FROM vw_AggOrder_DetailsBig WITH(NOEXPAND)
 WHERE OrdersBig_OrderDate >= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataAtual) / 30 
   AND OrdersBig_OrderDate <= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataLimite) / 30 

SELECT MIN(Order_DetailsBig_Shipped_Date), MAX(Order_DetailsBig_Shipped_Date)
  FROM vw_AggOrder_DetailsBig WITH(NOEXPAND)
 WHERE OrdersBig_OrderDate >= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataAtual) / 30 
   AND OrdersBig_OrderDate <= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataLimite) / 30 

SELECT @DataLimiteShipped = DATEADD(DAY, MAX(Order_DetailsBig_Shipped_Date + 1)  * 30, '19000101')
  FROM vw_AggOrder_DetailsBig WITH(NOEXPAND)
 WHERE OrdersBig_OrderDate >= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataAtual) / 30 
   AND OrdersBig_OrderDate <= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataLimite) / 30 

SELECT @DataLimiteShipped

SET STATISTICS IO ON
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       Order_DetailsBig.Shipped_Date, 
       Order_DetailsBig.Quantity
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate BETWEEN @DataAtual AND @DataLimite
   AND Order_DetailsBig.Shipped_Date BETWEEN @DataAtual AND @DataLimiteShipped
OPTION (RECOMPILE)
SET STATISTICS IO OFF

-- Criando uma PROC para simplificar as coisas...
IF OBJECT_ID('st_ConsultaOrders') IS NOT NULL
  DROP PROC st_ConsultaOrders
GO
CREATE PROC st_ConsultaOrders @DataAtual Date, @DataLimite Date
AS
BEGIN
  DECLARE @DataLimiteShipped Date

  SELECT @DataLimiteShipped = DATEADD(DAY, MAX(Order_DetailsBig_Shipped_Date + 1)  * 30, '19000101')
    FROM vw_AggOrder_DetailsBig WITH(NOEXPAND)
   WHERE OrdersBig_OrderDate >= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataAtual) / 30 
     AND OrdersBig_OrderDate <= DATEDIFF(DAY, CONVERT(Date, '19000101', 112), @DataLimite) / 30 

  SELECT OrdersBig.OrderID, 
         OrdersBig.OrderDate, 
         Order_DetailsBig.Shipped_Date, 
         Order_DetailsBig.Quantity
    FROM OrdersBig
   INNER JOIN Order_DetailsBig
      ON OrdersBig.OrderID = Order_DetailsBig.OrderID
   WHERE OrdersBig.OrderDate BETWEEN @DataAtual AND @DataLimite
     AND Order_DetailsBig.Shipped_Date BETWEEN @DataAtual AND @DataLimiteShipped
  OPTION (RECOMPILE)
END
GO


-- Teste antes/depois, se necessário testar com SQLQueryStress
DBCC DROPCLEANBUFFERS
SELECT OrdersBig.OrderID, 
       OrdersBig.OrderDate, 
       Order_DetailsBig.Shipped_Date, 
       Order_DetailsBig.Quantity
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate BETWEEN '20110101' AND '20110131'
GO
DBCC DROPCLEANBUFFERS
EXEC st_ConsultaOrders '20110101', '20110131'


-- Valor de 30 como base para criação da view, pode ser modificado...




-- Scalar functions...

-- Entendendo como Scalar functions são executadas


/* 
  Qual será o resultado de CONVERT(Time, GetDate())? 
  A - Um valor para cada linha.
  B - O mesmo valor para todas as linhas.
*/
SELECT TOP 200000
       ContactName, CONVERT(Time, GetDate())
  FROM CustomersBig
GO

IF OBJECT_ID('fn_RetornaHora', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_RetornaHora
GO
CREATE FUNCTION dbo.fn_RetornaHora()
RETURNS Time
AS
BEGIN
  RETURN CONVERT(Time, GetDate())
END
GO
SELECT dbo.fn_RetornaHora()

-- E agora? Qual será o resultado da scalar function?
SELECT TOP 200000
       ContactName, dbo.fn_RetornaHora()
  FROM CustomersBig
GO



-- Teste performance...
/*
  Analisar os seguintes contadores no PERFMON
  Transactions:PageSplits/Sec
  Processor:Processor Time
*/

IF OBJECT_ID('#TMP') IS NOT NULL -- Funciona?

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Inserindo em uma tabela temporária sem usar as scalar functions
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       DATEADD(d, (- DATEPART(d, OrderDate) + 1) , OrderDate) AS fn_Primeiro_Dia_Mes,
       DATEADD(d , -DATEPART(d, DATEADD( mm, 1, OrderDate)) ,DATEADD( mm, 1, OrderDate)) AS fn_Ultimo_Dia_Mes -- SQL2012 EOMONTH
  FROM OrdersBig
GO

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Inserindo em uma tabela temporária usando as scalar functions
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       dbo.fn_Primeiro_Dia_Mes(OrderDate) AS fn_Primeiro_Dia_Mes,
       dbo.fn_Ultimo_Dia_Mes(OrderDate) AS fn_Ultimo_Dia_Mes
  FROM OrdersBig
GO
/*
  Um novo operador de Spool é utilizado para ler os dados que serão inseridos na tabela
  temporária, este operador é utilizado para evitar erros relacionados ao halloween problem.
  Como a function não foi definida com SCHEMABINDING o SQL Server não sabe se a function
  irá ler ou atualizar dados de alguma tabela... Então ele usa o SPOOL para evitar possíveis erros.
  http://blogs.msdn.com/b/ianjo/archive/2006/01/31/521078.aspx
  http://blogs.msdn.com/b/mikecha/archive/2009/05/19/sql-high-cpu-and-tempdb-growth-by-scalar-udf.aspx
*/

-- Vamos recriar as functions e definir como SCHEMABINDING
ALTER FUNCTION dbo.fn_Primeiro_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  RETURN DATEADD(d, (- DATEPART(d, @Data) + 1) , @Data);
END
GO
ALTER FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Testando novamente com as functions definidas como schemabinding
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       dbo.fn_Primeiro_Dia_Mes(OrderDate) AS fn_Primeiro_Dia_Mes,
       dbo.fn_Ultimo_Dia_Mes(OrderDate) AS fn_Ultimo_Dia_Mes
  FROM OrdersBig
GO

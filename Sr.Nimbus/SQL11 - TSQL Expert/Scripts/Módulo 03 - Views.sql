/*
  Sr.Nimbus - T-SQL Expert
         Módulo 03
  http://www.srnimbus.com.br
*/

USE Northwind
GO

----------------------------------------
-------------- Views ------------------
----------------------------------------
IF OBJECT_ID('vw_Region') IS NOT NULL 
  DROP VIEW vw_Region
GO
ALTER VIEW vw_Region
AS
SELECT  RegionID ,
        RegionDescription
  FROM Region
GO
SELECT * FROM vw_Region
GO
-- ALTER TABLE Region DROP COLUMN Col1
ALTER TABLE Region ADD Col1 Int
GO
-- Retorna a coluna Col1, ou não?
SELECT * FROM vw_Region
GO

sp_refreshview vw_Region



sp_refreshview vw_Region



-- Teste 1
-- Teste View Indexada
USE NorthWind
GO
/*
  Limpar/Preparar o banco
*/

/*
  Consulta abaixo faz um Scan no índice cluster
*/
SET STATISTICS IO ON
SELECT CustomerID, SUM(Value)
  FROM OrdersBig
 GROUP BY CustomerID
 ORDER BY CustomerID
SET STATISTICS IO OFF
GO


CREATE INDEX ix_Value_CustomerID ON OrdersBig(Value, CustomerID)
GO
/*
  Após criar o índice a consulta abaixo 
  passa a fazer um Scan no índice NonClustered
  Porém continua usando o Hash Aggregate
*/
SET STATISTICS IO ON
SELECT CustomerID, SUM(Value)
  FROM OrdersBig
 GROUP BY CustomerID
 ORDER BY CustomerID
SET STATISTICS IO OFF
GO

/* 
  Até para criar um índice o SQL pode fazer proveito de outro índice
  O create index abaixo usa o indice ix_Value_CustomerID para criar 
  o ix_CustomerID_Value
*/
CREATE INDEX ix_CustomerID_Value ON OrdersBig(CustomerID) INCLUDE(Value)

-- Não gera mais o HashAggregate e usa o índice para ler os dados
SET STATISTICS IO ON
SELECT CustomerID, SUM(Value)
  FROM OrdersBig
 GROUP BY CustomerID
 ORDER BY CustomerID
SET STATISTICS IO OFF
GO

IF OBJECT_ID('vw_Test') IS NOT NULL
BEGIN
  DROP VIEW vw_Test
END
GO
CREATE VIEW vw_Test
WITH SCHEMABINDING AS 
SELECT CustomerID, SUM(Value) AS Value, Count_Big(*) AS CountBig
  FROM dbo.OrdersBig
 GROUP BY CustomerID
GO
CREATE UNIQUE CLUSTERED INDEX ix_View ON vw_Test(CustomerID)
GO



SET STATISTICS IO ON
SELECT CustomerID, SUM(Value)
  FROM OrdersBig
 GROUP BY CustomerID
 ORDER BY CustomerID
SET STATISTICS IO OFF
-- Obs.: Para o comando acima, o SQL Server só consegue acesar os dados pela view, em versão Enterprise e Developer
-- em versões diferentes é necessário usar a view e o hint NOEXPAND.

-- Teste 2
-- NOEXPAND Hint, Utilizado para fazer com que o Query Optimizer use
-- uma view indexada em versões diferente de Enterprise e Developer

IF OBJECT_ID('vw_Test2') IS NOT NULL
  DROP VIEW vw_Test2
GO
CREATE VIEW vw_Test2
WITH SCHEMABINDING
AS
SELECT CustomersBig.ContactName,
       OrdersBig.OrderID,
       OrdersBig.OrderDate,
       OrdersBig.Value,
       Order_DetailsBig.ProductID,
       Order_DetailsBig.Quantity
  FROM dbo.CustomersBig
 INNER JOIN dbo.OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 INNER JOIN dbo.Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE OrdersBig.OrderDate > CONVERT(DateTime, '20180201', 112) -- Cannot create index on view "Northwind.dbo.vw_Test". The view contains a convert that is imprecise or non-deterministic.
GO

CREATE UNIQUE CLUSTERED INDEX ixView ON vw_Test2 (OrderID, ProductID)
GO
CREATE NONCLUSTERED INDEX ixViewContactName ON vw_Test2(ContactName)
GO

-- Comparar performance
SELECT * FROM vw_Test2 WITH(NOEXPAND)
GO
SELECT * FROM vw_Test2 
OPTION (EXPAND VIEWS)
GO

-- Usando índice nonclustered
SELECT ContactName, OrderID
  FROM vw_Test2
 WHERE ContactName LIKE 'Ana%'
GO

-- Teste 3
-- Alternativa para limitação do LEFT OUTER JOIN

-- Preparando demo
DELETE FROM ProductsBig
 WHERE NOT EXISTS(SELECT 1 
                    FROM Order_DetailsBig
                   WHERE ProductsBig.ProductID = Order_DetailsBig.ProductID)
GO
DELETE FROM ProductsBig
WHERE ProductName = 'Teste Produto'
GO
INSERT INTO ProductsBig (ProductName, Col1)
VALUES  ('Teste Produto ' + CONVERT(VarChar(200), NEWID()), NEWID())
GO 10

-- Query para retornar todos os produtos e suas respectivas vendas
-- inclusive os que nunca tiveram venda, neste caso retornar NULL
SET STATISTICS IO ON
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
SELECT ProductsBig.ProductID, ProductsBig.ProductName, 
       SUM(Order_DetailsBig.Quantity) AS Val
  FROM ProductsBig
  LEFT OUTER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 GROUP BY ProductsBig.ProductID, ProductsBig.ProductName
 ORDER BY Val
SET STATISTICS IO OFF
--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Order_DetailsBig'. Scan count 5, logical reads 3626, physical reads 1, read-ahead reads 3610, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'ProductsBig'. Scan count 5, logical reads 104, physical reads 2, read-ahead reads 22, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
GO
-- Pergunta, os valores NULL vem no inicio ou no fim do resultado?


IF OBJECT_ID('vw_TestLeftOuter') IS NOT NULL
  DROP VIEW vw_TestLeftOuter
GO
CREATE VIEW vw_TestLeftOuter
WITH SCHEMABINDING
AS
SELECT ProductsBig.ProductID, 
       ProductsBig.ProductName, 
       SUM(ISNULL(Order_DetailsBig.Quantity,0)) AS Val, -- Cannot create the clustered index "ix" on view "Northwind.dbo.vw_TestLeftOuter" because the view references an unknown value (SUM aggregate of nullable expression). Consider referencing only non-nullable values in SUM. ISNULL() may be useful for this.
       COUNT_BIG(*) AS CntBig
  FROM dbo.ProductsBig
 INNER JOIN dbo.Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 GROUP BY ProductsBig.ProductID, ProductsBig.ProductName
GO
CREATE UNIQUE CLUSTERED INDEX ix ON vw_TestLeftOuter(ProductID)
GO

-- Consulta usando view indexada
SET STATISTICS IO ON
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
SELECT ProductsBig.ProductID, 
       ProductsBig.ProductName, 
       vw_TestLeftOuter.Val
  FROM ProductsBig
  LEFT OUTER JOIN vw_TestLeftOuter
    ON ProductsBig.ProductID = vw_TestLeftOuter.ProductID
 ORDER BY Val
SET STATISTICS IO OFF
GO
--Table 'ProductsBig'. Scan count 1, logical reads 29, physical reads 1, read-ahead reads 22, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'vw_TestLeftOuter'. Scan count 1, logical reads 17, physical reads 1, read-ahead reads 15, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.




-- Teste 4
-- Impacto nas alterações

-- Verificar plano, e observar insert no índice da view
-- apagar todos os índices da OrdersBig
-- DROP INDEX OrdersBig.ix_Col_fn_ValorVezesDois
-- DROP VIEW vw_Test2
-- ALTER TABLE OrdersBig DROP CONSTRAINT fk_OrdersBig_CustomersBig

-- Desabilitar índice
ALTER INDEX ix_View ON vw_test DISABLE
GO
 
SET STATISTICS IO ON
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES  (1, GetDate(), ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))))
SET STATISTICS IO OFF
GO
--Table 'OrdersBig'. Scan count 0, logical reads 3, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


-- Habilitar índice
ALTER INDEX ix_View ON vw_test REBUILD
GO

SET STATISTICS IO ON
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES  (1, GetDate(), ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))))
SET STATISTICS IO OFF
GO
--Table 'vw_Test'. Scan count 0, logical reads 6, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Worktable'. Scan count 3, logical reads 12, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'OrdersBig'. Scan count 0, logical reads 3, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


-- Inserindo massa de dados
SET STATISTICS IO ON
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
SELECT TOP 500000
       ABS(CONVERT(Int, CheckSUM(NEWID()) / 1000000)),
       GetDate(), 
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
  FROM OrdersBig 
SET STATISTICS IO OFF
GO
--Table 'vw_Test'. Scan count 1, logical reads 8605, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'Worktable'. Scan count 2, logical reads 1384985, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'OrdersBig'. Scan count 1, logical reads 1604563, physical reads 0, read-ahead reads 1575, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


-- Desabilitar índice
ALTER INDEX ix_View ON vw_test DISABLE
GO
-- Inserindo massa de dados
SET STATISTICS IO ON
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
SELECT TOP 500000
       ABS(CONVERT(Int, CheckSUM(NEWID()) / 1000000)),
       GetDate(), 
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
  FROM OrdersBig 
SET STATISTICS IO OFF
GO
--Table 'OrdersBig'. Scan count 1, logical reads 1604560, physical reads 0, read-ahead reads 1567, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


-- E um Update? Quanto piora?
-- Habilitar índice
ALTER INDEX ix_View ON vw_test REBUILD
GO
UPDATE TOP (50) PERCENT OrdersBig 
SET Value = ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
GO

-- Desabilitar índice
ALTER INDEX ix_View ON vw_test DISABLE
GO
UPDATE TOP (50) PERCENT OrdersBig SET Value = ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
GO


-- Teste 5 (Bonus, estudar em casa, ver artigos Simple-Talk)
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



-- Teste 6
-- Cuidado com selects em views...

IF OBJECT_ID('vw_Teste7') IS NOT NULL 
  DROP VIEW vw_Teste7
GO
CREATE VIEW vw_Teste7
AS
SELECT OrdersBig.OrderID,
       OrdersBig.OrderDate,
       ISNULL(CustomersBig.ContactName,'Cliente não existe') AS ContactName,
       CustomersBig.ContactName AS ContactNameOriginal
  FROM OrdersBig
  LEFT OUTER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
GO
--DROP INDEX CustomersBig.ixContactName
CREATE INDEX ixContactName ON CustomersBig(ContactName)
--DROP INDEX OrdersBig.ixCustomerID
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(OrderDate)
GO


-- Usa o índice ixContactName ou não?
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
SELECT * 
  FROM vw_Teste7
 WHERE ContactName like 'Antonio Moreno 5%'
GO

-- E agora?
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
SELECT * 
  FROM vw_Teste7
 WHERE ContactNameOriginal like 'Antonio Moreno 5%'
GO


-- Teste 7
-- Preparando demo
IF OBJECT_ID('ProductsBigTestView1') IS NOT NULL
  DROP TABLE ProductsBigTestView1
SELECT ProductID,
       CONVERT(Char(200),ProductName) AS ProductName,
       Col1
  INTO ProductsBigTestView1
  FROM ProductsBig
GO
IF OBJECT_ID('ProductsBigTestView2') IS NOT NULL
  DROP TABLE ProductsBigTestView2
SELECT ProductID,
       CONVERT(Char(250),ProductName) AS ProductName,
       Col1 
  INTO ProductsBigTestView2
  FROM ProductsBig
GO

-- Criando view
IF OBJECT_ID('vw_Teste8') IS NOT NULL 
  DROP VIEW vw_Teste8
GO
CREATE VIEW vw_Teste8
AS
SELECT * FROM ProductsBigTestView1
 UNION ALL
SELECT * FROM ProductsBigTestView2
GO

CREATE INDEX ixProductName ON ProductsBigTestView1(ProductName)
CREATE INDEX ixProductName ON ProductsBigTestView2(ProductName)
GO

-- Porque não faz seek no índice em ProductsBigTestView1 ? 
SELECT * 
  FROM vw_Teste8
 WHERE ProductName = 'Konbu EC386C0F'


-- Teste 8
 /*
  Overview SQL Server não deveria aplicar um filtro de like depois da agregação, 
  pois a lógica do like colide com a lógica de macthing da aggregação ...
*/

-- Enganar o SQL pra ele pensar que a tabela é grande...
UPDATE STATISTICS Orders WITH ROWCOUNT = 99999, PAGECOUNT = 50000
GO
-- Criando índice em ShipCountry
CREATE INDEX ixShipCountry ON Orders(ShipCountry)
GO

-- Atualizando uma linha para 'Brazil+ESPACO'
UPDATE Orders SET ShipCountry = 'Brazil '
WHERE OrderID = 10248
GO

-- Como o like considera o espaço, ele conta apenas UMA linha
-- Usa >= e <= como predicate para conseguir usar o índice
SELECT ShipCountry, COUNT(OrderID) AS cnt
  FROM Orders
 WHERE ShipCountry like 'Brazil '
 GROUP BY ShipCountry
GO

-- E se eu criar uma view com essa consulta??
IF OBJECT_ID('vw_View9', 'v') is not null
  DROP VIEW vw_View9
GO
CREATE VIEW vw_View9
AS
SELECT ShipCountry, COUNT(OrderID) AS cnt
  FROM Orders
 GROUP BY ShipCountry
GO

-- E agora, conta apenas 1 order?
SELECT * FROM vw_View9
 WHERE ShipCountry like 'Brazil '
GO

-- E na CTE?
WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM Orders
   GROUP BY ShipCountry
)

SELECT * FROM CTE_1
 WHERE ShipCountry like 'Brazil '

 
-- Exemplo Simon Sabin (SQL Server MVP)
WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM (SELECT TOP 1000 * FROM Orders ORDER BY OrderID DESC) Orders
   GROUP BY ShipCountry
)
SELECT ShipCountry +'XXX', cnt
  FROM CTE_1
 WHERE ShipCountry like 'Brazil '
GO

WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM (select top 1000 * from Orders order by OrderID asc) Orders
   GROUP BY ShipCountry
)

SELECT ShipCountry +'XXX', cnt
  FROM CTE_1
WHERE ShipCountry like 'Brazil '



-- O valor que é lido primeiro pelo StreamAggregate é utilizado como base para a agregação...

-- INF: How SQL Server Compares Strings with Trailing Spaces
-- http://support.microsoft.com/kb/316626

IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #tmp
GO
CREATE TABLE #tmp (c1 varchar(10))
GO
INSERT INTO #tmp VALUES ('abc ')
INSERT INTO #tmp VALUES ('abc')
GO
SELECT DATALENGTH(c1) as 'EqualWithSpace', * FROM #tmp WHERE c1 = 'abc '
SELECT DATALENGTH(c1) as 'EqualNoSpace  ', * FROM #tmp WHERE c1 = 'abc'
SELECT DATALENGTH(c1) as 'GTWithSpace   ', * FROM #tmp WHERE c1 > 'ab '
SELECT DATALENGTH(c1) as 'GTNoSpace     ', * FROM #tmp WHERE c1 > 'ab'
SELECT DATALENGTH(c1) as 'LTWithSpace   ', * FROM #tmp WHERE c1 < 'abd '
SELECT DATALENGTH(c1) as 'LTNoSpace     ', * FROM #tmp WHERE c1 < 'abd'
SELECT DATALENGTH(c1) as 'LikeWithSpace ', * FROM #tmp WHERE c1 LIKE 'abc %'
SELECT DATALENGTH(c1) as 'LikeNoSpace   ', * FROM #tmp WHERE c1 LIKE 'abc%'
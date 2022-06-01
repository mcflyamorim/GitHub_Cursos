/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Preparar ambiente... Criar tabelas com 5 milhões de linhas...
-- 2 mins para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 5000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 5000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO
IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 5000000 IDENTITY(Int, 1,1) AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
UPDATE ProductsBig SET ProductName = 'Produto qualquer'
WHERE ProductID = 1
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO
IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
  DROP TABLE Order_DetailsBig
GO
SELECT OrdersBig.OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000)),0) AS ProductID,
       GetDate() -  ABS(CheckSUM(NEWID())) / 1000000 AS Shipped_Date,
       CONVERT(Integer, ABS(CheckSUM(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM OrdersBig
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID])
GO
-- Criar os índices para cobrir os filtros/joins da query
CREATE INDEX ixContactName ON CustomersBig(ContactName) -- indexando WHERE
CREATE INDEX ixProductName ON ProductsBig(ProductName) -- indexando WHERE
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(Value) -- indexando FK
CREATE INDEX ixProductID ON Order_DetailsBig(ProductID) INCLUDE(Quantity) -- indexando FK
GO

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------


-- Criar novo cliente
INSERT INTO CustomersBig (CompanyName, ContactName, Col1, Col2)
VALUES ('Emp Fabiano', 'Fabiano Amorim', NEWID(), NEWID())

-- Efetuar uma venda para este cliente
INSERT INTO OrdersBig (CustomerID, OrderDate, Value)
VALUES(SCOPE_IDENTITY(), GetDate(), 999)
SET IDENTITY_INSERT Order_DetailsBig ON
INSERT INTO Order_DetailsBig(OrderID, ProductID, Shipped_Date, Quantity)
VALUES (SCOPE_IDENTITY(), 1, GetDate() + 30, 999)
SET IDENTITY_INSERT Order_DetailsBig OFF
GO


-- Criando procedure que retorna dados de venda de cliente e produto específico
IF OBJECT_ID('st_RetornaVendaClienteProduto') IS NOT NULL DROP PROC st_RetornaVendaClienteProduto
GO
CREATE PROCEDURE st_RetornaVendaClienteProduto @ContactName VarChar(200), @ProductName VarChar(200)
AS
SELECT OrdersBig.OrderID, 
       OrdersBig.Value,
       Order_DetailsBig.Quantity,
       CustomersBig.ContactName,
       ProductsBig.ProductName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 INNER JOIN ProductsBig
    ON Order_DetailsBig.ProductID = ProductsBig.ProductID
 WHERE CustomersBig.ContactName = @ContactName
   AND ProductsBig.ProductName = @ProductName
GO


-- "cold cache"
CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS;
GO
EXEC st_RetornaVendaClienteProduto @ContactName = 'Fabiano Amorim', @ProductName = 'Produto qualquer'
GO


-- Colocar exec no SQLQueryStress para rodar com 1000 iterations e 200 threads...
-- Ver batch requests por segundo no perfmon...



-- Analisar sintaxe da query
ALTER PROCEDURE st_RetornaVendaClienteProduto @ContactName VarChar(200), @ProductName VarChar(200)
AS
;WITH JoinEntre_CustomersBig_e_OrdersBig
AS
(
SELECT OrdersBig.OrderID,
       OrdersBig.Value,
       CustomersBig.ContactName
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
),
JoinEntre_ProductsBig_e_Order_DetailsBig
AS
(
SELECT 
       Order_DetailsBig.OrderID,
       Order_DetailsBig.Quantity,
       ProductsBig.ProductName
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON Order_DetailsBig.ProductID = ProductsBig.ProductID
)
SELECT JoinEntre_CustomersBig_e_OrdersBig.OrderID,
       JoinEntre_CustomersBig_e_OrdersBig.Value,
       JoinEntre_ProductsBig_e_Order_DetailsBig.Quantity,
       JoinEntre_CustomersBig_e_OrdersBig.ContactName,
       JoinEntre_ProductsBig_e_Order_DetailsBig.ProductName
  FROM JoinEntre_CustomersBig_e_OrdersBig
 INNER JOIN JoinEntre_ProductsBig_e_Order_DetailsBig
    ON JoinEntre_CustomersBig_e_OrdersBig.OrderID = JoinEntre_ProductsBig_e_Order_DetailsBig.OrderID
 WHERE JoinEntre_CustomersBig_e_OrdersBig.ContactName = @ContactName
   AND JoinEntre_ProductsBig_e_Order_DetailsBig.ProductName = @ProductName
 OPTION (FORCE ORDER)
GO




-- References:
    Join Reordering and Bushy Plans
    https://www.simple-talk.com/sql/performance/join-reordering-and-bushy-plans/

    ACM Paper: Left-deep vs. bushy trees: an analysis of strategy spaces and its implications for query optimization
    http://dl.acm.org/citation.cfm?id=115813

    G. Graefe. The Cascades framework for query optimization. Data Engineering Bulletin, 18(3), 1995.
    http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.98.9460

    Microsoft Research: Polynomial Heuristics for Query Optimization
    http://research.microsoft.com/apps/pubs/default.aspx?id=132009

    Itzik Ben-Gan: T-SQL Deep Dives: Create Efficient Queries
    http://www.sqlmag.com/print/database-administration/T-SQL-Deep-Dives-Creating-Queries-That-Work-and-Perform-Well-125389

    Benjamin Nevarez: Optimizing Join Orders
    http://www.benjaminnevarez.com/2010/06/optimizing-join-orders/
    
    Wikipedia: 
    http://en.wikipedia.org/wiki/Query_optimizer 


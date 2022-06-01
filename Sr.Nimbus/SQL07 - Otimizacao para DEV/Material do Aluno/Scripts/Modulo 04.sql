/**************************************************************************************************
	
	Sr. Nimbus Serviços em Tecnolgia LTDA
	
	Curso: SQL07 - Módulo 03
	
**************************************************************************************************/
-- Optimizer trabalhando
USE AdventureWorks2008
go

DROP INDEX Sales.SalesOrderDetail.idx_composto01

SP_HELP 'Sales.SalesOrderDetail'
go

select top 1000 * from Sales.SalesOrderDetail
go

DBCC FREEPROCCACHE

-- Note o aggregate que representa o group by
SELECT 
	SUM(SOD.UnitPrice * SOD.OrderQty) AS Total
FROM Sales.SalesOrderDetail AS SOD
GROUP BY SOD.SalesOrderDetailID
go

SELECT 
	SUM(SOD.UnitPrice * SOD.OrderQty) AS Total
FROM Sales.SalesOrderDetail AS SOD
GROUP BY SOD.SalesOrderDetailID, SOD.SalesOrderID
go


USE Northwind
GO

DBCC FREEPROCCACHE

-- IN ou NOT IN???
SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID NOT IN (4,5,6,7,8) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON

SELECT ProductName, p.UnitPrice, CompanyName, Country, quantity
FROM Products as P inner join Suppliers as S
ON P.SupplierID = S.SupplierID
inner join [order details] as od
on p.productID = od.productid
WHERE CategoryID in (1,2,3) and p.Unitprice < 20
and Country = 'uk' and Quantity < 30
GO



-- Tipos de Joins
Use Northwind
GO

SET STATISTICS IO ON

exec sp_help [order details]
exec sp_help [products]
go

select * from sys.indexes
where object_id = object_id('order details')

SELECT * 
FROM sys.index_columns
where object_id = object_id('order details')
	AND index_id IN (5, 7)
	 

SET STATISTICS IO ON
SET STATISTICS TIME ON

-- Nested loop
SELECT *
FROM Products as P
inner join Categories as C
ON P.CategoryID = C.CategoryID
GO

-- Hash Join 
Select ProductName, OrderID, OD.UnitPrice, Quantity
from products as p 
INNER JOIN [order details] AS OD
ON P.ProductID = OD.ProductID
Where CategoryID = 1
go

-- Merge JOIN
select O.OrderID, OrderDate, ProductId, UnitPrice
FROM ORDERs AS o 
INNER JOIN [Order Details] as OD
ON O.OrderID = OD.OrderID
go

/*
	Hints
*/
-- Hash Join 
Select ProductName, OrderID, OD.UnitPrice, Quantity
from products as p INNER JOIN [order details] AS OD
ON P.ProductID = OD.ProductID
Where CategoryID = 1
go

-- Mostrando o uso de HINTs para forçar um outro plano de execução
Select ProductName, OrderID, OD.UnitPrice, Quantity
from products as p 
INNER MERGE JOIN [order details] AS OD
ON P.ProductID = OD.ProductID
Where CategoryID = 1
go

-- Mostrando o uso de HINTs para forçar um outro plano de execução
Select ProductName, OrderID, OD.UnitPrice, Quantity
from products as p 
INNER LOOP JOIN [order details] AS OD
ON P.ProductID = OD.ProductID
Where CategoryID = 1
go


-- Index intersection
USE SQL07
go

DROP TABLE Vendas

SELECT * 
INTO Vendas
FROM AdventureWorks2008.Sales.SalesOrderHeader
go


SP_HELP Vendas

select * from vendas

CREATE UNIQUE CLUSTERED INDEX idx_venda
ON Vendas (SalesOrderId)
go

CREATE NONCLUSTERED INDEX idx_Data
ON Vendas (OrderDate)
go

CREATE NONCLUSTERED INDEX idx_Cliente
ON Vendas (CustomerID)
go

select *
from vendas

SELECT *
FROM Vendas
WHERE CustomerID < 11100
go

SELECT *
FROM Vendas
where orderDate < '20010901'
go

-- O que o SQL Server vai fazer?
SELECT *
FROM Vendas
WHERE CustomerID < 11100
AND orderDate < '20010901'
GO

SELECT *
FROM Vendas with(index(1))
WHERE CustomerID < 11100
AND orderDate < '20010901'
GO

-- E agora?
SELECT OrderDate, CustomerID, SalesOrderID
FROM Vendas
WHERE CustomerID < 11100
AND orderDate < '20010901'
go

SELECT OrderDate, CustomerID, SalesOrderID
FROM Vendas with(index(1))
WHERE CustomerID < 11100
AND orderDate < '20010901'
GO



-- Estatísticas
USE AdventureWorks2008
GO

exec sp_help 'sales.salesorderheader'
exec sp_help 'sales.salesorderdetail'

DBCC SHOW_STATISTICS ('sales.salesorderheader', PK_SalesOrderHeader_SalesOrderID)
go

DBCC SHOW_STATISTICS ('sales.salesorderdetail', PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID)
go

select * from Sales.SalesOrderHeader

CREATE NONCLUSTERED INDEX idx_testeEstatistica
ON Sales.SalesOrderHeader (SalesPersonId, TerritoryID, OrderDate, Status, PurchaseOrderNumber)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica)
go

DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica
GO

CREATE NONCLUSTERED INDEX idx_testeEstatistica
ON Sales.SalesOrderHeader (OrderDate, SalesPersonId, TerritoryID, Status, PurchaseOrderNumber)
go
DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica)
go

DROP INDEX Sales.SalesOrderHeader.idx_testeEstatistica2
GO

CREATE NONCLUSTERED INDEX idx_testeEstatistica2
ON Sales.SalesOrderHeader (PurchaseOrderNumber, OrderDate, SalesPersonId, TerritoryID, Status)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica2)
go

CREATE NONCLUSTERED INDEX idx_testeEstatistica3
ON Sales.SalesOrderHeader (Status, PurchaseOrderNumber, OrderDate, SalesPersonId, TerritoryID)
go

DBCC SHOW_STATISTICS ('sales.salesorderheader', idx_testeEstatistica3)
go


SELECT * FROM Person.Person

SP_HELPSTATS 'Person.Person'

CREATE STATISTICS STATSTeste ON Person.Person(FirstName,LastName)
WITH SAMPLE 50 PERCENT

DBCC SHOW_STATISTICS ('Person.Person', STATSTeste)
go

use Northwind
select *
from orders


SELECT * FROM sys.dm_exec_query_optimizer_info;


DBCC SHOW_STATISTICS ('sales.salesorderheader', PK_SalesOrderHeader_SalesOrderID)

DBCC SHOW_STATISTICS ('sales.salesorderheader', orderdate)


SELECT 
	STATS_DATE(object_id, stats_id) as data,
	*
FROM sys.stats
WHERE object_id = OBJECT_ID('sales.salesorderheader')

UPDATE STATISTICS sales.salesorderheader
WITH FULLSCAN

USE Inside
GO

exec sp_help 'Pessoa'
go
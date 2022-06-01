/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Preparando demo
DELETE FROM Order_DetailsBig
WHERE OrderID > 1000000
DELETE FROM OrdersBig
WHERE OrderID > 1000000
GO
INSERT INTO OrdersBig(CustomerID, OrderDate, Value )
VALUES  (1, GetDate(),999)
INSERT INTO Order_DetailsBig(OrderID, ProductID, Shipped_Date, Quantity)
VALUES  (@@Identity, 1, GetDate()-30, 9), 
        (@@Identity, 2, GetDate()-30, 9), 
        (@@Identity, 3, GetDate()-30, 9)
GO

------------------------------------------------
--- Pedidos com mesma qtde de itens vendidos ---
------------------------------------------------
/*
  Escreva uma consulta que retorne informações
  sobre pedidos onde a quantidade de itens vendidos
  é a mesma para todos os itens vendidos.

  Banco: NorthWind
  Tabelas: OrdersBig e Order_DetailsBig
  Retornar as informações de
  OrderID, ProductID, Quantity, OrderDate e Value
*/

-- Exemplo resultado esperado:
/*
  OrderID	OrderDate	  Value
  1000005	2013-05-10	 999.00
*/





-- Query 1
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE();
GO
SELECT DISTINCT a.OrderID, b.Quantity, a.OrderDate, a.Value
  FROM OrdersBig a
 INNER JOIN Order_DetailsBig b
    ON a.OrderID = b.OrderID
 WHERE NOT EXISTS(SELECT 1 
                    FROM Order_DetailsBig c
                   WHERE c.OrderID = b.OrderID
                     AND c.Quantity <> b.Quantity)
OPTION (MAXDOP 1)
GO

-- Query 2
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE();
GO
SELECT a.OrderID, a.OrderDate, MIN(b.Quantity), a.Value
  FROM OrdersBig a
 INNER JOIN Order_DetailsBig b
    ON a.OrderID = b.OrderID
 GROUP BY a.OrderID, a.OrderDate, a.Value
HAVING MIN(b.Quantity) = MAX(b.Quantity)
OPTION (MAXDOP 1)
GO

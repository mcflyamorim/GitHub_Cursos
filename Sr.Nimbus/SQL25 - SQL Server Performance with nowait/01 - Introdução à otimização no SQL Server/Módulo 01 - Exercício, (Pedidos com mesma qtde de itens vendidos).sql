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
  OrderID	ProductID	Quantity	OrderDate	  Value
  1000005	1	        9	       2013-05-10	 999.00
  1000005	2	        9	       2013-05-10	 999.00
  1000005	3	        9	       2013-05-10	 999.00
*/


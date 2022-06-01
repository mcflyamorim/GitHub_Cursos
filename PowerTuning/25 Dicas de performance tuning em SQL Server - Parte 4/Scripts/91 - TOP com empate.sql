USE Northwind
GO

-- TOP 10 Clientes...
SELECT TOP 10 Customers.ContactName, 
       COUNT(Orders.OrderID) AS Cnt
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
 ORDER BY Cnt DESC



-- Qual o critério para selecionar "Peter Franken" e não "Renate..."? 
SELECT TOP 15 Customers.ContactName, 
       COUNT(Orders.OrderID) AS Cnt
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
 ORDER BY Cnt DESC














-- TOP 10 WITH TIES
SELECT TOP 10 WITH TIES Customers.ContactName, 
       COUNT(Orders.OrderID) AS Cnt
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
 ORDER BY Cnt DESC

USE Northwind
GO

SELECT OrderID, CustomerID, Value
  FROM OrdersBig
 WHERE CustomerID = 10
ORDER BY Value
GO


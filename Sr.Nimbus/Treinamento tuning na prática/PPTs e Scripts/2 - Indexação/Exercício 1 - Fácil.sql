USE Northwind
GO


SELECT OrderID, CustomerID, Value
  FROM OrdersBig
 WHERE Value < 100
GO


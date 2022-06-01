USE Northwind
GO

SELECT * 
  FROM OrdersBig
 WHERE Value / 2 < 1.0
GO

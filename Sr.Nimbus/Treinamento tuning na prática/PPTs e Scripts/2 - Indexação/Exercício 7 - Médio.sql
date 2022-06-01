USE Northwind
GO

SELECT * 
  FROM OrdersBig
 WHERE Value < 1.0
    OR OrderDate = '2020-05-28'
GO
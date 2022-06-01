USE Northwind
GO

SELECT *
  FROM CustomersBig
 WHERE SUBSTRING(ContactName, 1, 10) = 'Victoria A'
GO

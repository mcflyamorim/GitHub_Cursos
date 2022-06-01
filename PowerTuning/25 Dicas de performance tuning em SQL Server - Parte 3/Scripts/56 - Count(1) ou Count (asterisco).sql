USE Northwind
GO

--COUNT(1) versus COUNT(*)
--O que é melhor? 
SELECT COUNT(1)
  FROM Products
GO
SELECT COUNT(*)
  FROM Products
GO
SELECT COUNT(ProductID) -- PK
  FROM Products
GO

/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

/*
  Foldable and Non-foldable Expressions
*/

-- Ex: Foldable Expressions
SELECT * 
  FROM Order_Details
 WHERE Quantity = 1+1
OPTION (RECOMPILE)

-- Ex: Foldable Expressions
SELECT * 
  FROM Order_Details
 WHERE Quantity = (10/2) * 2
OPTION (RECOMPILE)

-- Ex: Foldable Expressions
SELECT * 
  FROM Customers
 WHERE ContactName = REPLACE('EduaYYY', 'YYY', 'rdo')


-- Ex: NonFoldable Expressions
SELECT * 
  FROM Order_Details
 WHERE Quantity = ABS(-10)
GO
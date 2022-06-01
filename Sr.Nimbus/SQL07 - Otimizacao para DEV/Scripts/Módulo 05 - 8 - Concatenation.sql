/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Concatenation
*/

/*
  All operators used in execution plans, implement three methods called 
  Init(), GetNext() and Close(). 
  Some operators can receive more than one input, so, these inputs will 
  be processed at the Init() method. The concatenation is one example 
  of these operators.

  At the Init() method, the concatenation will initialize itself 
  and set up any required data structures. 
  After that, it will run the GetNext() method to read the 
  first or the subsequent row of the input data, it runs this 
  method until it has read all rows from the input data.
*/

/*
  Operador de Merge Join recebe 2 Inputs
*/
SELECT * FROM Orders
 INNER JOIN Order_Details
    ON Orders.OrderID = Order_Details.OrderID


/*
  Operador de Concatenation pode receber n Inputs
  Para cada input os métodos Init() e GetNext() são 
  chamados concatenando todas as linhas dos inputs
*/
SET STATISTICS PROFILE ON
SELECT * FROM Products
UNION ALL
SELECT * FROM Products
UNION ALL
SELECT * FROM Products
UNION ALL
SELECT * FROM Products
/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Stream Aggregate
*/

/*
  Scalar Aggregations
  
  Agregações sem group by
*/
SET SHOWPLAN_ALL ON
GO
SELECT COUNT_BIG(*) FROM Orders
GO
SET SHOWPLAN_ALL OFF

/*
  Pergunta: Porque precisamos do Compute Scalar ?
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Resposta: Para converter o resultado do Stream Aggregate 
  para o DataType Int.
  A function Count() retornar um Value Inteiro.
  Para contar linhas maiores que 2147483647
  precisamos da Count_BIG().
*/
SET SHOWPLAN_ALL ON
GO
SELECT COUNT_BIG(*) FROM Orders
GO
SET SHOWPLAN_ALL OFF

/*
  Scalar Aggregations SEMPRE retornam um Value,
  mesmo se não existir nenhuma linha para contar
*/

DECLARE @Tab1 TABLE(ID Int)
SELECT MAX(ID) FROM @Tab1

DECLARE @Tab1 TABLE(ID Int)
SELECT * FROM Products
WHERE EXISTS(SELECT COUNT(ID) FROM @Tab1)

/*
  Stream Aggregations fazendo dois calculos
  
  Stream Aggregate calcula o COUNT e o SUM e depois o 
  Compute Scalar divide um Value pelo outro.
  Reparou no CASE para evitar uma divisão por zero?   
*/
SET SHOWPLAN_ALL ON
GO
SELECT AVG(Value) FROM Orders
GO
SET SHOWPLAN_ALL OFF


/*
  Nota: Datatype do AVG é o mesmo que o da expressão.
*/
SELECT AVG(Quantity), AVG(CONVERT(Numeric(18,2),Quantity)) 
  FROM Order_Details
  
  
/*
  Group Aggregations
  Aggregações com a clausula GROUP BY
*/
IF EXISTS(SELECT * FROM sysindexes WHERE name = 'ix_CustomerID' and id = OBJECT_ID('Orders'))
  DROP INDEX ix_CustomerID ON Orders
GO
CREATE INDEX ix_CustomerID ON Orders(CustomerID) INCLUDE(Value)
GO

/*
  Lê os dados na ordem desejada e vai somando os Valuees
*/
-- Retornar soma de todos os Orders por cliente
SELECT CustomerID,
       SUM(Value) AS Value
  FROM Orders
 GROUP BY CustomerID
GO

/*
  Nota: Mito sobre a ordem dos dados no group by
*/

/*
  Nota: "34.7 - QO Bug, Stream Aggregate.sql"
*/
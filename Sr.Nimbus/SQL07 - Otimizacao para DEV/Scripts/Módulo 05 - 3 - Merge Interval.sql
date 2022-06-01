/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO
IF EXISTS(SELECT * FROM sysindexes WHERE name ='ix_CustomerID' and id = object_id('Orders'))
  DROP INDEX ix_CustomerID ON Orders
GO
CREATE NONCLUSTERED INDEX ix_CustomerID ON Orders(CustomerID) INCLUDE (Value)
GO
IF EXISTS(SELECT * FROM sysindexes WHERE name ='ix_Data' and id = object_id('Orders'))
  DROP INDEX ix_Data ON Orders
GO
CREATE NONCLUSTERED INDEX ix_Data ON Orders(OrderDate) INCLUDE (Value)
GO


/*
  Selecionar o total de vendas de 4 Customers.
  Olhar no plano que os 4 ids são aplicados como 
  predicates na tabela de Orders
*/
SELECT SUM(Value) AS Val
  FROM Orders
 WHERE CustomerID IN (1,2,3,4)
GO

/*
  E se eu usar variáveis?
  O SQL utiliza o MergeInterval + alguns compute scalar internos para 
  remover as duplicidades e possíveis overlaps (sobreposições)
*/
DECLARE @v1 Int = 1, 
        @v2 Int = 2,
        @v3 Int = 3, 
        @v4 Int = 4
 
SELECT SUM(Value) AS Val
  FROM Orders
 WHERE CustomerID IN (@v1, @v2, @v3, @v4)
GO

/*
  Repare que quando especificamos o Value duplicado(ID "1" duas vezes)
  O SQL remove a duplicidade do filtro
*/
SELECT SUM(Value) AS Val
  FROM Orders
 WHERE CustomerID IN (1,1,3,4)
GO


/*
  O merge interval fica interessante quando temos o overlap
  Troca o 10-25 e 20-30 por 10-30, evitando que o range
  entre 20 e 25 seja lido em duplicidade
*/
DECLARE @v_a1 Int = 10, 
        @v_b1 Int = 20,
        @v_a2 Int = 25, 
        @v_b2 Int = 30
 
SELECT SUM(Value) AS Val
  FROM Orders
 WHERE CustomerID BETWEEN @v_a1 AND @v_a2
    OR CustomerID BETWEEN @v_b1 AND @v_b2
/*
  Sr.Nimbus - T-SQL Expert
        Query Tuning 
         Exercícios
  http://www.srnimbus.com.br
*/

----------------------------------------
--------- Qtde de dias sem vendas ------
----------------------------------------

/*
  Escreva uma consulta que retorne todos os pedidos
  e quantos dias se passaram desde a última venda efetuada
  por cliente

  Banco: NorthWind
  Tabela: Orders

  Obs.: Pode ser utilizado recursos do SQL Server 2012
  Bonus: Escrever consulta que rode no SQL2005
*/

-- Resultado esperado:
/*
  CustomerID  orderdate               orderid     dias desde a última compra
  ----------- ----------------------- ----------- ---------------------
  1           1997-08-25 00:00:00.000 10643       NULL
  1           1997-10-03 00:00:00.000 10692       39
  1           1997-10-13 00:00:00.000 10702       10
  1           1998-01-15 00:00:00.000 10835       94
*/

-- Resposta

SELECT O.CustomerID,
       O.orderdate,
       O.orderid,
       DATEDIFF(day, (SELECT TOP (1)
                             I.orderdate
                        FROM Orders AS I
                       WHERE I.CustomerID = O.CustomerID
                         AND I.orderdate < O.orderdate
                       ORDER BY orderdate DESC,
                                orderid DESC), O.orderdate) AS "dias desde a última compra"
  FROM Orders AS O
 ORDER BY O.CustomerID, O.OrderDate
GO
-- SQL2012
SELECT CustomerID, 
       orderdate, 
       orderid,
       DATEDIFF(day, LAG(orderdate) -- Como retornar 0 no lugar de NULL?
                     OVER(PARTITION BY CustomerID 
                          ORDER BY orderdate, orderid), orderdate) AS "dias desde a última compra"
  FROM Orders
 ORDER BY CustomerID, OrderDate
GO
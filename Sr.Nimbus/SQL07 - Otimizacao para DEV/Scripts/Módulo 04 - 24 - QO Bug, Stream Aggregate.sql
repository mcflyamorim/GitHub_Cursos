/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Erro com Scalar Aggregations que tem que controlar o retorno do 
  NULL quando nenhuma linha é retornada
*/

-- Retornar NULL
SELECT SUM(Value) AS Value
  FROM OrdersBig
 WHERE 1=0
GO

-- Retornar soma de todos os Orders
SELECT SUM(Value) AS Value
  FROM OrdersBig
/*
  Stream Aggregate:
  [Expr1004] = Scalar Operator(Count(*)); 
  [Expr1005] = Scalar Operator(SUM([NorthWind].[dbo].[Orders].[Value]))
*/


-- Teste com query com problema
SET STATISTICS TIME ON
SELECT SUM(CASE
             WHEN Value BETWEEN 0 AND 10000 THEN Value / 1.10 -- Aplica 10% desconto
             WHEN Value >= 10001 THEN Value / 1.05 -- Aplica 05% desconto
             ELSE Value
           END) AS Value
  FROM OrdersBig
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS TIME OFF
GO
/*
  Stream Aggregate:
  [Expr1005] = Scalar Operator(COUNT_BIG([Expr1004])); 
  [Expr1006] = Scalar Operator(SUM([Expr1004]))
*/

SET STATISTICS TIME ON
SELECT SUM(Expr) AS Value
  FROM OrdersBig
 OUTER APPLY (SELECT CASE
                       WHEN Value BETWEEN 0 AND 10000 THEN Value / 1.10 -- Aplica 10% desconto
                       WHEN Value >= 10001 THEN Value / 1.05 -- Aplica 05% desconto
                       ELSE Value
                     END) AS Tab(Expr)
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS TIME OFF


-- Related Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/636382/scalar-expression-evaluated-twice-with-sum-aggregate
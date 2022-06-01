/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE AdventureWorks2008R2
GO

-- Query abaixo faz o scan e depois aplica um filtro
SELECT SalesOrderID, SalesOrderNumber
  FROM Sales.SalesOrderHeader
 WHERE OrderDate = '20010702'
GO

-- Query abaixo com o HINT para usar o mesmo índice da query acima
-- faz o filtro como predicate direto na leitura do índice
SELECT SalesOrderID, SalesOrderNumber
  FROM Sales.SalesOrderHeader WITH(INDEX([PK_SalesOrderHeader_SalesOrderID]))
 WHERE OrderDate = '20010702'
GO

/*
  O problema só acontece com tabelas com ComputedColumns.
  As colunas calculadas estão impedindo o uso da otimização que
  joga o filtro dos dados para o Engine do SQL enquanto ele está
  lendo os dados de memória/disco.
  Forçando o índice o SQL usa esta regra chamada SelToTrivialFilter
*/

-- Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/495862/query-optimizer-generates-incorrect-plan-with-a-deffered-filter-operator
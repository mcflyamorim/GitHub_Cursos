/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

-- Deixar somente 10 Customers com Cidade cadastrada
UPDATE Customers SET ID_Cidade = NULL
WHERE CustomerID > 10
GO

-- Criar um índice por ID_Cidade na tabela de Customers
CREATE INDEX ix ON Customers (ID_Cidade) INCLUDE(ContactName)
GO

/* 
  Query 1: Selecionar todos os Orders de Customers com Cidade cadastrada 
  (WHERE ID_Cidade IS NOT NULL)
  Query bem otimizada fazendo um seek em Customers.ix usando o SeekPredicate "IsNotNull"
  Optimization Level = FULL
*/
SELECT Orders.OrderID, Customers.ContactName, Cidades.ContactName
  FROM Customers
 INNER JOIN Orders
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Cidades
    ON Customers.ID_Cidade = Cidades.ID
 WHERE Customers.ID_Cidade IS NOT NULL
GO

/* 
  Query 2: Exatamente a mesma consulta que a Query 1, 
  porém agora estou usando o Hint WITH(RECOMPILE)
  Plano pior comparado ao primeiro
  Obs.: No SQL 2005 o QO gera o mesmo plano que o a Query 1
*/
SELECT Orders.OrderID, Customers.ContactName, Cidades.ContactName
  FROM Customers
 INNER JOIN Orders
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Cidades
    ON Customers.ID_Cidade = Cidades.ID
 WHERE Customers.ID_Cidade IS NOT NULL
OPTION (RECOMPILE)
GO

/*
  Query 3: Porque não fez o filtro na tabela de Customers aqui?
  Só por conta do LEFT OUTER JOIN?
  O QO deveria ter gerado um plano fazendo o Seek em Customers.ix,
  fazer o join com a tabela de Cidades, e depois o Outer join com a 
  tabela de Orders.
*/ 
SELECT Orders.OrderID, Customers.ContactName, Cidades.ContactName
  FROM Customers WITH(FORCESEEK)
 INNER JOIN Cidades 
    ON Customers.ID_Cidade = Cidades.ID
  LEFT OUTER JOIN Orders
    ON Orders.CustomerID = Customers.CustomerID
 WHERE Customers.ID_Cidade IS NOT NULL
 OPTION (RECOMPILE)
GO

-- Como resolver o problema ?

/*
  Alternativa 1:fazer o filtro em uma consulta derivada.
*/ 
SELECT Orders.OrderID, Tab.ContactName, Cidades.ContactName
  FROM (SELECT CustomerID, ID_Cidade, ContactName
          FROM Customers 
         WHERE Customers.ID_Cidade IS NOT NULL) AS Tab
 INNER JOIN Cidades
    ON Tab.ID_Cidade = Cidades.ID
  LEFT OUTER JOIN Orders
    ON Orders.CustomerID = Tab.CustomerID
GO

/*
  Alternativa 2: Forçar o Seek usando o hint FORCESEEK (somente SQL2008)
*/ 
SELECT Orders.OrderID, Customers.ContactName, Cidades.ContactName
  FROM Customers WITH(FORCESEEK)
 INNER JOIN Cidades
    ON Customers.ID_Cidade = Cidades.ID
  LEFT OUTER JOIN Orders
    ON Orders.CustomerID = Customers.CustomerID
 WHERE Customers.ID_Cidade IS NOT NULL
GO

/*
  Alternativa 3: Usar o ISNULL na coluna Cidade
  ISNULL Não é SARGable, mas o QO o torna SARGable
  trocando o filtro pela expressão:
  "ID_Cidade < -1 AND ID_Cidade > -1"
*/ 
SELECT Orders.OrderID, Customers.ContactName, Cidades.ContactName
  FROM Customers
 INNER JOIN Cidades
    ON Customers.ID_Cidade = Cidades.ID
  LEFT OUTER JOIN Orders
    ON Orders.CustomerID = Customers.CustomerID
 WHERE ISNULL(Customers.ID_Cidade,-1) <> -1
GO


-- Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/587729/query-optimizer-create-a-bad-plan-when-is-not-null-predicate-is-used#details
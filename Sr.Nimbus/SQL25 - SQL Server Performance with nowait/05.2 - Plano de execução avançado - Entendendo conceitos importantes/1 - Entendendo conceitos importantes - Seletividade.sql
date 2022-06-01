/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Quando o Otimizador de consultas pode confiar na seletividade de uma coluna
*/

-- Desligar a criação das estatísticas automaticamente 
-- para simular o problema
ALTER DATABASE NorthWind SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT
GO

-- SQL Pode confiar que SEMPRE somente 1 cliente será retornado
-- pois CustomerID é PK da tabela
SELECT * 
  FROM Customers
 WHERE CustomerID = 1
GO

--DROP INDEX Customers.ix_ContactName
--DROP STATISTICS Customers.Stats_ContactName

-- Criar índice único
-- DROP INDEX ix_Unique_ContactName ON Customers
CREATE UNIQUE INDEX ix_Unique_ContactName ON Customers(ContactName)

-- Estimativa esta perfeita com o índice único
SELECT *
  FROM Customers
 WHERE ContactName = 'Janine Labrune'
 
-- Evitando uma agregação
-- Repare que o distinct é ignorado
SELECT DISTINCT ContactName
  FROM Customers
GO

-- Evitando uma agregação 2
SELECT Customers.ContactName,
       SUM(Orders.Value) AS Total_Venda
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
GO

-- Evitando uma validação pelo operador Assert
SELECT (SELECT ContactName 
          FROM Customers 
         WHERE ContactName = 'Janine Labrune') AS ContactName,
       *
  FROM Orders
GO

-- Voltar o banco ao normal
ALTER DATABASE NorthWind SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT
GO
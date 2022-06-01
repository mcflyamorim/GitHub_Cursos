/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Top N Sort
-- Até 100 linhas algoritmo otimizado para retornar n linhas rapidamente
SELECT TOP 100
       CustomerID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Variável não utiliza "Top N SORT"
-- TOP N Sort SEMPRE utiliza algoritmo não otimizado para poucas linhas (algoritmo padrao)
-- Plano abaixo gera SortWarning
DECLARE @i Int = 100
SELECT TOP (@i)
       CustomerID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1)
GO

-- "Top N SORT"
-- TOP N Sort utilizando algoritmo padrao, query abaixo gera sort warning
SELECT TOP 101
       CustomerID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO



-- Resposta: Algoritmo de TOP N Sort é diferente para valores
-- maiores que 100.

-- Alternativa
-- Minimizar a quantidade de bytes que serão processados pelo operador de sort
SELECT TOP 101
       Tab1.CustomerID,
       CustomersBig.CompanyName,
       CustomersBig.ContactName,
       Tab1.Col1,
       CustomersBig.Col2
  FROM CustomersBig
 INNER JOIN (SELECT TOP 101 CustomerID, Col1 
               FROM CustomersBig 
              ORDER BY Col1) AS Tab1
    ON CustomersBig.CustomerID = Tab1.CustomerID
 ORDER BY CustomersBig.Col1
OPTION (MAXDOP 1, RECOMPILE)
GO
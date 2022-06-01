-- Dicas do mestre Itzik em 
-- https://sqlperformance.com/2019/10/t-sql-queries/overlooked-t-sql-gems

USE Northwind
GO

-- Digamos que eu queira retornar uma coluna com tudo concatenado...
SELECT FirstName, LastName, City, Region, Country 
  FROM Employees
GO


-- Dá ruim por causa do NULL
SELECT FirstName, LastName, City, Region, Country, (FirstName + ',' + LastName + ',' + City + ',' + Region + ',' + Country )
  FROM Employees
GO

-- Nada que um ISNULL não resolva
SELECT FirstName, LastName, City, Region, Country, 
      ISNULL(FirstName, '') + ',' + ISNULL(LastName, '')  + ',' + ISNULL(City, '')  + ',' + ISNULL(Region, '')  + ',' + ISNULL(Country, '')  
  FROM Employees
GO
-- Mas daí ficou o ",," ai no meio... Ex: "Steven,Buchanan,London,,UK"

-- Aaa, mas daí taca um REPLACE e bla bla bla, já viu onde vamos chegar né... 


-- Ou, no SQL2017 podemos fazer assim: 
SELECT FirstName, LastName, City, Region, Country, 
      CONCAT_WS(',', FirstName, LastName, City, Region, Country)
  FROM Employees
GO

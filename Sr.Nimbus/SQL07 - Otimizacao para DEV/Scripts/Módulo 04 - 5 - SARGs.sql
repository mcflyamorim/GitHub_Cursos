/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  SARGs (Search Arguments)
*/

-- Criar índice único
-- DROP INDEX ix_ContactName ON CustomersBig
CREATE INDEX ix_ContactName ON CustomersBig(ContactName)
GO

/*
  Exemplo simples de consulta com cláusula sargable
*/
SELECT * FROM CustomersBig
WHERE ContactName = 'Fran Wilson 0DD1DC54'

/*
  Consultas não sargable
*/

SELECT * FROM CustomersBig
WHERE ContactName Like '%Fran Wilson 0DD1DC54%'
GO

SELECT * FROM CustomersBig
WHERE ContactName = 'Fran Wilson 0DD1DC54' OR CityID = 10
GO

-- Consulta abaixo PODE não ser Sargable, depende de onde o SQL irá
-- efetuar a conversão da coluna
SELECT * FROM CustomersBig
 WHERE ContactName = N'Fran Wilson 0DD1DC54'
OPTION (RECOMPILE)
GO

SELECT * FROM CustomersBig
WHERE ContactName COLLATE Latin1_General_100_CI_AI = 'Fran Wilson 0DD1DC54'
GO

CREATE INDEX ix_OrderDate ON Orders(OrderDate)
GO
SELECT * FROM Orders
WHERE CONVERT(VARCHAR(8), OrderDate, 112) = '19960704'
-- Trocar por
SELECT * FROM Orders
  WHERE OrderDate >= '19960704' AND OrderDate < DateAdd(Day, 1, '19960704')


SELECT * FROM CustomersBig
WHERE LEFT(ContactName,1) = 'X'
-- Trocar por
SELECT * FROM CustomersBig
WHERE ContactName LIKE 'X%'


/*
  Query Optimizer tornando uma expressão Sargable
*/
-- Changing <> to < AND >
SELECT ContactName 
  FROM CustomersBig
 WHERE ContactName <> 'Fran Wilson 0DD1DC54'
OPTION (RECOMPILE)

--DROP INDEX ix_CityID ON CustomersBig
CREATE INDEX ix_CityID ON CustomersBig (CityID) INCLUDE(ContactName)
GO
-- Changing ISNULL to < AND > -1
SELECT Orders.OrderID, CustomersBig.ContactName, Cities.CityName
  FROM CustomersBig
 INNER JOIN Cities
    ON CustomersBig.CityID = Cities.CityID
  LEFT OUTER JOIN Orders
    ON Orders.CustomerID = CustomersBig.CustomerID
 WHERE ISNULL(CustomersBig.CityID,-1) <> -1
GO

-- Removing hour from a datetime. QO uses GetRangeThroughConvert
SELECT * FROM Orders
WHERE CONVERT(Date, OrderDate) = '19960704'
GO

-- QO uses Merge Interval
DECLARE @v1 Int, @v2 Int
SELECT * FROM CustomersBig
WHERE CustomerID IN (@v1, @v2)

-- QO IN more than 64 values
-- Seek
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
GO

-- ConstantScan
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,
                      11,12,13,14,15,16,17,18,19,20,
                      21,22,23,24,25,26,27,28,29,30,
                      31,32,33,34,35,36,37,38,39,40,
                      41,42,43,44,45,46,47,48,49,50,
                      51,52,53,54,55,56,57,58,59,60,
                      61,62,63,64,65)
GO
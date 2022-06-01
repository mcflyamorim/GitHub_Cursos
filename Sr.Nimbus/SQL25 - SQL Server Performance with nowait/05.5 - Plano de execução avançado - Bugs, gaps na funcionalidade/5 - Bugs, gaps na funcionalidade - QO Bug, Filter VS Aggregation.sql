/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/




/*
  Overview SQL Server não deveria aplicar um filtro de like depois da agregação, 
  pois a lógica do like colide com a lógica de macthing da aggregação ...
*/


USE Northwind
GO
-- Fool QO to consider index
UPDATE STATISTICS Orders WITH ROWCOUNT = 99999, PAGECOUNT = 50000
GO
-- Creating the index on ShipCountry
CREATE INDEX ixShipCountry ON Orders(ShipCountry)
GO

-- Updating one row to Brazil+OneSpace
UPDATE Orders SET ShipCountry = 'Brazil '
WHERE OrderID = 10248
GO

-- Because like consider spaces it counts just one order
-- does the >= and <= to use the index
SELECT ShipCountry, COUNT(OrderID) AS cnt
  FROM Orders
 WHERE ShipCountry like 'Brazil '
 GROUP BY ShipCountry
GO
/*
|--Compute Scalar(DEFINE:([Expr1003]=CONVERT_IMPLICIT(int,[Expr1006],0)))
     |--Stream Aggregate(DEFINE:([Expr1006]=Count(*), [Northwind].[dbo].[Orders].[ShipCountry]=ANY([Northwind].[dbo].[Orders].[ShipCountry])))
          |--Index Seek(OBJECT:([Northwind].[dbo].[Orders].[ixShipCountry]), SEEK:([Northwind].[dbo].[Orders].[ShipCountry] >= 'Brazil ' AND [Northwind].[dbo].[Orders].[ShipCountry] <= 'Brazil '),  WHERE:([Northwind].[dbo].[Orders].[ShipCountry] like 'Brazil ') ORDERED FORWARD)
*/
/* Results
------------------------
ShipCountry     cnt
--------------- --------
Brazil          1
*/

IF OBJECT_ID('vw_View', 'v') is not null
  DROP VIEW vw_View
GO
CREATE VIEW vw_View
AS
SELECT ShipCountry, COUNT(OrderID) AS cnt
  FROM Orders
 GROUP BY ShipCountry
GO

-- Even it is showing the index seek, the filter is executed in the filter operator
-- the aggregate is pushed down to a filter after the aggregation... and this optimization 
-- it's against the rule of a view/CTE works like a query
SELECT * FROM vw_View
 WHERE ShipCountry like 'Brazil '

GO
/*
|--Filter(WHERE:([Northwind].[dbo].[Orders].[ShipCountry] like 'Brazil '))
     |--Compute Scalar(DEFINE:([Expr1003]=CONVERT_IMPLICIT(int,[Expr1006],0)))
          |--Stream Aggregate(DEFINE:([Expr1006]=Count(*), [Northwind].[dbo].[Orders].[ShipCountry]=ANY([Northwind].[dbo].[Orders].[ShipCountry])))
               |--Index Seek(OBJECT:([Northwind].[dbo].[Orders].[ixShipCountry]), SEEK:([Northwind].[dbo].[Orders].[ShipCountry]='Brazil ') ORDERED FORWARD)
*/
/* Results
------------------------
ShipCountry     cnt
--------------- --------
Brazil          84
*/

-- A CTE as the same problem on push down the predicate after the aggregation
WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM Orders
   GROUP BY ShipCountry
)

SELECT * FROM CTE_1
 WHERE ShipCountry like 'Brazil '
 
-- Note: SQL2005 does a Scan in the index, not a seek

-- Resposta:
-- The rules for matching a group and filtering via like are different

 
-- Comentário do Simon Sabin
/*
  Whats odd is the way that grouping groups values and then present values.
  It is grouping all Brazils irrespective of trailing spaces, but it uses one of them 
  (probably the first) as the representation to return to the client. This can be seen by running the following
  The top tricks the order of the values being grouped. 
  As the Briazil with the space isn’t first the group is 
  returned without the space at the end. (the ‘s’ is just to show the space)
*/
WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM (select top 1000 * from Orders order by OrderID desc) Orders
   GROUP BY ShipCountry
)

SELECT ShipCountry +'s', cnt
  FROM CTE_1
WHERE ShipCountry like 'Brazil '
go

WITH CTE_1
AS
(
  SELECT ShipCountry, COUNT(OrderID) AS cnt
    FROM (select top 1000 * from Orders order by OrderID asc) Orders
   GROUP BY ShipCountry
)

SELECT ShipCountry +'s', cnt
  FROM CTE_1
WHERE ShipCountry like 'Brazil '



-- New sample 
IF OBJECT_ID('TabTest') IS NOT NULL
  DROP TABLE TabTest
GO

CREATE TABLE TabTest(Col1 varchar(30) NOT NULL, Col2 int NOT NULL, Col3 char(200))
GO

INSERT INTO TabTest VALUES ('abc ', 500, '')
INSERT INTO TabTest VALUES ('abc ', 500, '')
INSERT INTO TabTest VALUES ('abc', 333, '')
INSERT INTO TabTest VALUES ('xxx', 999, '')
GO

CREATE INDEX idx ON TabTest (Col1, Col2)
GO

drop index idx ON TabTest

SELECT *
FROM TabTest
WHERE Col1 LIKE 'abc '
GO

SELECT Col1, SUM(Col2)
  FROM TabTest
 WHERE Col1 LIKE 'abc '
 GROUP BY Col1
GO
 
;WITH CTE_1 (Col1, Col2)
AS
(
  SELECT Col1, SUM(Col2)
    FROM TabTest
   GROUP BY Col1
)
SELECT * FROM CTE_1
WHERE Col1 LIKE 'abc '
GO

IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
CREATE VIEW vw_test
AS
  SELECT Col1, SUM(Col2) AS Col2
    FROM TabTest
   GROUP BY Col1
GO

SELECT * FROM vw_test
GO

SELECT * FROM vw_test
WHERE Col1 LIKE 'abc '
GO

SELECT * FROM vw_test
WHERE Col1 LIKE 'abc '
GO
CREATE INDEX idx ON TabTest (Col1, Col2)
GO
SELECT * FROM vw_test
WHERE Col1 LIKE 'abc '
GO

-- exemplo do Erland Sommarskog
use tempdb
GO
IF OBJECT_ID('TabTest') IS NOT NULL
  DROP TABLE TabTest
GO
CREATE TABLE TabTest (Col1 varchar(30) COLLATE Latin1_General_CI_AS NOT NULL,
                      Col2 int NOT NULL, 
                      Col3 char(200))
GO
INSERT INTO TabTest VALUES ('ABC', 500, '')
INSERT INTO TabTest VALUES ('abC', 500, '')
INSERT INTO TabTest VALUES ('abc', 333, '')
INSERT INTO TabTest VALUES ('xxx', 999, '')
GO

IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
CREATE VIEW vw_test 
AS
SELECT Col1, SUM(Col2) AS Col2
  FROM TabTest
 GROUP BY Col1
GO

SELECT * FROM vw_test
 WHERE Col1 COLLATE Latin1_General_CS_AS = 'abc'
GO

IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
CREATE VIEW vw_test 
AS
SELECT Col1, SUM(Col2) AS Col2
  FROM (SELECT TOP 1000 * FROM TabTest ORDER BY Col2 ASC) AS Tab
 GROUP BY Col1
GO

SELECT * FROM vw_test
 WHERE Col1 COLLATE Latin1_General_CS_AS = 'abc'
GO

IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
CREATE VIEW vw_test 
AS
SELECT Col1, SUM(Col2) AS Col2
  FROM (SELECT TOP 1000 * FROM TabTest ORDER BY Col2 DESC) AS Tab
 GROUP BY Col1
GO

SELECT * FROM vw_test
 WHERE Col1 COLLATE Latin1_General_CS_AS = 'abc'
GO


-- Solução
IF OBJECT_ID('vw_test') IS NOT NULL
  DROP VIEW vw_test
GO
CREATE VIEW vw_test 
AS
SELECT Col1 COLLATE Latin1_General_CS_AS AS Col1, SUM(Col2) AS Col2
  FROM TabTest
 GROUP BY Col1 COLLATE Latin1_General_CS_AS
GO

SELECT * FROM vw_test
 WHERE Col1 COLLATE Latin1_General_CS_AS = 'abc'
GO


-- INF: How SQL Server Compares Strings with Trailing Spaces
-- http://support.microsoft.com/kb/316626

IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #tmp
GO
CREATE TABLE #tmp (c1 varchar(10))
GO
INSERT INTO #tmp VALUES ('abc ')
INSERT INTO #tmp VALUES ('abc')
GO
SELECT DATALENGTH(c1) as 'EqualWithSpace', * FROM #tmp WHERE c1 = 'abc '
SELECT DATALENGTH(c1) as 'EqualNoSpace  ', * FROM #tmp WHERE c1 = 'abc'
SELECT DATALENGTH(c1) as 'GTWithSpace   ', * FROM #tmp WHERE c1 > 'ab '
SELECT DATALENGTH(c1) as 'GTNoSpace     ', * FROM #tmp WHERE c1 > 'ab'
SELECT DATALENGTH(c1) as 'LTWithSpace   ', * FROM #tmp WHERE c1 < 'abd '
SELECT DATALENGTH(c1) as 'LTNoSpace     ', * FROM #tmp WHERE c1 < 'abd'
SELECT DATALENGTH(c1) as 'LikeWithSpace ', * FROM #tmp WHERE c1 LIKE 'abc %'
SELECT DATALENGTH(c1) as 'LikeNoSpace   ', * FROM #tmp WHERE c1 LIKE 'abc%'
GO
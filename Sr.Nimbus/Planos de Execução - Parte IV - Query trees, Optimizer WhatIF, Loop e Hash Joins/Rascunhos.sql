USE Northwind
GO

ALTER VIEW vw_Retorna_CustomersComVendas
WITH SCHEMABINDING
AS
SELECT c.CustomerID, c.ContactName, c.City, R.RegionDescription
  FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Region AS R 
    ON R.RegionDescription = c.Region
 WHERE EXISTS(SELECT O.OrderID 
                FROM dbo.Orders AS O 
               WHERE O.CustomerID = C.CustomerID)
GO

-- Para gerar "project remove"
CREATE UNIQUE INDEX ixCompanyName ON Shippers (CompanyName)
GO
-- Para gerar "simplify"
ALTER TABLE Orders ALTER COLUMN OrderDate DateTime NOT NULL
ALTER TABLE Orders WITH CHECK ADD CONSTRAINT ck_ValidaOrderDate CHECK (OrderDate > '19000101')
GO
-- Para gerar "join collapse"
ALTER TABLE Orders ALTER COLUMN ShipVia Int NOT NULL
ALTER TABLE Orders DROP CONSTRAINT FK_Orders_Shippers
GO
ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Shippers
 FOREIGN KEY (ShipVia) REFERENCES  Shippers(ShipperID)
GO

SELECT v2.ContactName,
       Col1 = (SELECT FirstName FROM Employees AS E 
                WHERE E.EmployeeID = O.EmployeeID),
       Col2 = Convert(VarChar(10), O.OrderDate, 112),
       o.Freight
  FROM (SELECT DISTINCT v1.CustomerID, v1.ContactName, V1.City
          FROM vw_Retorna_CustomersComVendas v1) as v2
 INNER JOIN Orders AS O
    ON O.CustomerID = v2.CustomerID
 INNER JOIN Order_Details AS od
    ON od.OrderID = O.OrderID
 INNER JOIN Shippers s
    ON s.ShipperID = O.ShipVia
 OUTER APPLY (SELECT ShipperID FROM Shippers AS S 
               WHERE S.CompanyName = 'Federal Shipping') AS Outer1
 WHERE v2.City = REPLACE('xxrlin', 'xx', 'Be')
   AND o.Freight > 94 + 5
   AND (NOT(od.Quantity IN(99,99)) OR NOT(od.Quantity IN(99)))
   AND o.OrderDate > '19000101'
   AND O.EmployeeID = 222
   AND od.Quantity = 35
option(
recompile
,querytraceon 3604 -- redirect output to console
,querytraceon 2318 -- opt phases (heuristic join reorder)
,querytraceon 2372 -- memory before/after optimization step
,querytraceon 8612 -- add arguements to the trees
,querytraceon 8605 -- converted tree
,querytraceon 8606 -- simplification trees
,querytraceon 8675 -- optimization step end times and other
--,querytraceon 2373 -- memory before/after property derive (verbose output)
)




SELECT C.ContactName, 
       COUNT_BIG(*) AS QtOrders
  FROM Orders as O
 INNER JOIN Customers AS C
    ON C.CustomerID = O.CustomerID
 WHERE C.City = 'Berlin'
 GROUP BY C.ContactName
option(
recompile
,querytraceon 3604 -- redirect output to console
,querytraceon 2318 -- opt phases (heuristic join reorder)
,querytraceon 2372 -- memory before/after optimization step
,querytraceon 8612 -- add arguements to the trees
,querytraceon 8605 -- converted tree
,querytraceon 8606 -- simplification trees
,querytraceon 8675 -- optimization step end times and other
--,querytraceon 2373 -- memory before/after property derive (verbose output)
)




SELECT *
  FROM OrdersBig
 WHERE NOT(CustomerID NOT IN(99, 99, 99))
option(
recompile
,querytraceon 3604 -- redirect output to console
,querytraceon 2318 -- opt phases (heuristic join reorder)
,querytraceon 2372 -- memory before/after optimization step
,querytraceon 8612 -- add arguements to the trees
,querytraceon 8605 -- converted tree
,querytraceon 8606 -- simplification trees
,querytraceon 8675 -- optimization step end times and other
--,querytraceon 2373 -- memory before/after property derive (verbose output)
)

use Northwind
GO



IF OBJECT_ID('tempdb.dbo.#Snapshot') IS NOT NULL
  DROP TABLE #Snapshot
GO
SELECT *
  INTO #Snapshot
  FROM sys.dm_exec_query_transformation_stats
GO

/* COMANDO SQL */
SELECT CustomersBig.ContactName, 
       SUM(Value)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Fab%'
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff GbAggToHS, QueryRuleOff JNtoNL)

GO
-- Results
SELECT QTS.name,
       QTS.promised - S.promised AS promised,
       CASE 
         WHEN QTS.promised = S.promised THEN 0
         ELSE (QTS.promise_total - S.promise_total)/(QTS.promised - S.promised)
       END promise_value_avg,
       QTS.built_substitute - S.built_substitute AS built_substitute,
       QTS.succeeded - S.succeeded AS succeeded
  FROM #Snapshot S
 INNER JOIN sys.dm_exec_query_transformation_stats QTS
    ON QTS.name = S.name
 WHERE QTS.succeeded <> S.succeeded
 ORDER BY promise_value_avg DESC
OPTION  (KEEPFIXED PLAN);
GO


DBCC FREEPROCCACHE()
GO
SELECT *
  FROM OrdersBig
 WHERE Value <= CONVERT(tinyInt, 256)
GO

DBCC FREEPROCCACHE()
GO
SELECT *
  FROM OrdersBig
 WHERE Value <= CONVERT(tinyInt, 255)

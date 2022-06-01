USE Northwind
GO

IF OBJECT_ID('OrdersToIgnore1') IS NOT NULL
  DROP TABLE OrdersToIgnore1
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(1000), NEWID()) AS Col2
  INTO OrdersToIgnore1
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
ALTER TABLE OrdersToIgnore1 ADD CONSTRAINT xpk_OrdersToIgnore1 PRIMARY KEY(OrderID)
GO
DELETE FROM OrdersToIgnore1
WHERE OrderID >= 1000000
GO
IF OBJECT_ID('OrdersToIgnore2') IS NOT NULL
  DROP TABLE OrdersToIgnore2
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(1), 'a') AS Col2
  INTO OrdersToIgnore2
  FROM Products A
 CROSS JOIN Products B CROSS JOIN Products C CROSS JOIN Products D
GO
ALTER TABLE OrdersToIgnore2 ADD CONSTRAINT xpk_OrdersToIgnore2 PRIMARY KEY(OrderID)
GO
DELETE FROM OrdersToIgnore2
WHERE OrderID >= 1000000
GO

-- 1145656 KB
sp_spaceused OrdersToIgnore1
GO
-- 54888 KB
sp_spaceused OrdersToIgnore2
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
SET STATISTICS IO, TIME ON
GO
SELECT * FROM OrdersBig
 WHERE NOT EXISTS(SELECT 1 
                    FROM OrdersToIgnore1
                   WHERE OrdersToIgnore1.OrderID = OrdersBig.OrderID)
   AND NOT EXISTS(SELECT 1 
                    FROM OrdersToIgnore2
                   WHERE OrdersToIgnore2.OrderID = OrdersBig.OrderID)
OPTION (RECOMPILE, MAXDOP 1)
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
SELECT * FROM OrdersBig
 WHERE NOT EXISTS(SELECT 1 
                    FROM OrdersToIgnore2
                   WHERE OrdersToIgnore2.OrderID = OrdersBig.OrderID)
   AND NOT EXISTS(SELECT 1 
                    FROM OrdersToIgnore1
                   WHERE OrdersToIgnore1.OrderID = OrdersBig.OrderID)
OPTION (RECOMPILE, MAXDOP 1)
GO
SET STATISTICS IO, TIME OFF
GO

-- Notice that QO KNOWS the second option has a lower cost, but still choosing for the bad plan :-( ... 
-- QO may not pick best order, but sometimes it does... whaaat? ... yes, you'l have to double check 
-- those plans for outer/anti-semi joins

-- Follow up reading... :
-- https://blogs.msdn.microsoft.com/conor_cunningham_msft/2010/04/23/conor-vs-left-outer-join-reordering/
-- https://blogs.msdn.microsoft.com/conor_cunningham_msft/2009/12/10/conor-vs-does-join-order-matter/
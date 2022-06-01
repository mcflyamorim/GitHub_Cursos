USE NorthWind
GO
SET NOCOUNT ON;
GO
IF OBJECT_ID('OrdersReallyBig') IS NOT NULL
  DROP TABLE OrdersReallyBig
GO
SELECT TOP 20000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate1,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate2,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate3,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value1,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value2,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value3
  INTO OrdersReallyBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersReallyBig ADD CONSTRAINT xpk_OrdersReallyBig PRIMARY KEY(OrderID)
GO



CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SELECT CustomersBig.ContactName,
       SUM(OrdersReallyBig.Value1) AS ValorTotal
  FROM OrdersReallyBig
 INNER JOIN CustomersBig
    ON OrdersReallyBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Carlos%'
   AND OrdersReallyBig.Value1 < 10
   AND OrdersReallyBig.Value2 BETWEEN 0 AND 900000
   AND OrdersReallyBig.Value3 BETWEEN 0 AND 900000
   AND OrdersReallyBig.OrderDate1 < '29990101'
 GROUP BY CustomersBig.ContactName
GO

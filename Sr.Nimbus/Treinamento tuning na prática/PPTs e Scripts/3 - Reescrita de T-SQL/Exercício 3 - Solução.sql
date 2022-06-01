USE Northwind
GO


CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
SELECT TOP 50000
       OrdersBig.OrderID,       
       OrdersBig.Value,
       CustomersBig.ContactName,
       ISNULL(CASE 
                WHEN OrdersBig.Value < 1 THEN Order_DetailsBig.Quantity
              END, 0) AS Qt
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 LEFT OUTER JOIN Order_DetailsBig
   ON Order_DetailsBig.OrderID = OrdersBig.OrderID
ORDER BY CustomersBig.ContactName
OPTION (MAXDOP 1)
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL
  DROP TABLE #tmp1

SELECT TOP 50000
       OrdersBig.OrderID,       
       OrdersBig.Value,
       CustomersBig.ContactName,
       CONVERT(INT, NULL) AS Qt
  INTO #TMP1
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
ORDER BY CustomersBig.ContactName
OPTION (MAXDOP 1)
UPDATE #tmp1 SET Qt = Order_DetailsBig.Quantity
FROM #tmp1
 LEFT OUTER JOIN Order_DetailsBig
   ON Order_DetailsBig.OrderID = #tmp1.OrderID
WHERE #tmp1.Value < 1

SELECT OrderID,
       Value,
       ContactName,
       ISNULL(Qt,0)
 FROM #tmp1
GO

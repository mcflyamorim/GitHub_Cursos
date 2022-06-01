USE Northwind
GO
IF OBJECT_ID('OrdersBigHistory') IS NOT NULL
  DROP TABLE OrdersBigHistory
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       ABS(CheckSUM(NEWID()) / 10000000) AS EmployeeID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(CHAR(1000), SUBSTRING(CONVERT(VarChar(250),NEWID()),1,20)) AS OrderNotes
  INTO OrdersBigHistory
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBigHistory ADD CONSTRAINT xpk_OrdersBigHistory PRIMARY KEY(OrderID)
GO
CREATE INDEX ixOrderDate ON OrdersBigHistory(OrderDate)
GO
CREATE INDEX ixEmployeeID ON OrdersBigHistory(EmployeeID)
GO
;WITH CTE
AS
(
  SELECT CONVERT(DATE, DATEADD(DAY, OrderID, CONVERT(Date, '15000101'))) AS Col1, OrderDate
    FROM OrdersBigHistory
)
UPDATE CTE SET OrderDate = Col1
GO


CHECKPOINT;DBCC DROPCLEANBUFFERS
GO
SELECT MIN(OrdersBigHistory.OrderID)
  FROM OrdersBigHistory
 WHERE OrdersBigHistory.OrderDate >= '20170101 00:00:00.000'
GO

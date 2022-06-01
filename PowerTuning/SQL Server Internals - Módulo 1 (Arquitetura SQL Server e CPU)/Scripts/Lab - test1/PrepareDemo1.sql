USE Northwind

IF OBJECT_ID('st_TestCPU') IS NOT NULL
  DROP PROC st_TestCPU

IF OBJECT_ID('OrdersBig1') IS NOT NULL
  DROP TABLE OrdersBig10, OrdersBig9, OrdersBig8, OrdersBig7, OrdersBig6, OrdersBig5, OrdersBig4, OrdersBig3, OrdersBig2, OrdersBig1

SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(CHAR(500), ISNULL(ABS(CONVERT(CHAR(1000), (CheckSUM(NEWID()) / 1000000))),0)) AS Col1
  INTO OrdersBig1
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D

ALTER TABLE OrdersBig1 ADD CONSTRAINT xpk_OrdersBig1 PRIMARY KEY(OrderID)

SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig2 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig3 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig4 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig5 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig6 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig7 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig8 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig9 FROM OrdersBig1
SELECT ISNULL(CONVERT(INT, OrderID),0) AS OrderID,CustomerID,OrderDate,Value INTO OrdersBig10 FROM OrdersBig1

ALTER TABLE OrdersBig2 ADD CONSTRAINT xpk_OrdersBig2 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig3 ADD CONSTRAINT xpk_OrdersBig3 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig4 ADD CONSTRAINT xpk_OrdersBig4 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig5 ADD CONSTRAINT xpk_OrdersBig5 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig6 ADD CONSTRAINT xpk_OrdersBig6 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig7 ADD CONSTRAINT xpk_OrdersBig7 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig8 ADD CONSTRAINT xpk_OrdersBig8 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig9 ADD CONSTRAINT xpk_OrdersBig9 PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig10 ADD CONSTRAINT xpk_OrdersBig10 PRIMARY KEY(OrderID)

IF OBJECT_ID('st_TestCPU', 'FN') IS NOT NULL
  DROP PROC st_TestCPU

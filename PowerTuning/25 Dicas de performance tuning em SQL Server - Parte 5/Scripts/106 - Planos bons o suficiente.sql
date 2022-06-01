---------------------------- WARNING ---------------- READ -----------------------------
---------------------------- WARNING ---------------- READ -----------------------------
----------------------------------------------------------------------------------------
-- PLEASE BEAR IN MIND THAT 8780 TRACE FLAG IS UNDOCUMENTED AND UNSUPPORTED,  ----------
-- AND SHOULD NOT BE USED ON A PRODUCTION ENVIRONMENT. ---------------------------------
-- YOU CAN USE THEM AS A WAY TO EXPLORE AND UNDERSTAND HOW THE QUERY OPTIMIZER WORKS. --
----------------------------------------------------------------------------------------
---------------------------- WARNING ---------------- READ -----------------------------
---------------------------- WARNING ---------------- READ -----------------------------

USE Northwind
GO

IF OBJECT_ID('OrdersBig1') IS NOT NULL
  DROP TABLE OrdersBig1
GO
CREATE TABLE [dbo].[OrdersBig1](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig1] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 18000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig1 ADD CONSTRAINT xpk_OrdersBig1 PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('OrdersBig2') IS NOT NULL
  DROP TABLE OrdersBig2
GO
CREATE TABLE [dbo].[OrdersBig2](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig2] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 18000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig2 ADD CONSTRAINT xpk_OrdersBig2 PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('OrdersBig3') IS NOT NULL
  DROP TABLE OrdersBig3
GO
CREATE TABLE [dbo].[OrdersBig3](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig3] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 18000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig3 ADD CONSTRAINT xpk_OrdersBig3 PRIMARY KEY(OrderID)
GO




IF OBJECT_ID('vw_1') IS NOT NULL
  DROP VIEW vw_1
GO
CREATE VIEW vw_1
AS
SELECT OrderID, CustomerID, OrderDate, Value FROM OrdersBig1
UNION ALL 
SELECT OrderID, CustomerID, OrderDate, Value FROM OrdersBig2
UNION ALL
SELECT OrderID, CustomerID, OrderDate, Value FROM OrdersBig3
GO

-- Plan scaning clustered index and aggregating MAX value...
SELECT MAX(OrderDate) 
  FROM vw_1
GO

-- BAD PLAN... How to improve it? ... 

-- Let's create some indexes to help it
CREATE INDEX ixOrderDate ON OrdersBig1 (OrderDate)
CREATE INDEX ixOrderDate ON OrdersBig2 (OrderDate)
CREATE INDEX ixOrderDate ON OrdersBig3 (OrderDate)
GO


-- Great, now, ROW GOAL optimization will help... right? ...


SET STATISTICS IO ON
-- Where is the TOP 1 + stream aggregate optimization? 
-- No ScalarGbAggToTop (change scalar MIN/MAX to gb over top) optimization
SELECT MAX(OrderDate) 
  FROM vw_1
OPTION (RECOMPILE)
GO

-- Plan is not expensive enough, no need to further optimization
-- Reason for early termination of statment = Good Enough Plan Found



-- What if we use TOP 1 OrderBy desc instead of MAX?
-- Better plan, less page reads...
-- Used UNIAtoMERGE rule to optimize the plan
SELECT TOP 1 OrderDate 
  FROM vw_1
 ORDER BY OrderDate DESC
OPTION (RECOMPILE)
GO


-- Back to the problem... 
-- Where did the QO stopped the exploration?
-- Check TF8675 result
SELECT MAX(OrderDate)
  FROM vw_1
OPTION (
RECOMPILE
,QueryTraceON 3604
,QueryTraceON 8675 -- show optimization stages
)
-- ^^^^^^^^^^^^^^^^^ --
-- Found a good plan on search(0) phase




-- What if we say skip search 0/TP Plan and explore search 1 and search 2?
-- Here it is ScalarGbAggToTop (GBAGG -> GBAGG on TOP)
SELECT MAX(OrderDate)
  FROM vw_1
OPTION (QueryTraceON 3604
--,QueryTraceON 8677 -- disable "search 1"/quickplan
,QueryTraceON 8750 -- disable search 0/TP Plan
,QueryTraceON 8675 -- show optimization stages
)



-- NOTE:

-- If you have MORE rows, it will have > cost and require more exploration, 
-- in this case there is no need to use TF8750...

-- Except if you are using SQL2008/2008R2 :-(
-- If this is the case, you'll need to use TF4199 
-- http://support.microsoft.com/kb/974006



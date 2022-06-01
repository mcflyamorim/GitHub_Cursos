USE NorthWind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 100000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- Comando pra ficar "gastando" CPU
SELECT ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000))),0)
GO

-- Proc para ler algo da tab OrdersBig
IF OBJECT_ID('st_SOS_SCHEDULER_YIELD') IS NOT NULL
  DROP PROC st_SOS_SCHEDULER_YIELD
GO
CREATE PROC st_SOS_SCHEDULER_YIELD
AS
BEGIN
  DECLARE @i INT, @y INT, @x INT, @counter INT = 1

  WHILE @counter <= 10
  BEGIN
    SET @i = ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000))),0)
    SET @y = @i + 1000
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
    SELECT TOP 1000 @x = OrderiD FROM OrdersBig
    WHERE OrderID BETWEEN @i AND @y

    SET @counter += 1;
  END
END
GO

-- Testar a proc
EXEC st_SOS_SCHEDULER_YIELD
GO









-- Recriar proc com NOLOCK
IF OBJECT_ID('st_SOS_SCHEDULER_YIELD') IS NOT NULL
  DROP PROC st_SOS_SCHEDULER_YIELD
GO
CREATE PROC st_SOS_SCHEDULER_YIELD
AS
BEGIN
  DECLARE @i INT, @y INT, @x INT, @counter INT = 1

  WHILE @counter <= 10
  BEGIN
    SET @i = ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000))),0)
    SET @y = @i + 1000
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

    SELECT TOP 1000 @x = OrderiD FROM OrdersBig WITH(NOLOCK)
    WHERE OrderID BETWEEN @i AND @y

    SET @counter += 1;
  END
END
GO

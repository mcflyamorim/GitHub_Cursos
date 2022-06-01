/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/




USE Northwind
GO

-- Preparar ambiente... Criar tabelas com 30 milhões de linhas...
-- 2 mins para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(INT, 1,1) AS OrderID,
       CONVERT(CHAR(500), SUBSTRING(CONVERT(Char(500),NEWID()),1,5)) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
OPTION (MAXDOP 1)
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
       IDENTITY(INT, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(CHAR(500), SUBSTRING(CONVERT(Char(500),NEWID()),1,5)) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
OPTION (MAXDOP 1)
GO

/*
  Hash Join
*/



-- Alternativa 3, alterar tamanho do Memory Grant Workspace
-- utilizando Resource Governor
ALTER WORKLOAD GROUP [default] WITH(request_max_memory_grant_percent=25)
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

-- In-Memory Hash Join
-- Build cria os buckets baseado em OrdersBig (menor tabela)
CHECKPOINT; DBCC DROPCLEANBUFFERS(); DBCC FREEPROCCACHE();
GO
-- Granted memory = 1904784 KB
DECLARE @i1 Int, @i2 varchar(500)
SELECT @i1 = Ordersbig.OrderID, @i2 = CustomersBig.CompanyName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.Col1 = OrdersBig.CustomerID
OPTION (HASH JOIN)
GO

-- Grace Hash Join
-- If the build input does not fit in memory, a hash join proceeds in several steps. 
-- This is known as a grace hash join.
DECLARE @i1 Int, @i2 varchar(500)
SELECT @i1 = Ordersbig.OrderID, @i2 = CustomersBig.CompanyName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.Col1 = OrdersBig.CustomerID
OPTION (MAXDOP 1, HASH JOIN, MAX_GRANT_PERCENT = 0.0)
GO

-- Gera Hash BailOut (vários hash recursions...)
DECLARE @i1 Int, @i2 varchar(500), @CustomerID INT = 100000000, @OrderID INT = 100000000
SELECT @i1 = Ordersbig.OrderID, @i2 = CustomersBig.CompanyName
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.Col1 = OrdersBig.CustomerID
 WHERE Ordersbig.OrderID <= @OrderID -- 100000000
  AND CustomersBig.CustomerID <= @CustomerID -- 100
OPTION (MAXDOP 1, HASH JOIN, OPTIMIZE FOR(@OrderID = 0, @CustomerID = 0))
GO

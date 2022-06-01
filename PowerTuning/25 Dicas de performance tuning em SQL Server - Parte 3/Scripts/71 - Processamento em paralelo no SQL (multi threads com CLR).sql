
-- Objetos CLR em Scritps\Outros\SqlClrLib
-- Compilar o arquivo Scritps\Outros\SqlClrLib\Deployment.sql


USE Northwind
GO
-- Preparar ambiente... 
-- Criando tabela de 10 milhões de linhas
-- 16 segundos para rodar...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 10000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('OrdersBigHistory') IS NOT NULL 
  DROP TABLE OrdersBigHistory
-- Criando tabela OrdersBigHistory
SELECT TOP 0 ISNULL(CONVERT(INT, OrderID),0) AS OrderID,
             CustomerID,
             OrderDate,
             Value
 INTO OrdersBigHistory 
 FROM OrdersBig
GO
ALTER TABLE OrdersBigHistory ADD CONSTRAINT xpk_OrdersBigHistory PRIMARY KEY(OrderID)
GO


-- Quanto tempo demora pra inserir? 
-- 18 segundos...
INSERT INTO Northwind.dbo.OrdersBigHistory (OrderID, CustomerID, OrderDate, Value)
SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig 
GO

TRUNCATE TABLE OrdersBigHistory
GO

-- E em paralelo? 
-- 6 segundos...


-- Preparando threads...

-- First you have to declare parallel block.
-- You can name it anyway you like. THIS IS A MUST
exec Northwind.dbo.Parallel_Declare 'Test_Insert_OrdersBigHistory'

-- optionally you can setup options for your block
EXEC Northwind.dbo.Parallel_SetOption_MaxThreads 64
EXEC Northwind.dbo.Parallel_SetOption_CommandTimeout 30


EXEC Northwind.dbo.Parallel_AddSql 'sql0', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 1 AND 1000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql2', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 1000001 AND 2000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql3', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 2000001 AND 3000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql4', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 3000001 AND 4000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql5', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 4000001 AND 5000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql6', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 5000001 AND 6000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql7', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 6000001 AND 7000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql8', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 7000001 AND 8000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql9', 'INSERT INTO Northwind.dbo.OrdersBigHistory  (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 8000001 AND 9000000'
EXEC Northwind.dbo.Parallel_AddSql 'sql10', 'INSERT INTO Northwind.dbo.OrdersBigHistory (OrderID, CustomerID, OrderDate, Value) SELECT OrderID, CustomerID, OrderDate, Value FROM Northwind.dbo.OrdersBig WHERE OrderID BETWEEN 9000001 AND 10000000'

DECLARE @RC int
exec @RC = Northwind.dbo.Parallel_execute
IF @RC != 0
BEGIN
    DECLARE @ErrorMessage varchar(MAX)
    SET @ErrorMessage = Northwind.dbo.Parallel_GetErrorMessage()
    RAISERROR(@ErrorMessage, 16, 1)
END

SELECT * FROM Northwind.dbo.parallel_GetExecutionResult()
GO


-- http://www.codeproject.com/Articles/29356/Asynchronous-T-SQL-Execution-Without-Service-Broke
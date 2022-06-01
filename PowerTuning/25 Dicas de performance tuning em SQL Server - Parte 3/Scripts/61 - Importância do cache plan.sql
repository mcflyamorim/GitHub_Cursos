USE Northwind
GO

IF OBJECT_ID('st_TestRecompile') IS NOT NULL
  DROP PROC st_TestRecompile
GO
-- Encapsular código em uma Procedure
CREATE PROC st_TestRecompile @ID Integer, 
                             @ID_Saida Integer OUTPUT
AS
   SELECT TOP 1 @ID_Saida = Orders.CustomerID
     FROM Orders
    INNER JOIN Customers
       ON Orders.CustomerID = Customers.CustomerID
    INNER JOIN Order_Details
       ON Orders.OrderID = Order_Details.OrderID
    WHERE Orders.OrderID = @ID
GO


-- Test Proc
DECLARE @i Int
EXEC st_TestRecompile @ID = 10248, @ID_Saida = @i OUT
SELECT @i


/*
  Executar a proc acima 100 mil vezes
*/
-- 1 segundo...
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 100000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT

  SET @i = @i + 1 
END 
GO

-- Verificar quantas vezes o plano da proc foi reutilizado
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan, *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c

IF OBJECT_ID('st_TestRecompile') IS NOT NULL
  DROP PROC st_TestRecompile
GO
-- Recriar a proc com option (recompile)
CREATE PROC st_TestRecompile @ID Integer, 
                             @ID_Saida Integer OUTPUT
AS
  SELECT TOP 1 @ID_Saida = Orders.CustomerID
    FROM Orders
   INNER JOIN Customers
      ON Orders.CustomerID = Customers.CustomerID
   INNER JOIN Order_Details
      ON Orders.OrderID = Order_Details.OrderID
   WHERE Orders.OrderID = @ID
  OPTION (RECOMPILE)
GO


/*
  Executar a mesma proc 100 mil vezes
  mas desta vez pedindo para recompilar o plano
*/
-- Ouch...
-- 2 mins e 51 segundos...
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 100000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT

  SET @i = @i + 1 
END 
GO
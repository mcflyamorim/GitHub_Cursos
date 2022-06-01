/*
  Sr.Nimbus - T-SQL Expert
         Módulo 11
  http://www.srnimbus.com.br
*/

USE Northwind
GO


--------------------------------
-----  Stored Procedures -------
--------------------------------


--------------------------------
----- Parameter Sniffing -------
--------------------------------

-- Preparando o ambiente
SET NOCOUNT ON;
IF OBJECT_ID('TabTeste') IS NOT NULL
  DROP TABLE TabTeste
GO
CREATE TABLE TabTeste(ID Int Identity(1,1) Primary Key,
                                           ContactName VarChar(200) NOT NULL,
                                           Value Int NOT NULL)
GO
BEGIN TRAN
DECLARE @i INT
SET @i = 0 
WHILE (@i < 50000)
BEGIN
  INSERT INTO TabTeste(ContactName, Value)
  VALUES(NEWID(), ABS(CHECKSUM(NEWID()) / 1000000) + 1)
  SET @i = @i + 1 
END;
COMMIT TRAN
GO
-- Incluindo apenas 3 linhas com Value 0
INSERT INTO TabTeste(ContactName, Value) VALUES(NEWID(), 0)
INSERT INTO TabTeste(ContactName, Value) VALUES(NEWID(), 0)
INSERT INTO TabTeste(ContactName, Value) VALUES(NEWID(), 0)
GO
CREATE NONCLUSTERED INDEX ix_Value ON TabTeste(Value);
GO
CREATE NONCLUSTERED INDEX ix_ContactName ON TabTeste(ContactName);
GO


SELECT * FROM TabTeste
GO

IF OBJECT_ID('st_Proc_Teste', 'P') IS NOT NULL
  DROP PROC st_Proc_Teste
GO
CREATE PROCEDURE dbo.st_Proc_Teste @Value Int, @ContactName VarChar(200) = NULL
AS
BEGIN
  DECLARE @Variavel_Auxiliar Int
  SELECT @Variavel_Auxiliar = @Value;
  
  -- Problema 1 - Variável original sem alterar
  SELECT *
    FROM TabTeste
   WHERE Value <= @Value;
  
  -- Problema 2 - Variável auxiliar
  SELECT *
    FROM TabTeste
   WHERE Value <= @Variavel_Auxiliar;
  
  -- Problema 3 - Filtros dinâmicos
  SELECT *
    FROM TabTeste
   WHERE (Value <= @Value OR @Value IS NULL)
     AND (ContactName LIKE @ContactName OR @ContactName IS NULL)

  IF @Value = 0
    SET @Value = 10;

  -- Problema 4 - Variável original alterada
  SELECT *
    FROM TabTeste
   WHERE Value <= @Value;
END
GO

-- Teste Proc
EXEC dbo.st_Proc_Teste @Value = 0
GO

-- Teste Proc
EXEC dbo.st_Proc_Teste @Value = 0, @ContactName = 'AB%'
GO

/*
  Alternativas:
  OPTION (RECOMPILE)
  WITH RECOMPILE
  EXEC dbo.st_Proc_Teste @Value = 0 WITH RECOMPILE
  sp_recompile
  DBCC FREEPROCCACHE(PlanHandle) -- SELECT cp.plan_handle, st.[text] FROM sys.dm_exec_cached_plans AS cp CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
  OPTION(OPTIMIZE FOR UNKNOWN)
  OPTION(OPTIMIZE FOR (@Value = 0, @ContactName UNKNOWN));
  trace flag 4136 para desabilitar parameter sniffing 
*/

---------------------------------
----- Código/Filtro dinâmico ----
---------------------------------
sp_helpindex OrdersBig
GO
-- DROP INDEX ixCustomerID ON OrdersBig
-- DROP INDEX ixOrderDate ON OrdersBig
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO

-- Stored Procedure st_RetornaOrders
IF OBJECT_ID('st_RetornaOrders') IS NOT NULL 
  DROP PROC st_RetornaOrders
GO
CREATE PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                             @CustomerID  AS Int      = NULL,
                             @OrderDate   AS DateTime = NULL
WITH RECOMPILE
AS
BEGIN
  SELECT OrderID, CustomerID, OrderDate, Value
    FROM OrdersBig
   WHERE (OrderID    = @OrderID    OR @OrderID    IS NULL)
     AND (CustomerID = @CustomerID OR @CustomerID IS NULL)
     AND (OrderDate  = @OrderDate  OR @OrderDate  IS NULL)
END
GO

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO

-- Criar controle utilizando IFs
ALTER PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                            @CustomerID  AS Int      = NULL,
                            @OrderDate   AS DateTime = NULL
WITH RECOMPILE
AS
BEGIN
  IF @OrderID IS NOT NULL
     AND @CustomerID IS NULL
     AND @OrderDate IS NULL
  BEGIN
    SELECT OrderID, CustomerID, OrderDate, Value
      FROM OrdersBig
     WHERE OrderID = @OrderID
  END
  ELSE IF @OrderID IS NULL
    AND @CustomerID IS NOT NULL
    AND @OrderDate IS NULL
  BEGIN
    SELECT OrderID, CustomerID, OrderDate, Value
      FROM OrdersBig
     WHERE CustomerID = @CustomerID
  END
  ELSE IF @OrderID IS NULL
    AND @CustomerID IS NULL
    AND @OrderDate IS NOT NULL
  BEGIN
    SELECT OrderID, CustomerID, OrderDate, Value
      FROM OrdersBig
     WHERE OrderDate = @OrderDate
  END
--  ELSE IF ...
END

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO

-- Utilizando código dinâmico
ALTER PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                            @CustomerID  AS Int      = NULL,
                            @OrderDate   AS DateTime = NULL
AS
BEGIN
  DECLARE @sql AS NVARCHAR(1000);

  SET @sql = 
      N'SELECT OrderID, CustomerID, OrderDate, Value'
    + N'  FROM OrdersBig'
    + N' WHERE 1 = 1'
    + CASE WHEN @OrderID IS NOT NULL THEN
        N' AND OrderID = @oid' ELSE N'' END
    + CASE WHEN @CustomerID IS NOT NULL THEN
        N' AND CustomerID = @cid' ELSE N'' END
    + CASE WHEN @OrderDate IS NOT NULL THEN
        N' AND OrderDate = @dt' ELSE N'' END;

  EXEC sp_executesql
    @stmt = @sql,
    @params = N'@oid AS Int, @cid AS Int, @dt AS DateTime',
    @oid = @OrderID,
    @cid = @CustomerID,
    @dt  = @OrderDate;
END
GO

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO
 
-- Stored Procedure st_RetornaOrders
-- HINT RECOMPILE, melhor otimizado no SQL2008
IF OBJECT_ID('st_RetornaOrders') IS NOT NULL 
  DROP PROC st_RetornaOrders
GO
CREATE PROC st_RetornaOrders @OrderID     AS Int      = NULL,
                             @CustomerID  AS Int      = NULL,
                             @OrderDate   AS DateTime = NULL
AS
BEGIN
  SELECT OrderID, CustomerID, OrderDate, Value
    FROM OrdersBig
   WHERE (OrderID    = @OrderID    OR @OrderID    IS NULL)
     AND (CustomerID = @CustomerID OR @CustomerID IS NULL)
     AND (OrderDate  = @OrderDate  OR @OrderDate  IS NULL)
  OPTION (RECOMPILE)
END
GO

-- Testar a proc, olhar os planos...
EXEC st_RetornaOrders @OrderID    = 10248;
EXEC st_RetornaOrders @OrderDate  = '20070101';
EXEC st_RetornaOrders @CustomerID = 3;
GO

/*
  http://www.sommarskog.se/dyn-search-2008.html
  In SQL 2008, things changed. Microsoft changed the hint OPTION(RECOMPILE) so it now works as you would expect. 
  However, there was a serious bug in the original implementation, 
  and you need at least CU5 of SQL 2008 SP1 or SQL 2008 SP2 to benefit from this feature. 
*/
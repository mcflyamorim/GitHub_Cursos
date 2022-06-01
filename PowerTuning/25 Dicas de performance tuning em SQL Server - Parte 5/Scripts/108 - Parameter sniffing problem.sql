USE Northwind
GO

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

SELECT * FROM TabTeste
GO

IF OBJECT_ID('st_Proc_Teste', 'P') IS NOT NULL
  DROP PROC st_Proc_Teste
GO
CREATE PROCEDURE dbo.st_Proc_Teste @Value Int
AS
BEGIN  
  SELECT *
    FROM TabTeste
   WHERE Value <= @Value;
END
GO

-- Teste Proc
EXEC dbo.st_Proc_Teste @Value = 0
GO

-- Teste Proc
EXEC dbo.st_Proc_Teste @Value = 0
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
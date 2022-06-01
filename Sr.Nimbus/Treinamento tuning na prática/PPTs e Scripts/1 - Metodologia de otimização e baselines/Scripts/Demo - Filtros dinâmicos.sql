/*
    Fabiano Neves Amorim
       Thiago Alencar
      SQLSaturday 284
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Preparando o ambiente
-- Demora 1:30 mins para rodar
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
WHILE (@i < 5000000)
BEGIN
  INSERT INTO TabTeste(ContactName, Value)
  VALUES(NEWID(), ABS(CHECKSUM(NEWID()) / 1000000) + 1)
  SET @i = @i + 1 
END;
COMMIT TRAN
GO
-- Incluindo apenas 500 linhas com Value 0
INSERT INTO TabTeste(ContactName, Value) VALUES(NEWID(), 0)
GO 500
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
  DECLARE @i Int
  -- Problema - Filtros dinâmicos
  SELECT @i = Count(*)
    FROM TabTeste
   WHERE (Value <= @Value OR @Value IS NULL)

  SELECT @i "Resultado do Count"
END
GO

-- Teste Proc
-- Tenho um índice por Value, porque não faz o seek?
EXEC dbo.st_Proc_Teste @Value = 0
GO

-- E o option(recompile) resolve?
IF OBJECT_ID('st_Proc_Teste', 'P') IS NOT NULL
  DROP PROC st_Proc_Teste
GO
CREATE PROCEDURE dbo.st_Proc_Teste @Value Int
AS
BEGIN
  DECLARE @i Int
  -- Problema - Filtros dinâmicos
  SELECT @i = Count(*)
    FROM TabTeste
   WHERE (Value <= @Value OR @Value IS NULL)
  OPTION (RECOMPILE)

  SELECT @i "Resultado do Count"
END
GO

-- Com OPTION (RECOMPILE) agora vai, correto?
EXEC dbo.st_Proc_Teste @Value = 0
GO


















-- "Gap na funcionalidade" do recompile (parameter embedding optimization) + "setar" variáveis
-- precisamos fazer uma "gambi"...
IF OBJECT_ID('st_Proc_Teste', 'P') IS NOT NULL
  DROP PROC st_Proc_Teste
GO
CREATE PROCEDURE dbo.st_Proc_Teste @Value Int
AS
BEGIN
  DECLARE @i Int

  SELECT i = Count(*)
    INTO #TMP
    FROM TabTeste
   WHERE (Value <= @Value OR @Value IS NULL)
  OPTION (RECOMPILE)

  SELECT @i = i 
    FROM #TMP

  SELECT @i "Resultado do Count"
END
GO

-- Agora gera o seek
EXEC dbo.st_Proc_Teste @Value = 0
GO



/*
  http://www.sommarskog.se/dyn-search-2008.html
  In SQL 2008, things changed. Microsoft changed the hint OPTION(RECOMPILE) so it now works as you would expect. 
  However, there was a serious bug in the original implementation, 
  and you need at least CU5 of SQL 2008 SP1 or SQL 2008 SP2 to benefit from this feature. 
*/
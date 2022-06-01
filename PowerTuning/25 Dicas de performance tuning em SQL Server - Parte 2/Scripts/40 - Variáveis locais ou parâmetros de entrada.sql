/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

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
WHILE (@i < 1000)
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
  DECLARE @Variavel_Auxiliar INT, @Variavel_Auxiliar1 INT, @Variavel_Auxiliar2 Int
  SELECT @Variavel_Auxiliar = @Value;
  
  -- =
  SELECT *
    FROM TabTeste
   WHERE Value = @Variavel_Auxiliar;

  -- <= 
  SELECT *
    FROM TabTeste
   WHERE Value <= @Variavel_Auxiliar;

  -- BETWEEN
  SELECT *
    FROM TabTeste
   WHERE Value BETWEEN @Variavel_Auxiliar1 AND @Variavel_Auxiliar2;
END
GO

-- Teste Proc
EXEC dbo.st_Proc_Teste @Value = 0
GO

-- Cuidado... 
-- Melhor utilizar a variável recebida 
 -- como parametro de entrada... ou OPTION (RECOMPILE)
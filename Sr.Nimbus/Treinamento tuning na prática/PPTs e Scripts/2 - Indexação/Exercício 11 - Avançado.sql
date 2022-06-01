USE Northwind
GO

IF OBJECT_ID('TABTeste') IS NOT NULL
  DROP TABLE TABTeste
GO

CREATE TABLE TabTeste(ID     Int Identity(1,1) Primary Key,
                      Nome1  VarChar(4) NOT NULL,
                      Valor1 Int NOT NULL)
GO

DECLARE @i INT
SET @i = 0
WHILE (@i < 1000)
BEGIN
    INSERT INTO TabTeste(Nome1, Valor1)
    VALUES('aaaa', 0) 
    SET @i = @i + 1
END;

-- DROP INDEX ix_TesteSem_Include ON TabTeste
CREATE NONCLUSTERED INDEX ix_TesteSem_Include ON TabTeste(Nome1, Valor1)
GO

-- Não usa o índice
SELECT *
  FROM TabTeste
 WHERE Nome1 = 'aaaa'
   AND Valor1 <= 10
 ORDER BY ID
GO


-- DROP INDEX ix_Teste_Include ON TabTeste
CREATE NONCLUSTERED INDEX ix_Teste_Include ON TabTeste(Nome1) INCLUDE(Valor1)
GO

-- Porque agora usa? Explique!
SELECT *
  FROM TabTeste
 WHERE Nome1 = 'aaaa'
   AND Valor1 <= 10
 ORDER BY ID
GO

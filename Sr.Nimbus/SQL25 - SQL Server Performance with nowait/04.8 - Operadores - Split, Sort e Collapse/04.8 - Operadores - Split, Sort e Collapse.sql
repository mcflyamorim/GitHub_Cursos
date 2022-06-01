/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE tempdb
GO


-- Preparando demo
IF OBJECT_ID('TabTest') IS NOT NULL
  DROP TABLE TabTest
GO
CREATE TABLE TabTest (ID    Int IDENTITY(1,1) PRIMARY KEY,
                      Name  VarChar(250) NULL,
                      Name2 VarChar(250) NULL,
                      Val   Int NULL,
                      Val2  Int NULL)
GO
CREATE UNIQUE INDEX ix_Name_Unique ON TabTest(Name)
CREATE INDEX ix_Name2_NonUnique ON TabTest(Name2)
CREATE UNIQUE INDEX ix_Val_Unique ON TabTest(Val)
CREATE INDEX ix_Val2_NonUnique ON TabTest(Val2)
GO
INSERT INTO TabTest(Name, Val) VALUES('Valor 1', 1)
INSERT INTO TabTest(Name, Val) VALUES('Valor 2', 2)
INSERT INTO TabTest(Name, Val) VALUES('Valor 3', 3)
INSERT INTO TabTest(Name, Val) VALUES('Valor 4', 4)
INSERT INTO TabTest(Name, Val) VALUES('Valor 5', 5)
GO
UPDATE TabTest SET Name2 = Name, Val2 = Val
GO

-- Consultando dados da tabela
SELECT * FROM TabTest


-- Update na coluna Val2 que não tem índice único
-- Não precisa de split,sort, collapse
UPDATE TabTest SET Val2 = Val2 + 1
GO

-- Update na coluna Val que tem índice único
UPDATE TabTest SET Val = Val + 1
GO


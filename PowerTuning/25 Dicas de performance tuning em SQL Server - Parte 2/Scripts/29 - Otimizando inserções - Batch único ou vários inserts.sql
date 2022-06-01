/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO



-- Qual command é mais rápido?
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (ID   INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
                   Col1 VarChar(250) NOT NULL,
                   Col2 VarChar(250) NOT NULL)
GO
CHECKPOINT
GO
DECLARE @i INT = 1
WHILE @i <= 50000
BEGIN
  INSERT INTO Tab1 VALUES(NEWID(), NEWID())
  SET @i+= 1
END
GO


-- Ou esse? 
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (ID   INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
                   Col1 VarChar(250) NOT NULL,
                   Col2 VarChar(250) NOT NULL)
GO
CHECKPOINT
GO
BEGIN TRAN
DECLARE @i INT = 1
WHILE @i <= 50000
BEGIN
  INSERT INTO Tab1 VALUES(NEWID(), NEWID())
  SET @i+= 1
END
COMMIT
GO


-- Consulta eventos gerados no Log
SELECT TOP 1000 *
  FROM ::fn_dblog(null, null)
GO


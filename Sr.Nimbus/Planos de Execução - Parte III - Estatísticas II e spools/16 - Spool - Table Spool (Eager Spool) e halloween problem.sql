/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

----------------------------------------------------
--- Table Spool - Eager Spool e halloween problem ---
----------------------------------------------------

USE Northwind
GO

/*
  Eager Spool - Halloween Problem
*/
SET NOCOUNT ON
IF OBJECT_ID('Funcionarios') IS NOT NULL
  DROP TABLE Funcionarios
GO
CREATE TABLE Funcionarios(ID          Int IDENTITY(1,1) PRIMARY KEY,
                          ContactName Char(7000),
                          Salario     Numeric(18,2));
GO
-- Inserir 4 registros para alocar 4 páginas
INSERT INTO Funcionarios(ContactName, Salario) VALUES('Fabiano', 1900)
INSERT INTO Funcionarios(ContactName, Salario) VALUES('Luciano',2050)
INSERT INTO Funcionarios(ContactName, Salario) VALUES('Gilberto', 2070)
INSERT INTO Funcionarios(ContactName, Salario) VALUES('Ivan', 2090)
GO
CREATE NONCLUSTERED INDEX ix_Salario ON Funcionarios(Salario)
GO

-- Consultar os dados da tabela
SELECT * FROM Funcionarios
GO

-- Aumento do salário em 10%
-- Utiliza o operador Eager Spool
UPDATE Funcionarios SET Salario = Salario * 1.1
  FROM Funcionarios WITH(index=ix_Salario)
 WHERE Salario < 3000
GO


-- Simular o update com um dynamyc cursor
BEGIN TRAN
DECLARE @ID INT
DECLARE TMP_Cursor CURSOR DYNAMIC 
    FOR SELECT ID 
          FROM Funcionarios WITH(index=ix_Salario)
         --WHERE Salario < 3000

OPEN TMP_Cursor
FETCH NEXT FROM TMP_Cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT * FROM Funcionarios WITH(index=ix_Salario)

  UPDATE Funcionarios SET Salario = Salario * 1.1 
   WHERE ID = @ID

  FETCH NEXT FROM TMP_Cursor INTO @ID
END
CLOSE TMP_Cursor
DEALLOCATE TMP_Cursor
SELECT * FROM Funcionarios
ROLLBACK TRAN
GO

-- Simular o update com um static cursor 
-- simulando o Spool que grava uma cópia dos dados no tempdb
BEGIN TRAN
DECLARE @ID INT
DECLARE TMP_Cursor CURSOR STATIC 
    FOR SELECT ID 
          FROM Funcionarios WITH(index=ix_Salario)
         WHERE Salario < 3000

OPEN TMP_Cursor
FETCH NEXT FROM TMP_Cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT * FROM Funcionarios WITH(index=ix_Salario)

  UPDATE Funcionarios SET Salario = Salario * 1.1 
   WHERE ID = @ID

  FETCH NEXT FROM TMP_Cursor INTO @ID
END
CLOSE TMP_Cursor
DEALLOCATE TMP_Cursor
SELECT * FROM Funcionarios
ROLLBACK TRAN
GO


-- Filtro na chave única elimina a necessidade de validação contra HP
UPDATE Funcionarios SET Salario = Salario * 1.1
  FROM Funcionarios WITH(index=ix_Salario)
 WHERE Salario < 3000
   AND ID = 1
GO

-- TOP 1 elimina a necessidade de validação contra HP
UPDATE TOP (1) Funcionarios SET Salario = Salario * 1.1
  FROM Funcionarios WITH(index=ix_Salario)
 WHERE Salario < 3000
GO



-- HP em inserts

IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (OrderID Int PRIMARY KEY, OrderDate Date)
GO

-- SQL inlcui spool para proteção de HP
INSERT INTO #TMP
SELECT OrderID, OrderDate
  FROM OrdersBig
 WHERE NOT EXISTS (SELECT *
                     FROM #TMP)
OPTION (MAXDOP 1, RECOMPILE)
GO


-- Evitando spool para proteção de HP
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (OrderID Int PRIMARY KEY, OrderDate Date)
GO

IF NOT EXISTS (SELECT *
                 FROM #TMP)
BEGIN
  INSERT INTO #TMP
  SELECT OrderID, OrderDate
    FROM OrdersBig
  OPTION (MAXDOP 1, RECOMPILE)
END



-- Bug SQL 2000
http://support.microsoft.com/kb/285870
-- FIX: Update With Self Join May Update Incorrect Number Of Rows

SET NOCOUNT ON
IF OBJECT_ID('Funcionarios') IS NOT NULL
  DROP TABLE Funcionarios
GO
CREATE TABLE Funcionarios(ID       Int IDENTITY(1,1) PRIMARY KEY,
                          Nome     VarChar(200),
                          Chefe    Int,
                          Salario  Numeric(18,2));
GO
-- Inserir 4 registros para alocar 4 páginas
INSERT INTO Funcionarios(Nome, Chefe, Salario) VALUES('Fabiano', 2, 1900)
INSERT INTO Funcionarios(Nome, Chefe, Salario) VALUES('Luciano', 0, 2050)
INSERT INTO Funcionarios(Nome, Chefe, Salario) VALUES('Gilberto', 2, 2070)
INSERT INTO Funcionarios(Nome, Chefe, Salario) VALUES('Ivan', 3, 2090)
GO
CREATE NONCLUSTERED INDEX ix_Salario ON Funcionarios(Salario)
GO

-- Consultar os dados da tabela
SELECT * 
  FROM Funcionarios
GO

ALTER TABLE Funcionarios ADD RespondePara VarChar(200)
GO
UPDATE Funcionarios SET RespondePara = 'Deus'
WHERE Nome = 'Luciano'
GO

-- Bug no SQL Server 2000 (standard edition)
UPDATE Funcionarios SET RespondePara = Funcionarios.Nome + ' -> ' + b.Nome + ' -> ' + ISNULL(b.RespondePara, '')
  FROM Funcionarios
 INNER JOIN Funcionarios b
    ON Funcionarios.Chefe = b.ID
OPTION (FORCE ORDER, HASH JOIN) -- Trocar para LOOP JOIN para previnir bug
GO

SELECT * FROM Funcionarios



-- Preciso de HP (halloween protection) em RCSI ?
-- Não porque o RCSI garante que durante a consulta terei uma visão consistente
-- dos dados no momento em que a consulta iniciou, sendo assim, eu não veria 
-- as minhas próprias alterações até que a transação seja "comitada"

-- QO não leva isso em consideração...
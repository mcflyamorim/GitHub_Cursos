/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

----------------------------------------
--- Tried trees para estimar strings ---
----------------------------------------

USE Northwind
GO

IF OBJECT_ID('Funcionarios') IS NOT NULL
  DROP TABLE Funcionarios
GO
CREATE TABLE Funcionarios(ID       Int IDENTITY(1,1) PRIMARY KEY,
                          Nome     VarChar(40),
                          Salario  Numeric(18,2));
GO
-- Inserir 4 registros para alocar 4 páginas
INSERT INTO Funcionarios(Nome, Salario)
VALUES('Fabiano', 0),('Gilberto', 0),('Luciano', 0), ('Fabio', 0),
('Fagner', 0), ('Fabiana', 0), ('Gil', 0), ('Lucia', 0), ('Lucio', 0), 
('Lucimar', 0)
GO
CREATE NONCLUSTERED INDEX ix_Nome ON Funcionarios(Nome)
GO

DBCC SHOW_STATISTICS (Funcionarios, ix_Nome)
GO

-- Estimativa perfeita (4 linhas)
SELECT * FROM Funcionarios
WHERE Nome like '%Fa%'
GO

-- Estimativa perfeita (3 linhas)
SELECT * FROM Funcionarios
WHERE Nome like '%abi%'
GO

-- Nem tão perfeito mas funcionou bem
SELECT * FROM Customers
 WHERE ContactName LIKE '%ab%'
GO

-- DROP INDEX ixProductName ON ProductsBig
CREATE INDEX ixProductName ON ProductsBig(ProductName)
GO

-- Maravilhoso! Estima 38828 e atual é de 38760
SELECT COUNT(*) 
  FROM ProductsBig
 WHERE ProductName LIKE '%ant%'
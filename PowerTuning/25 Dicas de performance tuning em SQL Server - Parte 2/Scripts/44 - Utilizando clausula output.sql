/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (ID INT, Col1 INT, Col2 Int)
GO

-- Insere e retorna as linhas inseridas...
INSERT INTO Tab1(ID, Col1, Col2)  
OUTPUT Inserted.ID, Inserted.Col1, Inserted.Col2
VALUES  (1, 1, 1), (2, 2, 2), (3, 3, 3), (4, 4, 4) 
GO

-- Inserted e deleted...
UPDATE Tab1 SET Col1 =  99
OUTPUT Deleted.Col1, Inserted.Col1
GO

----------------------------------------
------- OUTPUT:Composable DML ----------
----------------------------------------

BEGIN TRAN
DECLARE @tb TABLE (ProductID Int, ValorAntigo Float, NovoValor Float)
INSERT INTO @tb
SELECT ProductID, ValorAntigo, NovoValor
  FROM (UPDATE dbo.Products
           SET UnitPrice *= 1.10 -- Atualiza em 10%
        OUTPUT inserted.ProductID,
               deleted.UnitPrice AS ValorAntigo,
               inserted.UnitPrice AS NovoValor
         WHERE SupplierID = 1) AS D
 WHERE ValorAntigo < 20.0 AND NovoValor >= 20.0;
SELECT * FROM @tb
ROLLBACK TRAN

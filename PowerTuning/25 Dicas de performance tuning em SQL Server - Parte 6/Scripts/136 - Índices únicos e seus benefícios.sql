USE Northwind
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
INSERT INTO CustomersBig
        (
         CompanyName,
         ContactName,
         Col1,
         Col2
        )
VALUES  (
         '', -- CompanyName - varchar(20)
         'Fabiano Amorim', -- ContactName - varchar(20)
         '', -- Col1 - varchar(250)
         ''  -- Col2 - varchar(250)
        )
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO

CREATE UNIQUE INDEX ix1 ON CustomersBig (ContactName)
GO


-- SQL Pode confiar que SEMPRE somente 1 cliente será retornado
-- pois CustomerID é PK da tabela
SELECT * 
  FROM CustomersBig
 WHERE ContactName = 'Fabiano Amorim'
GO

 
-- Evitando uma agregação
-- Repare que o distinct é ignorado
SELECT DISTINCT ContactName
  FROM CustomersBig
GO

-- Evitando uma aggregação e validação pelo operador Assert
SELECT (SELECT ContactName 
          FROM CustomersBig
         WHERE ContactName = 'Janine Labrune') AS ContactName,
       *
  FROM Orders
GO

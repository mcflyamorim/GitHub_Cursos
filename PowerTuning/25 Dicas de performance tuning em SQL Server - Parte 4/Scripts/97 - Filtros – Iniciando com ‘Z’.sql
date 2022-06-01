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
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
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
         'Zé', -- ContactName - varchar(20)
         '', -- Col1 - varchar(250)
         ''  -- Col2 - varchar(250)
        )
GO
CREATE INDEX ixContactName ON CustomersBig (ContactName)
GO


-- Retorna todos os clientes que começam com Z...
SELECT * FROM CustomersBig
WHERE LEFT(ContactName, 1)  = 'Z'
GO

-- Utilizando SubString, agora vai...
SELECT * FROM CustomersBig
WHERE SUBSTRING(ContactName, 1, 1)  = 'Z'
GO


-- Né?
SELECT * FROM CustomersBig
WHERE ContactName LIKE 'Z%'
GO


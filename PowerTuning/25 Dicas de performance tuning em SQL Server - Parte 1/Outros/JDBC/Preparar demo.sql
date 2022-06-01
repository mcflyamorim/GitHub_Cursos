USE Northwind
GO

-- 20 segundos para rodar...
IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
  DROP TABLE CustomersBig
END
GO
SELECT TOP 3000000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       CONVERT(VarChar(250), NEWID()) AS CompanyName, 
       CONVERT(VarChar(250), NEWID()) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO
INSERT INTO CustomersBig
        (
         CityID,
         CompanyName,
         ContactName,
         Col1,
         Col2
        )
VALUES  (
         0, -- CityID - int
         '', -- CompanyName - uniqueidentifier
         'Fabiano Amorim', -- ContactName - uniqueidentifier
         '', -- Col1 - varchar(250)
         ''  -- Col2 - varchar(250)
        )
GO
CREATE INDEX ixContactName ON CustomersBig(ContactName)
GO

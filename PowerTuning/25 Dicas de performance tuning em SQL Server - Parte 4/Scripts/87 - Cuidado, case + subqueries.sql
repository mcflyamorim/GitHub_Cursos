USE Northwind
GO
-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
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


-- Quantas vezes acessa a tabela OrdersBig?
SELECT TOP 10000
       ContactName,
       CASE (SELECT SUM(Value) FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID)
         WHEN 1 THEN 'Cliente tipo 1'
         WHEN 2 THEN 'Cliente tipo 2'
         WHEN 3 THEN 'Cliente tipo 3'
         WHEN 4 THEN 'Cliente tipo 4'
         WHEN 5 THEN 'Cliente tipo 5'
         WHEN 6 THEN 'Cliente tipo 6'
         WHEN 7 THEN 'Cliente tipo 7'
         WHEN 8 THEN 'Cliente tipo 8'
         WHEN 9 THEN 'Cliente tipo 9'
         ELSE 'Nennum'
       END AS Status_Cliente
  FROM CustomersBig
GO

-- E agora?
SELECT TOP 10000
       ContactName,
       (SELECT CASE SUM(Value) 
                    WHEN 1 THEN 'Cliente tipo 1'
                    WHEN 2 THEN 'Cliente tipo 2'
                    WHEN 3 THEN 'Cliente tipo 3'
                    WHEN 4 THEN 'Cliente tipo 4'
                    WHEN 5 THEN 'Cliente tipo 5'
                    WHEN 6 THEN 'Cliente tipo 6'
                    WHEN 7 THEN 'Cliente tipo 7'
                    WHEN 8 THEN 'Cliente tipo 8'
                    WHEN 9 THEN 'Cliente tipo 9'
                 ELSE 'Nennum'
               END AS Status_Cliente       
          FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID) AS Status_Cliente
  FROM CustomersBig
GO

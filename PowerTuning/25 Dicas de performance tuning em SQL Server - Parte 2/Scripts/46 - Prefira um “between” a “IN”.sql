/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 10000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO


-- Qual é melhor? 
SET STATISTICS IO ON
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
GO
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID BETWEEN 1 AND 16
SET STATISTICS IO OFF
GO

-- E se não for sequencial? ... 
SET STATISTICS IO ON
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,25)
GO
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID BETWEEN 1 AND 25
   AND CustomerID NOT BETWEEN 16 AND 24
SET STATISTICS IO OFF
GO



-- Pra mais de 64 valores no in... SQL vai jogar em uma constante e fazer join...
-- Faça você isso... nem espere ele fazer... jogue na #tmp e faça o join...
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,
                      11,12,13,14,15,16,17,18,19,20,
                      21,22,23,24,25,26,27,28,29,30,
                      31,32,33,34,35,36,37,38,39,40,
                      41,42,43,44,45,46,47,48,49,50,
                      51,52,53,54,55,56,57,58,59,60,
                      61,62,63,64,65)
GO




-- Isso é igual a 50 seeks
SET STATISTICS IO ON
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID IN (1,2,3,4,5,6,7,8,9,10,
                      11,12,13,14,15,16,17,18,19,20,
                      21,22,23,24,25,26,27,28,29,30,
                      31,32,33,34,35,36,37,38,39,40,
                      41,42,43,44,45,46,47,48,49,50)
GO

-- Isso é igual a um seek + um range scan...
SELECT * 
  FROM CustomersBig 
 WHERE CustomerID BETWEEN 1 AND 50
SET STATISTICS IO OFF
GO

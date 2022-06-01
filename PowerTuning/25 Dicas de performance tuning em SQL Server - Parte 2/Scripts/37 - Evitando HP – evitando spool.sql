/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

-- Preparando o ambiente
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
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

-- HP em inserts
IF OBJECT_ID('TMP') IS NOT NULL
  DROP TABLE TMP
GO
CREATE TABLE TMP (OrderID Int PRIMARY KEY, OrderDate Date)
GO

-- SQL inlcui spool para proteção de HP
INSERT INTO TMP
SELECT OrderID, OrderDate
  FROM OrdersBig
 WHERE NOT EXISTS (SELECT *
                     FROM TMP)
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Dica bônus, remote queries geram HP mesmo quando a tabela acessada não tem relação com a modificada :-( ... e não há como evitar... 
-- Ex:
INSERT INTO TMP
SELECT OrderID, OrderDate
  FROM OrdersBig
 WHERE NOT EXISTS (SELECT a.*  
                     FROM OPENROWSET('SQLNCLI', 'Server=RAZERFABIANO\SQL2019CTP2_4;Trusted_Connection=yes;',  
                          'SELECT * FROM Northwind.dbo.Orders') AS a)
OPTION (MAXDOP 1, RECOMPILE)
GO

SELECT a.*  
FROM OPENROWSET('SQLNCLI', 'Server=RAZERFABIANO\SQL2019CTP2_4;Trusted_Connection=yes;',  
     'SELECT * FROM Northwind.dbo.TMP') AS a;

-- Evitando spool para proteção de HP
IF OBJECT_ID('TMP') IS NOT NULL
  DROP TABLE TMP
GO
CREATE TABLE TMP (OrderID Int PRIMARY KEY, OrderDate Date)
GO

IF NOT EXISTS (SELECT *
                 FROM TMP)
BEGIN
  INSERT INTO TMP
  SELECT OrderID, OrderDate
    FROM OrdersBig
  OPTION (MAXDOP 1, RECOMPILE)
END
GO


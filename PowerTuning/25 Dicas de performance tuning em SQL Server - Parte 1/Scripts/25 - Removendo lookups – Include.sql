USE Northwind
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 10000
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


CREATE INDEX ix_CompanyName ON CustomersBig(CompanyName)
GO

-- Mesmo que um índice por CompanyName exista o SQL não vai usar por causa da seletividade
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName LIKE 'C%'
GO

/*
  A partir do SQL Server 2005 podemos utilizar a clausula INCLUDE 
  para evitar o lookup
*/

CREATE INDEX ix_CompanyName ON CustomersBig(CompanyName) INCLUDE(Col1, Col2) WITH(DROP_EXISTING=ON)
GO

-- Com o índice coberto o SQL Faz o Seek + um Range Scan
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName LIKE 'C%'
GO

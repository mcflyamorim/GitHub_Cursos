/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind
GO

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 2GB
EXEC sp_configure 'max server memory', 2048
RECONFIGURE
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
  DROP TABLE CustomersBig
END
GO
SELECT TOP 2000000 
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
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

-- Sort query. Bad spill, if 1 row, and 1 row only 
-- does not fit into memory, entire set will be spilled to disk...

-- TOP 100 is OK
-- 1MB as MemoryGrant
SELECT TOP 100
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO


-- TOP 101 uses unoptimized algorithm
-- Sort writes the whole shit into tempdb... :-(
-- See warning
SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO


-- Alternative, minimize the amount of data spilled to tempdb
-- No warning... 374MB as grant was enough
SELECT CustomersBig.*
  FROM (SELECT TOP 101 CustomerID, Col1 
          FROM CustomersBig 
         ORDER BY Col1) AS Tab1
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = Tab1.CustomerID
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO


-- Other alternatives
-- Give it more memory... 
-- Create index per Col1...



-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 10GB
EXEC sp_configure 'max server memory', 10240
RECONFIGURE
GO
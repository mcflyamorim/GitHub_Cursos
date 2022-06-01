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
       CONVERT(VarChar(250), REPLICATE('ASD', 10)) AS Col1, 
       CONVERT(VarChar(250), REPLICATE('ASD', 10)) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO



-- Spill to tempdb because memory grant wasn't enough
SET STATISTICS IO ON
SELECT * 
  FROM CustomersBig
 ORDER BY Col1 DESC
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO
--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 25000, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'CustomersBig'. Scan count 1, logical reads 25692, physical reads 49, read-ahead reads 2, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


sp_spaceused CustomersBig
GO

ALTER INDEX ALL ON CustomersBig REBUILD WITH(DATA_COMPRESSION=PAGE)
GO

sp_spaceused CustomersBig
GO

-- Ops... same 25001 are written to tempdb
SET STATISTICS IO ON
SELECT * 
  FROM CustomersBig
 ORDER BY Col1 DESC
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
GO

--Table 'Worktable'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 25001, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
--Table 'CustomersBig'. Scan count 1, logical reads 6364, physical reads 6, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.


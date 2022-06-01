/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

-------------------------------
-- Monitoring Sort Warnings --
-------------------------------

USE NorthWind
GO

-- Warning on Sort operator on SQL2012+
SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1)
GO

-- Or via xEvents
-- Demo


-- Earlier than 2012, we'll need to use profiler

-- Step 1 create a new trace:
-- Step 2 PAUSE trace
-- Step 3 create TextData column (in case it doesn't exist...)
-- Step 4 create a trigger
-- Step 5 start trace


ALTER TABLE TabTraces ADD TextData VARCHAR(MAX)
GO

IF OBJECT_ID('tr_CapturaSQL_SortWarning') IS NOT NULL
  DROP TRIGGER tr_CapturaSQL_SortWarning
GO
CREATE TRIGGER tr_CapturaSQL_SortWarning ON TabTraces
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SQL VARCHAR(MAX)

  SELECT @SQL = sqltext.text
   FROM sys.dm_exec_connections conn
  INNER JOIN inserted
     ON inserted.SPID = conn.session_id
  CROSS APPLY sys.dm_exec_sql_text(conn.most_recent_sql_handle) AS sqltext

  UPDATE	TabTraces
     SET TextData = @SQL
    FROM TabTraces
   INNER JOIN Inserted
      ON Inserted.SPID = TabTraces.SPID
   WHERE TabTraces.TextData IS NULL
END
GO

-- Query trace table
SELECT * FROM TabTraces
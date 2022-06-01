/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE Northwind
GO

-- Exercícios: FizzBuzzProblemn

--------------------------------------
--------- Windows Functions ----------
--------------------------------------
USE TempDB
SET NOCOUNT ON;
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Col1 Int)
GO

INSERT INTO Tab1 VALUES(5), (5), (3) , (1)
GO

-- RowNumber
SELECT Col1, 
       ROW_NUMBER() OVER(ORDER BY Col1 DESC) AS "ROW_NUMBER()"
  FROM Tab1
  
-- Rank
SELECT Col1, 
       RANK() OVER(ORDER BY Col1 DESC) AS "RANK()"
  FROM Tab1

-- Dense_Rank
SELECT Col1, 
       DENSE_RANK() OVER(ORDER BY Col1 DESC) AS "DENSE_RANK"
  FROM Tab1

-- NTILE
SELECT Col1, 
       NTILE(3) OVER(ORDER BY Col1 DESC) AS "NTILE(3)"
  FROM Tab1

-- NTILE
SELECT Col1, 
       NTILE(2) OVER(ORDER BY Col1 DESC) AS "NTILE(2)"
  FROM Tab1

-- LEAD
SELECT Col1, 
       LEAD(Col1) OVER(ORDER BY Col1) AS "LEAD()"
  FROM Tab1
  
-- LEAD
SELECT Col1, 
       LEAD(Col1, 2) OVER(ORDER BY Col1) AS "LEAD()"
  FROM Tab1

-- LAG
SELECT Col1, 
       LAG(Col1) OVER(ORDER BY Col1) AS "LAG()"
  FROM Tab1

SELECT Col1, 
       LEAD(Col1, -1) OVER(ORDER BY Col1) AS "LEAD() Como LAG()"
  FROM Tab1

-- FIRST_VALUE
SELECT Col1, 
       FIRST_VALUE(Col1) OVER(ORDER BY Col1) AS "FIRST_VALUE()"
  FROM Tab1

-- LAST_VALUE
SELECT Col1, 
       LAST_VALUE(Col1) OVER(ORDER BY Col1) AS "LAST_VALUE()"
  FROM Tab1

-- LAST_VALUE
SELECT Col1, 
       LAST_VALUE(Col1) OVER(ORDER BY Col1 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS "LAST_VALUE()"
  FROM Tab1

-- LAST_VALUE
SELECT Col1,
       LAST_VALUE(Col1) OVER(ORDER BY Col1 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS "LAST_VALUE()"
  FROM Tab1



-- Outras

-- PERCENT_RANK
SELECT Col1, 
       PERCENT_RANK() OVER(ORDER BY Col1) AS "PERCENT_RANK()"
  FROM Tab1
  
-- Fake PERCENT_RANK
SELECT Col1, 
       (RANK() OVER(ORDER BY Col1) - 1.) / ((SELECT COUNT(*) FROM Tab1) - 1.) AS "Fake PERCENT_RANK()"
  FROM Tab1

-- CUME_DIST()
SELECT Col1, 
       CUME_DIST() OVER(ORDER BY Col1) AS "CUME_DIST()"
  FROM Tab1

-- PERCENTILE_CONT, PERCENTILE_DISC
SELECT Col1, 
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Col1) OVER () AS MedianCont,
       PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY Col1) OVER () AS MedianDisc
  FROM Tab1



-- Teste 2
-- xEvent - window_spool_ondisk_warning

-- Performance tests, utilizando running aggregation

use tempdb
GO

-- Running Aggregations
USE tempdb
SET NOCOUNT ON;
GO
IF OBJECT_ID('TestRunningTotals') IS NOT NULL
  DROP TABLE TestRunningTotals
GO
CREATE TABLE TestRunningTotals (ID         Integer IDENTITY(1,1) PRIMARY KEY,
                                ID_Account Integer, 
                                ColDate    Date,
                                ColValue   Float)
GO
-- inserting some garbage data (almost 33 seconds to run)
INSERT INTO TestRunningTotals(ID_Account, ColDate, ColValue)
SELECT TOP 2000000
       ABS((CHECKSUM(NEWID()) /10000000)), 
       CONVERT(Date, GetDate() - (CHECKSUM(NEWID()) /1000000)), 
       (CHECKSUM(NEWID()) /10000000.)
FROM master.sys.columns AS c,
     master.sys.columns AS c2,
     master.sys.columns AS c3
GO
;WITH CTE1
AS
(
  SELECT ColDate, ROW_NUMBER() OVER(PARTITION BY ID_Account, ColDate ORDER BY ColDate) rn
    FROM TestRunningTotals
)
-- Removing duplicated dates
DELETE FROM CTE1
WHERE rn > 1
GO
CREATE UNIQUE INDEX ix ON TestRunningTotals (ID_Account, ColDate) INCLUDE(ColValue)
GO

-- Counting the number of rows
SELECT COUNT(*) FROM TestRunningTotals
GO

-- Solution 1 -- SubQuery
IF OBJECT_ID('st_RunningAggregations_Solution1', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution1
GO
CREATE PROCEDURE st_RunningAggregations_Solution1 @ID_Account Int
AS
BEGIN
  SELECT ID_Account, 
         ColDate,
         ColValue,
         (SELECT SUM(b.ColValue)
            FROM TestRunningTotals b
           WHERE b.ID_Account = @ID_Account
             AND b.ColDate <= a.ColDate) AS RunningTotal
    FROM TestRunningTotals a
   WHERE ID_Account = @ID_Account
   ORDER BY ID_Account, ColDate
END
GO
-- Solution 2 -- Cursor
IF OBJECT_ID('st_RunningAggregations_Solution2', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution2
GO
CREATE PROCEDURE st_RunningAggregations_Solution2 @ID_Account Int
AS
BEGIN
  CREATE TABLE #TMP (ID_Account Int, ColDate Date, ColValue Float, RunningTotal Float)
  CREATE CLUSTERED INDEX ix ON #TMP (ID_Account, ColDate)

  DECLARE @ColValue       Float,
          @RunningTotal   Float = 0,
          @ColDate        Date,
          @CurrID_Account Int

  DECLARE curRunningTotal CURSOR STATIC LOCAL FORWARD_ONLY
      FOR SELECT ID_Account, ColDate, ColValue
            FROM TestRunningTotals
           WHERE ID_Account = @ID_Account
           ORDER BY ID_Account, ColDate

  OPEN curRunningTotal

  FETCH NEXT FROM curRunningTotal
   INTO @CurrID_Account, @ColDate, @ColValue

  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @RunningTotal = @RunningTotal + @ColValue
    INSERT INTO #TMP
            (
             ID_Account,
             ColDate,
             ColValue,
             RunningTotal
            )
    SELECT @CurrID_Account, @ColDate, @ColValue, @RunningTotal

    FETCH NEXT FROM curRunningTotal
     INTO @CurrID_Account, @ColDate, @ColValue
  END
  CLOSE curRunningTotal
  DEALLOCATE curRunningTotal

  SELECT * FROM #TMP
END
GO
-- Solution 3 - UPDATE with variable, trusting on cluster key order (not allways safe)
IF OBJECT_ID('st_RunningAggregations_Solution3', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution3
GO
CREATE PROCEDURE st_RunningAggregations_Solution3 @ID_Account Int
AS
BEGIN
  IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
    DROP TABLE #TMP

  CREATE TABLE #TMP (ID_Account Int, ColDate Date, ColValue Float, RunningTotal Float)
  CREATE CLUSTERED INDEX ix ON #TMP (ID_Account, ColDate)

  DECLARE @RunningTotal Float = 0

  INSERT INTO #TMP
          (
           ID_Account,
           ColDate,
           ColValue,
           RunningTotal
          )
  SELECT ID_Account, ColDate, ColValue, 0
    FROM TestRunningTotals
   WHERE ID_Account = @ID_Account
   ORDER BY ID_Account, ColDate

  UPDATE #TMP SET @RunningTotal = RunningTotal = @RunningTotal + ColValue
    FROM #TMP

  SELECT * FROM #TMP
  ORDER BY ID_Account, ColDate
END
GO
-- Solution 4 - DML+DDL+CTE+TOP+ORDERBY+UPDATE+OUTUPT+VARIABLE, Crazy stuff from Paul White :-) (not safe)
IF OBJECT_ID('st_RunningAggregations_Solution4', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution4
GO
CREATE PROCEDURE st_RunningAggregations_Solution4 @ID_Account Int
AS
BEGIN
  BEGIN TRAN

  ALTER TABLE TestRunningTotals ADD RunningTotal Float NULL
  DECLARE @str NVarChar(MAX)
  SET @str = 'DECLARE @RunningTotal Float = 0
              ;WITH CTE_1
              AS
              (
                SELECT TOP (9223372036854775807) *
                  FROM TestRunningTotals
                 WHERE ID_Account = @IntID_Account
                 ORDER BY ColDate
              )
              UPDATE CTE_1 SET @RunningTotal = RunningTotal = @RunningTotal + ColValue
              OUTPUT INSERTED.ID_Account, 
                     INSERTED.ColDate, 
                     INSERTED.ColValue, 
                     INSERTED.RunningTotal'
  
  EXEC sp_executeSQL @str, N'@IntID_Account Int', @IntID_Account = @ID_Account
  
  ROLLBACK TRAN
END
GO
-- Solution 5 - SQL Serer 2012, OVER clause with ORDER BY, Disk-Based worktable
IF OBJECT_ID('st_RunningAggregations_Solution5', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution5
GO
CREATE PROCEDURE st_RunningAggregations_Solution5 @ID_Account Int
AS
BEGIN
  SELECT ID_Account, 
         ColDate, 
         ColValue,
         SUM(ColValue) OVER(ORDER BY ID_Account, ColDate) AS RunningTotal
    FROM TestRunningTotals
   WHERE ID_Account = @ID_Account
   ORDER BY ID_Account, ColDate
END
GO
-- Solution 6 - SQL Serer 2012, OVER clause with ORDER BY, In-Memory worktable
IF OBJECT_ID('st_RunningAggregations_Solution6', 'P') IS NOT NULL
  DROP PROC st_RunningAggregations_Solution6
GO
CREATE PROCEDURE st_RunningAggregations_Solution6 @ID_Account Int
AS
BEGIN
  SELECT ID_Account, 
         ColDate, 
         ColValue,
         SUM(ColValue) OVER(ORDER BY ID_Account, ColDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS RunningTotal
    FROM TestRunningTotals
   WHERE ID_Account = @ID_Account
   ORDER BY ID_Account, ColDate
END
GO



-- Solution 1 -- SubQuery
-- PageReads: 43290
-- Duration: 1702
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution1 @ID_Account = @i
GO

-- Solution 2 -- Cursor
-- PageReads: 23702
-- Duration: 637
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution2 @ID_Account = @i
GO

-- Solution 3 - UPDATE with variable, trusting on cluster key order (not allways safe)
-- PageReads: 462
-- Duration: 395
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution3 @ID_Account = @i
GO

-- Solution 4 - sp_executeSQL+DML+DDL+CTE+TOP+ORDERBY+UPDATE+OUTUPT+VARIABLE, 
-- Crazy and fun stuff from Paul White :-) (not safe)
-- PageReads: 42777
-- Duration: 2660
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution4 @ID_Account = @i
GO

-- Solution 5 - SQL Serer 2012, OVER clause with ORDER BY, Disk-Based worktable
-- PageReads: 31210
-- Duration: 347
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution5 @ID_Account = @i
GO

-- Solution 6 - SQL Serer 2012, OVER clause with ORDER BY, In-Memory worktable
-- PageReads: 22 YES I ONLY 22 reads :-)
-- Duration: 234
CHECKPOINT
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
DECLARE @i Int = ABS(CHECKSUM(NEWID()) / 10000000)
EXEC st_RunningAggregations_Solution6 @ID_Account = @i
GO

-- Performance difference
-- 1 - Analisar Reads no Profiler
-- 2 - Ver Reads usando SET STATISTICS IO
-- 3 - Olhar warning - evento(xEvent)
USE tempdb
GO
-- Prepara ambiente
-- Aproximadamente 2 minutos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE OrdersBig (OrderID int NOT NULL IDENTITY(1, 1),
                        CustomerID int NULL,
                        OrderDate date NULL,
                        Value numeric (18, 2) NOT NULL)
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY CLUSTERED  (OrderID)
GO
-- Tab com 5 milhões de linhas
INSERT INTO OrdersBig(CustomerID, OrderDate, Value)
SELECT TOP 5000000
       ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000))),
       CONVERT(Date, GetDate() - ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000)))),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
GO
ALTER TABLE OrdersBig ADD CountCol VarChar(20)
GO
UPDATE TOP (50) PERCENT OrdersBig SET CountCol = 'Count'
WHERE CountCol IS NULL
GO
UPDATE TOP (50) PERCENT OrdersBig SET CountCol = 'CountDistinct'
WHERE CountCol IS NULL
GO
UPDATE OrdersBig SET CountCol = 'CountDistinct_1'
WHERE CountCol IS NULL
GO
CHECKPOINT
GO

-- Problema
CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
SELECT a.CustomerID,
       a.CountCol,
       CASE a.CountCol
         WHEN 'Count' THEN COUNT(1)
         WHEN 'CountDistinct' THEN COUNT(DISTINCT a.OrderDate)
         WHEN 'CountDistinct_1' THEN COUNT(DISTINCT 1)
         ELSE NULL
       END AS Cnt,
       CASE (SELECT AVG(b.Value)
               FROM OrdersBig b
              WHERE b.CustomerID = a.CustomerID) 
            WHEN 1000 THEN 'Média = 1 mil'
            WHEN 2000 THEN 'Média = 2 mil'
            WHEN 3000 THEN 'Média = 3 mil'
            WHEN 4000 THEN 'Média = 4 mil'
            WHEN 5000 THEN 'Média = 5 mil'
            ELSE 'Não é número exato'
       END AS Sts
  FROM OrdersBig AS a
 GROUP BY a.CustomerID, a.CountCol
 ORDER BY a.CustomerID
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
Table 'Worktable'. Scan count 4303, logical reads 75389953, physical reads 7809, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'OrdersBig'. Scan count 6, logical reads 215472, physical reads 3020, read-ahead reads 112058, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

SQL Server Execution Times:
  CPU time = 111884 ms,  elapsed time = 236156 ms.

SQL Server Execution Times:
  CPU time = 0 ms,  elapsed time = 0 ms.
*/





-- Solução


-- 1 - Índice para evitar Sort
-- Demora 26 segundos para rodar
-- DROP INDEX ix1 ON OrdersBig 
CREATE INDEX ix1 ON OrdersBig (CustomerID, CountCol, OrderDate) INCLUDE(Value) WITH(DATA_COMPRESSION=PAGE)
CHECKPOINT
GO
-- E agora?
CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
SELECT a.CustomerID,
       a.CountCol,
       CASE a.CountCol
         WHEN 'Count' THEN COUNT(1)
         WHEN 'CountDistinct' THEN COUNT(DISTINCT a.OrderDate)
         WHEN 'CountDistinct_1' THEN COUNT(DISTINCT 1)
         ELSE NULL
       END AS Cnt,
       CASE (SELECT AVG(b.Value)
               FROM OrdersBig b
              WHERE b.CustomerID = a.CustomerID) 
            WHEN 1000 THEN 'Média = 1 mil'
            WHEN 2000 THEN 'Média = 2 mil'
            WHEN 3000 THEN 'Média = 3 mil'
            WHEN 4000 THEN 'Média = 4 mil'
            WHEN 5000 THEN 'Média = 5 mil'
            ELSE 'Não é número exato'
       END AS Sts
  FROM OrdersBig AS a
 GROUP BY a.CustomerID, a.CountCol
 ORDER BY a.CustomerID
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
Table 'Worktable'. Scan count 4303, logical reads 15110979, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'OrdersBig'. Scan count 1076, logical reads 60935, physical reads 1, read-ahead reads 9427, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 49281 ms,  elapsed time = 50335 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/



-- 2 - Reescrevendo a SubQuery do CASE
CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
SELECT a.CustomerID,
       a.CountCol,
       CASE a.CountCol
         WHEN 'Count' THEN COUNT(1)
         WHEN 'CountDistinct' THEN COUNT(DISTINCT a.OrderDate)
         WHEN 'CountDistinct_1' THEN COUNT(DISTINCT 1)
         ELSE NULL
       END AS Cnt,
       (SELECT CASE AVG(b.Value)
                      WHEN 1000 THEN 'Média = 1 mil'
                      WHEN 2000 THEN 'Média = 2 mil'
                      WHEN 3000 THEN 'Média = 3 mil'
                      WHEN 4000 THEN 'Média = 4 mil'
                      WHEN 5000 THEN 'Média = 5 mil'
                      ELSE 'Não é número exato'
               END AS Sts
               FROM OrdersBig b
              WHERE b.CustomerID = a.CustomerID) AS Sts
  FROM OrdersBig a
 GROUP BY a.CustomerID, a.CountCol
 ORDER BY a.CustomerID
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
Table 'Worktable'. Scan count 863, logical reads 15100671, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'OrdersBig'. Scan count 216, logical reads 19835, physical reads 1, read-ahead reads 9427, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Workfile'. Scan count 0, logical reads 0, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

SQL Server Execution Times:
CPU time = 36489 ms,  elapsed time = 37301 ms.

SQL Server Execution Times:
CPU time = 0 ms,  elapsed time = 0 ms.
*/


-- 3 - Remover o COUNT(DISTINCT 1)  
CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
SELECT a.CustomerID,
       a.CountCol,
       CASE a.CountCol
         WHEN 'Count' THEN COUNT(1)
         WHEN 'CountDistinct' THEN COUNT(DISTINCT a.OrderDate)
         WHEN 'CountDistinct_1' THEN 1
         ELSE NULL
       END AS Cnt,
       (SELECT CASE AVG(b.Value)
                      WHEN 1000 THEN 'Média = 1 mil'
                      WHEN 2000 THEN 'Média = 2 mil'
                      WHEN 3000 THEN 'Média = 3 mil'
                      WHEN 4000 THEN 'Média = 4 mil'
                      WHEN 5000 THEN 'Média = 5 mil'
                      ELSE 'Não é número exato'
               END AS Sts
               FROM OrdersBig b
              WHERE b.CustomerID = a.CustomerID) AS Sts
  FROM OrdersBig a
 GROUP BY a.CustomerID, a.CountCol
 ORDER BY a.CustomerID
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
SET STATISTICS TIME OFF
GO

/*
Table 'Worktable'. Scan count 860, logical reads 2577, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'OrdersBig'. Scan count 216, logical reads 19835, physical reads 1, read-ahead reads 9427, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

SQL Server Execution Times:
  CPU time = 6053 ms,  elapsed time = 6524 ms.

SQL Server Execution Times:
  CPU time = 0 ms,  elapsed time = 0 ms.
*/


-- 4 - Alternativa para COUNT(DISTINCT ...)
-- No SQL2012 e 2014 não precisa

-- E agora?
CHECKPOINT;DBCC DROPCLEANBUFFERS;DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
;WITH CTE_1
AS
(
  SELECT CustomerID,
         CountCol,
         OrderDate,
         CASE 
           WHEN ROW_NUMBER() OVER(PARTITION BY CustomerID, CountCol, OrderDate ORDER BY OrderDate) = 1 THEN 1
           ELSE NULL
         END AS DistinctCnt
    FROM OrdersBig
)
SELECT CustomerID,
       CountCol,
       CASE CountCol
         WHEN 'Count' THEN COUNT(1)
         WHEN 'CountDistinct' THEN COUNT(DistinctCnt)
         WHEN 'CountDistinct_1' THEN 1
         ELSE NULL
       END AS Cnt,
       (SELECT CASE AVG(b.Value)
                      WHEN 1000 THEN 'Média = 1 mil'
                      WHEN 2000 THEN 'Média = 2 mil'
                      WHEN 3000 THEN 'Média = 3 mil'
                      WHEN 4000 THEN 'Média = 4 mil'
                      WHEN 5000 THEN 'Média = 5 mil'
                      ELSE 'Não é número exato'
               END AS Sts
               FROM OrdersBig b
              WHERE b.CustomerID = CTE_1.CustomerID) AS Sts
  FROM CTE_1
 GROUP BY CustomerID, CountCol
 ORDER BY CustomerID
OPTION (MAXDOP 1)
SET STATISTICS IO OFF
SET STATISTICS TIME OFF

/*
Table 'Worktable'. Scan count 860, logical reads 2577, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'OrdersBig'. Scan count 216, logical reads 19835, physical reads 1, read-ahead reads 9427, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

 SQL Server Execution Times:
   CPU time = 8471 ms,  elapsed time = 8969 ms.

 SQL Server Execution Times:
   CPU time = 0 ms,  elapsed time = 0 ms.
*/
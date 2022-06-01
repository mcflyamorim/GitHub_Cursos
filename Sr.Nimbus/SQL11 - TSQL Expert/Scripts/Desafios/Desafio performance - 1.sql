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




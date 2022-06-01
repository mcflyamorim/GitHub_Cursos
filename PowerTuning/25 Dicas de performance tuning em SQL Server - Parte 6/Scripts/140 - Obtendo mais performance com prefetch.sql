USE Master
GO
DROP DATABASE TestPrefetch
GO

CREATE DATABASE TestPrefetch ON  PRIMARY 
( NAME = N'TestPrefetch1', FILENAME = N'C:\DBs\TestPrefetch1.mdf' , SIZE = 512000KB , FILEGROWTH = 1024KB ) 
 LOG ON 
( NAME = N'TestPrefetch_log', FILENAME = N'C:\DBs\TestPrefetch_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE TestPrefetch SET RECOVERY SIMPLE 
GO


USE TestPrefetch
GO
IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1
GO
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
                       Col1 Char(5000),
                       Col2 Char(1250),
                       Col3 Char(1250),
                       Col4 Numeric(18,2))
GO
-- 25 secs to run...
INSERT INTO TestTab1 WITH(TABLOCK) (Col1, Col2, Col3, Col4) 
SELECT TOP 1000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 30
CREATE INDEX ix_Col4 ON TestTab1(Col4)
GO
CHECKPOINT
GO


-- Run SQLIO
-- c:\sqlio\sqlio.exe -kR -t16 -dD -s1200 -b64

-- Teste prefetch DISABLED
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS;
GO
SET STATISTICS IO, TIME ON
SELECT *
  FROM TestTab1 
 WHERE Col4 < 2.5
OPTION (RECOMPILE,
        QueryTraceON 8744) -- Disable Prefetch
SET STATISTICS IO, TIME OFF
GO
--Table 'TestTab1'. Scan count 1, logical reads 1103, physical reads 412, page server reads 0, read-ahead reads 0
-- SQL Server Execution Times:
--   CPU time = 31 ms,  elapsed time = 11183 ms.

-- Teste prefetch ENABLED
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS;
GO
SET STATISTICS IO, TIME ON
SELECT *
  FROM TestTab1
 WHERE Col4 < 2.5
OPTION (RECOMPILE)
SET STATISTICS IO, TIME OFF
GO
--Table 'TestTab1'. Scan count 1, logical reads 2049, physical reads 3, page server reads 0, read-ahead reads 3272
-- SQL Server Execution Times:
--   CPU time = 15 ms,  elapsed time = 2783 ms.


-- Exemplo de problema em Prod...

IF OBJECT_ID('st_Test1') IS NOT NULL
  DROP PROC st_Test1
GO
CREATE PROC st_Test1 @i Numeric(18,2)
AS
BEGIN
  SELECT *
    FROM TestTab1
   WHERE TestTab1.Col4 < @i
END
GO

-- Se menos de 25 linhas forem estimadas... não habilita 
-- prefetch (harcoded value)
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 0.05
GO

-- E agora que estou reutilizando o plano do cache? 
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 2.5
GO


-- E se eu pedir pra recompilar?
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 2.5 WITH RECOMPILE
GO


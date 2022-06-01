IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1

-- Table with 1 page per row...
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
                       Col1 Char(5000),
                       Col2 Char(1250),
                       Col3 Char(1250),
                       Col4 Numeric(18,2))

-- 5 minutes to run...
INSERT INTO TestTab1 WITH(TABLOCK) (Col1, Col2, Col3, Col4) 
SELECT TOP 100000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
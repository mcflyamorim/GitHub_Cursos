use tempdb;
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1(id INT IDENTITY(1,1) PRIMARY KEY,
                  Col1 int,
                  Col1000 VARCHAR(1000),
                  Col8000 VARCHAR(8000),                  
                  ColMax VarChar(MAX))
GO

INSERT INTO Tab1 ( Col1, Col1000, Col8000, ColMax )
SELECT TOP 10000 CHECKSUM(NEWID()), NEWID(), NEWID(), NEWID()
  FROM sysobjects a, sysobjects b, sysobjects c
GO

-- 511bytes rowsize, 7mb memory grant
SELECT Col1000
  FROM Tab1
 ORDER BY Col1000
OPTION (MAXDOP 1)
GO

-- 4011bytes rowsize, 49mb memory grant
SELECT Col8000
  FROM Tab1
 ORDER BY Col8000
OPTION (MAXDOP 1)
GO

-- 4025bytes rowsize, 50mb memory grant
SELECT ColMAX
  FROM Tab1
 ORDER BY ColMAX
OPTION (MAXDOP 1)
GO

SELECT (1000 * 4035.) / 1024
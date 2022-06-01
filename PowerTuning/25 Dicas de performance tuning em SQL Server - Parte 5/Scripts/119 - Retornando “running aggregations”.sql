USE Northwind
GO

-- Dados de teste ... 2 segundos para rodar...
IF OBJECT_ID('Tab_TesteSaldo') IS NOT NULL
  DROP TABLE Tab_TesteSaldo
GO
CREATE TABLE Tab_TesteSaldo (ID       Integer IDENTITY(1,1) PRIMARY KEY,
                                IDConta  Integer, 
                                ColData  Date,
                                ColValor Float)
GO
INSERT INTO Tab_TesteSaldo(IDConta, ColData, ColValor)
SELECT TOP 1000000
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
  SELECT ColData, ROW_NUMBER() OVER(PARTITION BY IDConta, ColData ORDER BY ColData) rn
    FROM Tab_TesteSaldo
)
-- Removendo dados duplicados...
DELETE FROM CTE1
WHERE rn > 1
GO
CREATE INDEX ix1 ON Tab_TesteSaldo (IDConta, ColData) INCLUDE(ColValor)
GO

-- Query utilizando frame otimizado (ROWS UNBOUNDED PRECEDING)
-- in–memory worktable
SET STATISTICS IO ON
DECLARE @i INT
SET @i = ABS((CHECKSUM(NEWID()) /10000000))
SELECT IDConta,
       ColData,
       ColValor,
       SUM(ColValor) OVER(PARTITION BY IDConta ORDER BY ColData ASC ROWS UNBOUNDED PRECEDING) AS RunningTotal
  FROM Tab_TesteSaldo
 WHERE IDConta = @i
 ORDER BY IDConta, ColData
OPTION (RECOMPILE)
SET STATISTICS IO OFF
GO


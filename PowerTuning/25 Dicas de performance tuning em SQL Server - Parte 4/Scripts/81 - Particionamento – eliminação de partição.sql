USE Northwind;
GO

-- 15 segundos para rodar...
IF OBJECT_ID('TabPartitionElimination') IS NOT NULL
  DROP TABLE TabPartitionElimination
GO
IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'PartitionScheme1')
  DROP PARTITION SCHEME PartitionScheme1
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'PartitionFunction1')
  DROP PARTITION FUNCTION PartitionFunction1
GO

CREATE PARTITION FUNCTION PartitionFunction1 (INT)
AS RANGE FOR VALUES
(   100,
    200,
    300,
    400
);

CREATE PARTITION SCHEME PartitionScheme1 AS PARTITION PartitionFunction1 ALL TO ([PRIMARY]);
GO

CREATE TABLE TabPartitionElimination
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON PartitionScheme1 (Col1);
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1

CREATE TABLE Tab1
(
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID()
) ON "PRIMARY";
GO

SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (ABS(CheckSUM(NEWID()) / 10000000), ABS(CheckSUM(NEWID()) / 10000000));
GO 20000
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (301, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
INSERT INTO TabPartitionElimination (Col1, Col2)
VALUES (401, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
COMMIT
GO
INSERT INTO Tab1
SELECT * FROM TabPartitionElimination
GO




-- Consultando o número das partições
SELECT $partition.PartitionFunction1(Col1) [Partition Number], * 
  FROM TabPartitionElimination
GO

-- Lendo apenas os dados da partição 5
SET STATISTICS IO ON
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= 400 -- Static partition elimination
   AND 1=1 -- pra eliminar auto parameterização... Ler http://sqlblog.com/blogs/paul_white/archive/2012/09/12/why-doesn-t-partition-elimination-work.aspx
SET STATISTICS IO OFF
-- Table 'TabPartitionElimination'. Scan count 2, logical reads 4

-- Lendo apenas os dados da partição 4 e 5
SET STATISTICS IO ON
DECLARE @i Int = 400
SELECT * 
  FROM TabPartitionElimination
 WHERE Col1 >= @i -- Dynamic partition elimination
SET STATISTICS IO OFF
-- Table 'TabPartitionElimination'. Scan count 2, logical reads 4


-- E na tabela que não tem particionamento?
SET STATISTICS IO ON
SELECT * 
  FROM Tab1
 WHERE Col1 >= 400
SET STATISTICS IO OFF
-- Table 'Tab1'. Scan count 1, logical reads 2860
GO

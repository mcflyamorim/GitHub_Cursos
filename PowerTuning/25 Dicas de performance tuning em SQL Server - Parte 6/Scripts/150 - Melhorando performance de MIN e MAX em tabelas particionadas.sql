USE Northwind;
GO

-- 15 segundos para rodar...
IF OBJECT_ID('TabPartition') IS NOT NULL
  DROP TABLE TabPartition
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
DROP TABLE IF EXISTS TabPartition
GO
CREATE TABLE TabPartition
(
    ID INT IDENTITY(1, 1) ,
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID(),

    CONSTRAINT PK_TabPartition PRIMARY KEY CLUSTERED 
    (
	    ID ASC, Col1 ASC
    )
) ON PartitionScheme1 (Col1);
GO



SET NOCOUNT ON;
BEGIN TRANSACTION
GO
INSERT INTO TabPartition (Col1, Col2)
VALUES (ABS(CheckSUM(NEWID()) / 10000000), ABS(CheckSUM(NEWID()) / 10000000));
GO 2000
INSERT INTO TabPartition (Col1, Col2)
VALUES (301, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
INSERT INTO TabPartition (Col1, Col2)
VALUES (401, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
COMMIT
GO

-- Scan na tabela :-( ... 
SET STATISTICS TIME, IO ON
SELECT MIN(ID) FROM TabPartition
SELECT MAX(ID) FROM TabPartition
SET STATISTICS TIME, IO OFF
GO

-- Alternativa 1
-- Criar outro índice que não está particionado...
-- Obs.: Você vai precisar apagar ele antes de fazer um SWITCH ...
-- Vantagem dessa opção é que não há necessidade de reescrita de queries
-- Desvantagem é que você vai precisar pagar pelo custo extra do índice "duplicado"
DROP INDEX IF EXISTS TabPartition.ix2 
CREATE INDEX ix2 ON TabPartition (ID) ON "PRIMARY"
GO

-- TOP+Scan... Perfect...
SET STATISTICS TIME, IO ON
SELECT MIN(ID) FROM TabPartition
SELECT MAX(ID) FROM TabPartition
SET STATISTICS TIME, IO OFF
GO

DROP INDEX IF EXISTS TabPartition.ix2 
GO

-- Alternativa 2
-- Usar filtro na partição
SET STATISTICS TIME, IO ON
SELECT MIN(ID) FROM TabPartition
WHERE $PARTITION.PartitionFunction1(Col1) = 1;
SET STATISTICS TIME, IO OFF
GO

-- Mas e pra ler de todas as partições?
SET STATISTICS TIME, IO ON
SELECT MIN(ID) FROM TabPartition
WHERE $PARTITION.PartitionFunction1(Col1) = 1;
SET STATISTICS TIME, IO OFF
GO

-- Nada como uma boa gambiarra...
SET STATISTICS TIME, IO ON
-- Min
SELECT MIN(cMin_ID)
  FROM sys.partitions
 CROSS APPLY (SELECT MIN(ID) AS cMin_ID
                FROM TabPartition
               WHERE $PARTITION.PartitionFunction1(Col1) = partitions.partition_number) AS Tab1
 WHERE partitions.object_id = OBJECT_ID('TabPartition')
   AND partitions.index_id = INDEXPROPERTY(OBJECT_ID('TabPartition'), 'PK_TabPartition', 'IndexID')
-- Max
SELECT MAX(cMin_ID)
  FROM sys.partitions
 CROSS APPLY (SELECT MAX(ID) AS cMin_ID
                FROM TabPartition
               WHERE $PARTITION.PartitionFunction1(Col1) = partitions.partition_number) AS Tab1
 WHERE partitions.object_id = OBJECT_ID('TabPartition')
   AND partitions.index_id = INDEXPROPERTY(OBJECT_ID('TabPartition'), 'PK_TabPartition', 'IndexID')
SET STATISTICS TIME, IO OFF
GO


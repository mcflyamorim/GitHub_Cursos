USE Northwind
GO

-- Ok, não é bem um truncate com where, mas é um truncate de uma partição... 
-- O que já ajuda bastante...

-- Criando tabela pra testes...
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
SET NOCOUNT OFF;
BEGIN TRANSACTION
GO
INSERT INTO TabPartition (Col1, Col2)
VALUES (ABS(CheckSUM(NEWID()) / 10000000), ABS(CheckSUM(NEWID()) / 10000000));
GO 100
INSERT INTO TabPartition (Col1, Col2)
VALUES (301, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
INSERT INTO TabPartition (Col1, Col2)
VALUES (401, ABS(CheckSUM(NEWID()) / 10000000));
GO 10 
COMMIT
GO
INSERT INTO TabPartition (Col1, Col2)
VALUES (100, ABS(CheckSUM(NEWID()) / 10000000));
GO


-- Se eu quiser apagar todos os dados da partição 1 (<=100), 2 (>100 e <=200) 
-- e 3 (>200 e <=300)
BEGIN TRAN
DELETE FROM TabPartition
WHERE Col1 <= 300

SELECT * FROM TabPartition
ROLLBACK TRAN
GO

-- Ou então, desde o SQL2016, consigo fazer o seguinte:
BEGIN TRAN
TRUNCATE TABLE TabPartition 
WITH (PARTITIONS (1, 2 TO 3));

SELECT * FROM TabPartition
ROLLBACK TRAN
GO

-- Antes do SQL 2016 também é possível... Mas da um pouco de trabalho... 
-- Preciso criar uma tabela com a mesma estrutura, fazer swtich da partição pra ela
-- e depois fazer o truncate/drop


DROP TABLE IF EXISTS TabPartition_Tmp
GO
CREATE TABLE TabPartition_Tmp
(
    ID INT IDENTITY(1, 1) ,
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID(),

    CONSTRAINT PK_TabPartition_Tmp PRIMARY KEY CLUSTERED 
    (
	    ID ASC, Col1 ASC
    )
);
GO

BEGIN TRAN
ALTER TABLE TabPartition SWITCH PARTITION 1 TO TabPartition_Tmp
-- TRUNCATE TABLE TabPartition_Tmp
ALTER TABLE TabPartition SWITCH PARTITION 2 TO TabPartition_Tmp -- Se TabPartition_Tmp não estiver vazia, vai falhar...
TRUNCATE TABLE TabPartition_Tmp
ALTER TABLE TabPartition SWITCH PARTITION 3 TO TabPartition_Tmp
TRUNCATE TABLE TabPartition_Tmp

DROP TABLE TabPartition_Tmp

SELECT * FROM TabPartition
ROLLBACK TRAN
GO


-- Ou então, criar a nova tabela, também utilizando particionamento
-- Pra fazer o SWITCH direto pra partição
DROP TABLE IF EXISTS TabPartition_Tmp
GO
CREATE TABLE TabPartition_Tmp
(
    ID INT IDENTITY(1, 1) ,
    Col1 INT,
    Col2 INT,
    Col3 CHAR(1000) DEFAULT NEWID(),

    CONSTRAINT PK_TabPartition_Tmp PRIMARY KEY CLUSTERED 
    (
	    ID ASC, Col1 ASC
    )
) ON PartitionScheme1 (Col1);
GO

BEGIN TRAN
ALTER TABLE TabPartition SWITCH PARTITION 1 TO TabPartition_Tmp PARTITION 1
ALTER TABLE TabPartition SWITCH PARTITION 2 TO TabPartition_Tmp PARTITION 2
ALTER TABLE TabPartition SWITCH PARTITION 3 TO TabPartition_Tmp PARTITION 3

DROP TABLE TabPartition_Tmp

SELECT * FROM TabPartition
ROLLBACK TRAN
GO

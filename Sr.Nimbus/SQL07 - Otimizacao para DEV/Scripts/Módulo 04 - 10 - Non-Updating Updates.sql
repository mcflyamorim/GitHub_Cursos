/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

IF OBJECT_ID('Tab1') IS NOT NULL
BEGIN
  DROP TABLE Tab1
END
GO
CREATE TABLE Tab1 (Tab1_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col2 CHAR(200))
CREATE INDEX ix_Test ON Tab1(Tab1_Col2)

INSERT INTO Tab1 (Tab1_Col1, Tab1_Col2) VALUES(1,'')

SELECT  OBJECT_NAME(a.OBJECT_ID) Tabela,
        b.name,
        leaf_insert_count,
        leaf_delete_count,
        leaf_update_count
FROM    sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), 2, NULL) AS a
INNER JOIN sys.indexes b
ON      a.OBJECT_ID = b.OBJECT_ID
        AND a.index_id = b.index_id

UPDATE Tab1 SET Tab1_Col2 = 'ABC'
GO

SELECT  OBJECT_NAME(a.OBJECT_ID) Tabela,
        b.name,
        leaf_insert_count,
        leaf_delete_count,
        leaf_update_count
FROM    sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), 2, NULL) AS a
INNER JOIN sys.indexes b
ON      a.OBJECT_ID = b.OBJECT_ID
        AND a.index_id = b.index_id
GO

UPDATE Tab1 SET Tab1_Col2 = 'ABC'
GO

SELECT  OBJECT_NAME(a.OBJECT_ID) Tabela,
        b.name,
        leaf_insert_count,
        leaf_delete_count,
        leaf_update_count
FROM    sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), 2, NULL) AS a
INNER JOIN sys.indexes b
ON      a.OBJECT_ID = b.OBJECT_ID
        AND a.index_id = b.index_id
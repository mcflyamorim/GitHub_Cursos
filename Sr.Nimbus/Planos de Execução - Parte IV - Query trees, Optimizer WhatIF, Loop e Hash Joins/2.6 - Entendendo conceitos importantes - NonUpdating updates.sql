USE Northwind
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Col1 Integer IDENTITY(1,1) NOT NULL PRIMARY KEY, 
                   Col2 VarChar(800),
                   Col3 VarChar(800) DEFAULT NEWID())
CREATE INDEX ix_Test ON Tab1(Col2)
GO
INSERT INTO Tab1 (Col2) 
SELECT TOP 1 NEWID() FROM sysobjects a, sysobjects b, sysobjects c
GO

-- Insert da linha acima foi efetuado nos 2 índices...
SELECT OBJECT_NAME(a.OBJECT_ID) Tabela, b.name, leaf_insert_count, leaf_delete_count, leaf_update_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), NULL, NULL) AS a
 INNER JOIN sys.indexes b
    ON a.OBJECT_ID = b.OBJECT_ID
   AND a.index_id = b.index_id
GO

-- E se eu atualizar o valor da coluna Col2?
UPDATE Tab1 SET Col2 = 'ABC'
GO

-- Ocorreu um insert em ix_Test e um Update em "PK__Tab1__..."
SELECT OBJECT_NAME(a.OBJECT_ID) Tabela, b.name, leaf_insert_count, leaf_delete_count, leaf_update_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), NULL, NULL) AS a
 INNER JOIN sys.indexes b
    ON a.OBJECT_ID = b.OBJECT_ID
   AND a.index_id = b.index_id
GO

-- E se eu tentar atualizar com o mesmo valor?
UPDATE Tab1 SET Col2 = 'ABC'
GO


-- Otimização evita que o valor seja modificado nos índices non-cluster...
SELECT OBJECT_NAME(a.OBJECT_ID) Tabela, b.name, leaf_insert_count, leaf_delete_count, leaf_update_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('Tab1'), NULL, NULL) AS a
 INNER JOIN sys.indexes b
    ON a.OBJECT_ID = b.OBJECT_ID
   AND a.index_id = b.index_id
GO


-- Outro exemplo
DROP INDEX ix_OrderDate ON OrdersBig
DROP INDEX ix_CustomerID ON OrdersBig
DROP INDEX ix_Value ON OrdersBig

CREATE INDEX ix_OrderDate ON OrdersBig(OrderDate)
CREATE INDEX ix_CustomerID ON OrdersBig(CustomerID)
CREATE INDEX ix_Value ON OrdersBig(Value)
GO


-- Otimização evita que o valor seja modificado nos índices non-cluster...
SELECT OBJECT_NAME(a.OBJECT_ID) Tabela, b.name, leaf_insert_count, leaf_delete_count, leaf_update_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('OrdersBig'), NULL, NULL) AS a
 INNER JOIN sys.indexes b
    ON a.OBJECT_ID = b.OBJECT_ID
   AND a.index_id = b.index_id
GO

BEGIN TRAN

DECLARE @CustomerID Int, @Value Numeric(18,2), @OrderDate Date, @i BigInt = 9223372036854775807

SET @Value = 999

UPDATE TOP (@i) OrdersBig 
   SET CustomerID = ISNULL(@CustomerID, CustomerID), 
       Value = ISNULL(@Value, Value), 
       OrderDate = ISNULL(@OrderDate, OrderDate)
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (OPTIMIZE FOR (@i = 123123123)) -- Para forçar um plano Narrow/Per-Row

ROLLBACK TRAN
GO

-- Índices por OrderDate e por CustomerID não são modificados...
-- Sabe aquela tabela com 20 índices?... Então...

-- Otimização evita que o valor seja modificado nos índices non-cluster...
SELECT OBJECT_NAME(a.OBJECT_ID) Tabela, b.name, leaf_insert_count, leaf_delete_count, leaf_update_count
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('OrdersBig'), NULL, NULL) AS a
 INNER JOIN sys.indexes b
    ON a.OBJECT_ID = b.OBJECT_ID
   AND a.index_id = b.index_id
GO

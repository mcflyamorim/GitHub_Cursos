USE Northwind
GO

IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 10000 IDENTITY(Int, 1,1) AS ProductID, 
       dbo.fn_ReturnProductName() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
INSERT INTO ProductsBig (ProductName, Col1)
VALUES  ('Produto TV 50 com nome Fabiano e código - 98872167', 'Alguma coisa'), 
        ('SAMSUNG UN50JS7200GXZD LED 50" UHD SMART 4X HDMI', 'TVs SAMSUNG'), 
        ('SAMSUNG UN32J4300AGXZD TV LED 32" HD SMART 2HDMI 1USB', 'TVs SAMSUNG')
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO
CREATE INDEX ixProductName ON ProductsBig (ProductName)
GO

SELECT index_id 
  FROM sys.indexes
 WHERE OBJECT_ID = OBJECT_ID('ProductsBig')
   AND Name = 'ixProductName'
GO

-- Consulta Fragmentação do índice ixProductName
SELECT avg_fragmentation_in_percent 
  FROM sys.dm_db_index_physical_stats (DB_ID('NorthWind'),OBJECT_ID('ProductsBig'), 2, NULL, NULL);
GO

-- Gerando fragmentação na tabela...
UPDATE ProductsBig SET ProductName = NEWID()
GO

-- Consulta Fragmentação da tabela
SELECT avg_fragmentation_in_percent 
  FROM sys.dm_db_index_physical_stats (DB_ID('NorthWind'),OBJECT_ID('ProductsBig'), 2, NULL, NULL);
GO

SET STATISTICS IO ON
SELECT COUNT(*)
  FROM ProductsBig
SET STATISTICS IO OFF
GO
-- Table 'ProductsBig'. Scan count 1, logical reads 125


ALTER INDEX ixProductName ON ProductsBig REBUILD
GO

SET STATISTICS IO ON
SELECT COUNT(*)
  FROM ProductsBig
SET STATISTICS IO OFF
GO
-- Table 'ProductsBig'. Scan count 1, logical reads 65
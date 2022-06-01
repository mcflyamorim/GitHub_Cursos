USE NorthWind
GO

IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
  DROP TABLE Order_DetailsBig
GO
SELECT TOP 50000
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS OrderID,
       ISNULL(CONVERT(Integer, CONVERT(Integer, ABS(Checksum(NEWID())) / 100000)),0) AS ProductID,
       ISNULL(GetDate() -  ABS(Checksum(NEWID())) / 1000000, GetDate()) AS Shipped_Date,
       CONVERT(Integer, ABS(Checksum(NEWID())) / 1000000) AS Quantity
  INTO Order_DetailsBig
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
GO
;WITH CTE_1
AS
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY [OrderID], [ProductID] ORDER BY [OrderID], [ProductID]) AS rn
    FROM Order_DetailsBig
)
DELETE FROM CTE_1 WHERE rn <> 1
GO
ALTER TABLE Order_DetailsBig ADD CONSTRAINT [xpk_Order_DetailsBig] PRIMARY KEY([OrderID], [ProductID])
GO
ALTER TABLE Order_DetailsBig DROP COLUMN Quantity
GO
-- Aprox. 15 segundos
ALTER TABLE Order_DetailsBig ADD Quantity Int NOT NULL DEFAULT ABS(CHECKSUM(NEwID())) / 100000000
GO
UPDATE Order_DetailsBig SET Quantity = ABS(CHECKSUM(NEwID())) / 100000000
WHERE Quantity = 0
GO
-- ALTER TABLE Order_DetailsBig DROP COLUMN UnitPrice
ALTER TABLE Order_DetailsBig ADD UnitPrice Numeric(18,2) NULL
GO
-- Aprox. 16 segundos
UPDATE TOP (90) PERCENT Order_DetailsBig SET UnitPrice = ABS(CHECKSUM(NEwID())) / 10000000.
GO



-- Estimativa incorreta, 30%
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Vamos criar uma estatística calculada com fullscan
-- DROP STATISTICS Order_DetailsBig.Stats1
-- ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn1
ALTER TABLE Order_DetailsBig ADD ComputedColumn1 AS ISNULL(Quantity,0) * ISNULL(UnitPrice, 0)
GO
CREATE STATISTICS Stats1 ON Order_DetailsBig(ComputedColumn1) WITH FULLSCAN
GO

-- Agora vai?
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- DROP STATISTICS Order_DetailsBig.Stats2
-- ALTER TABLE Order_DetailsBig DROP COLUMN ComputedColumn2
ALTER TABLE Order_DetailsBig ADD ComputedColumn2 AS Quantity * ISNULL(UnitPrice, 0)
GO
CREATE STATISTICS Stats2 ON Order_DetailsBig(ComputedColumn2) WITH FULLSCAN
GO

-- Coluna Quantity não aceita NULL
-- O SQL Server sabe disso e o que ele faz? 
-- Troca o ISNULL(Quantity, 0) por Quantity
-- Dai a expressão não faz match com a coluna calculada...
-- Ver o predicate aplicado no scan
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE Quantity * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Mesmo usando a function funciona porque o QO a ignora
SELECT OrderID, Quantity, UnitPrice
  FROM Order_DetailsBig
 WHERE ISNULL(Quantity,0) * ISNULL(UnitPrice, 0) < 10.0
OPTION (MAXDOP 1, RECOMPILE)
GO
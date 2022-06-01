USE NorthWind
GO

IF OBJECT_ID('Order_DetailsBig') IS NOT NULL
  DROP TABLE Order_DetailsBig
GO
SELECT TOP 1000000
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
CREATE INDEX ixQuantity ON Order_DetailsBig(Quantity)
GO


-- Estimativa correta
SELECT * FROM Order_DetailsBig
WHERE Quantity = -10
OPTION (RECOMPILE)
GO

-- E se as estatísticas estiverem desatualizadas?
ALTER DATABASE NorthWind SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT
GO
UPDATE TOP (10) PERCENT Order_DetailsBig SET Quantity = -10
GO


-- Estimativa incorreta, pois as estatisticas estão desatualizadas
SELECT * FROM Order_DetailsBig
WHERE Quantity = -10
OPTION (RECOMPILE)
GO

ALTER DATABASE NorthWind SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT
GO

-- Estimativa correta, pois o AUTO_UPDATE_STATISTICS é disparado
SELECT * FROM Order_DetailsBig
WHERE Quantity = -10
OPTION (RECOMPILE)
GO

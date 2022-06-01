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
/*
  Atualizando a coluna Quantity em 500 grupos de 1 a 500
  com 2000 linhas em cada grupo.
*/
;WITH CTE
AS
(
SELECT NTILE(500) OVER(ORDER BY OrderID, ProductID) Qtd,
       *
  FROM Order_DetailsBig
)
UPDATE CTE SET Quantity = Qtd;
GO
-- Deixar um GAP no grupo 444
UPDATE Order_DetailsBig SET Quantity = -1
WHERE Quantity = 444
GO

-- Criar uma estatística por Quantity com FULLSCAN
CREATE STATISTICS Stats_Quantity ON Order_DetailsBig (Quantity) WITH FULLSCAN
GO

-- Visualizando o GAP do valor 444
DBCC SHOW_STATISTICS (Order_DetailsBig, Stats_Quantity) WITH HISTOGRAM
GO

/*
  Como o valor 444 não esta no histograma ele usa a média de 
  distribuição dos valores (AVG_RANGE_ROWS) entre o range
  
  Neste caso ele estima que 2000 linhas serão retornadas o que é errado
*/
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
GO

/*
  DROP INDEX ix_Quantity ON Order_DetailsBig (Quantity)
  Se eu tiver um índice por Quantity será 
  que não compensa usar o índice?
*/
CREATE INDEX ix_Quantity ON Order_DetailsBig (Quantity)
GO

-- SQL Continua não utilizando o índice
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF


-- Vejamos a Quantity de IOs forçando o SEEK
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig WITH(FORCESEEK)
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF

/*
  Criando estatísticas filtradas para resolver o problema
*/

IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_0_a_200' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_0_a_200
IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_201_a_400' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_201_a_400
IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity_Maior_401' AND object_id = OBJECT_ID('Order_DetailsBig'))
  DROP STATISTICS Order_DetailsBig.Stats_Quantity_Maior_401
GO
CREATE STATISTICS Stats_Quantity_0_a_200 ON Order_DetailsBig(Quantity) WHERE Quantity >= 0 AND Quantity <= 200 WITH FULLSCAN
CREATE STATISTICS Stats_Quantity_201_a_400 ON Order_DetailsBig(Quantity) WHERE Quantity >= 201 AND Quantity <= 400 WITH FULLSCAN
CREATE STATISTICS Stats_Quantity_Maior_401 ON Order_DetailsBig(Quantity) WHERE Quantity >= 401 WITH FULLSCAN
GO

-- Apenas 51 amostras foram analisadas, e o problema do GAP foi corrigido
DBCC SHOW_STATISTICS (Order_DetailsBig, Stats_Quantity_Maior_401)
GO

-- Com a estimativa correta o SQL utiliza corretamente o índice
SET STATISTICS IO ON
SELECT * FROM Order_DetailsBig
WHERE Quantity = 444
OPTION(RECOMPILE)
SET STATISTICS IO OFF


-- E em procs como fica?
IF OBJECT_ID('st_TestGAPStatistics') IS NOT NULL
  DROP PROC st_TestGAPStatistics
GO
CREATE PROC st_TestGAPStatistics @i Int
AS
BEGIN
  SELECT * 
    FROM Order_DetailsBig
   WHERE Quantity = @i
  OPTION (RECOMPILE) -- Necessário para poder usar a estatística associada ao valor
END
GO
 
EXEC st_TestGAPStatistics @i = 444
GO

USE Northwind
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1(Col1 Int NOT NULL PRIMARY KEY, Col2 Int)
GO
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
CREATE TABLE Tab2(Col1 Int NOT NULL PRIMARY KEY, Col2 Int)
GO

INSERT INTO Tab1 VALUES(1, 1), (2, 2)
INSERT INTO Tab2 VALUES(1, 1), (2, 2)
GO


-- Plano simples com SORT executando a operação de distinct sort
SELECT DISTINCT(Col2) 
  FROM Tab1
GO

-- Plano com Scan em Tab1 e Seek em Tab2 + Nested Loops e finalmente 
-- um sort por Tab1.Col2 + Tab2.Col2
SELECT * 
  FROM Tab1
 INNER JOIN Tab2 
    ON Tab1.Col1 = Tab2.Col2
 ORDER BY Tab1.Col2 + Tab2.Col2
OPTION (RECOMPILE)
GO
 
-- WITH STATS_STREAM para mostrar os valores de Rows e Data Pages
DBCC SHOW_STATISTICS (Tab1) WITH STATS_STREAM
DBCC SHOW_STATISTICS (Tab2) WITH STATS_STREAM
GO

-- Atualizando para números maiores
UPDATE STATISTICS Tab1 WITH ROWCOUNT = 10000, PAGECOUNT = 10000
UPDATE STATISTICS Tab2 WITH ROWCOUNT = 100000, PAGECOUNT = 100000
GO

-- Plano utilizando Hash Match para processar o distinct das 10 mil linhas
SELECT DISTINCT(Col2)
  FROM Tab1
OPTION (RECOMPILE)
GO

-- Scan em Tab1 e Tab2 + Hash Match para fazer o join e 
-- Sort por Tab1.Col2 + Tab2.Col2
SELECT *
  FROM Tab1
 INNER JOIN Tab2 
    ON Tab1.Col1 = Tab2.Col2
 ORDER BY Tab1.Col2 + Tab2.Col2
OPTION (RECOMPILE)
GO

-- Reset ROWCOUNT e PAGECOUNT para números originais...
DBCC UPDATEUSAGE (Northwind,'Tab1') WITH COUNT_ROWS;
DBCC UPDATEUSAGE (Northwind,'Tab2') WITH COUNT_ROWS;
GO


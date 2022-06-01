/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



----------------------------------------
----------- Valores faltando -----------
----------------------------------------
/*
  Escreva uma consulta que retorne todos os dias sem vendas dentro
  de todo o período de vendas existente.
  Sendo data inicial primeira venda, e data final a última venda.
  Em outras palavras, os valores faltantes.
*/

USE TempDB
GO
IF OBJECT_ID('tempdb.dbo.#TMPPedidos') IS NOT NULL
  DROP TABLE #TMPPedidos
GO
CREATE TABLE #TMPPedidos (ID_Pedido Integer, Data_Pedido Date)
GO
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10369','19961202')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10371','19961203')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10372','19961204')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10374','19961205')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10375','19961206')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10377','19961209')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10378','19961210')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10379','19961211')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10381','19961212')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10382','19961213')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10384','19961216')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10385','19961217')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10387','19961218')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10388','19961219')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10389','19961220')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10391','19961223')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10392','19961224')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10394','19961225')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10395','19961226')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10397','19961227')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10398','19961230')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10399','19961231')
GO

SELECT * FROM #TMPPedidos
GO

IF OBJECT_ID('fnSequencial', 'IF') IS NOT NULL
  DROP FUNCTION dbo.fnSequencial
GO
CREATE FUNCTION dbo.fnSequencial (@i Int)
RETURNS TABLE
AS
RETURN 
(
 WITH L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
     L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
     L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
     L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
     L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
     L5   AS(SELECT 1 AS C FROM L4 AS A CROSS JOIN L4 AS B), -- 4,294,967,296 rows
     Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L5)

SELECT TOP (@i) N AS Num
  FROM Nums
)
GO
/*
  SELECT * FROM dbo.fnSequencial(10)
*/

;WITH CTE_1
AS
(
  SELECT MIN(Data_Pedido) AS Menor_Data, 
         DATEDIFF(day, MIN(Data_Pedido), MAX(Data_Pedido)) AS Col1
    FROM #TMPPedidos
),
CTE_2
AS
(
SELECT *, DATEADD(day, fnSequencial.Num, Menor_Data) AS TodasDatas
  FROM CTE_1
 CROSS APPLY dbo.fnSequencial(CTE_1.Col1)
)
SELECT TodasDatas AS DataSemVenda
  FROM CTE_2
 WHERE NOT EXISTS(SELECT *
                    FROM #TMPPedidos
                   WHERE #TMPPedidos.Data_Pedido = CTE_2.TodasDatas)
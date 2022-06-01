----------------------------------------
--------- Identificando Gaps -----------
----------------------------------------
/*
  Escreva uma consulta que retorne o período inicial e final
  de cada GAP nas vendas.
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

-- Resultado desejado
/*
  PeriodoInicial PeriodoFinal
  -------------- ------------
  1996-12-07     1996-12-08
  1996-12-14     1996-12-15
  1996-12-21     1996-12-22
  1996-12-28     1996-12-29
*/


-- Caso valores não sejam sequenciais
;WITH TempCTE
AS
(
  SELECT ID_Pedido,
         Data_Pedido AS Data_Pedido,
         ROW_NUMBER() OVER(ORDER BY Data_Pedido) Rn
    FROM #TMPPedidos
)
SELECT DISTINCT
       DateAdd(d, 1, LinhaAtual.Data_Pedido) AS "PeriodoInicial",
       DateAdd(d, -1, ProximaLinha.Data_Pedido) AS "PeriodoFinal"
  FROM TempCTE AS LinhaAtual
 INNER JOIN TempCTE AS ProximaLinha
    ON LinhaAtual.rn + 1 = ProximaLinha.rn 
 WHERE DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido) > 1;
GO

/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

---------------------------
-- Estatísticas em views --
---------------------------

USE Northwind
GO

-- Preparando base
WITH CTE_1
AS
(
  SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
    FROM OrdersBig
   INNER JOIN Order_DetailsBig
      ON OrdersBig.OrderID = Order_DetailsBig.OrderID
)
UPDATE CTE_1 SET Shipped_Date = DATEADD(d, ABS(CHECKSUM(NEWID())) / 100000000 + 1, OrderDate)
GO
UPDATE STATISTICS OrdersBig WITH FULLSCAN
UPDATE STATISTICS Order_DetailsBig WITH FULLSCAN
GO

-- Query para fazer validação de consistência dos dados
-- Existe algum item com data de entrega menor que a 
-- data do pedido?
-- Estimativa é muito ruim pois SQL não sabe que existe uma 
-- relação entre as colunas
SELECT * FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE Order_DetailsBig.Shipped_Date < OrdersBig.OrderDate
GO

-- Mundo perfeito 1!
CREATE STATISTICS Stats1
AS
SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
GO

-- Mundo quase perfeito!
IF OBJECT_ID('vw_View1') IS NOT NULL
  DROP VIEW vw_View1
GO
CREATE VIEW vw_View1
WITH SCHEMABINDING
AS
SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
  FROM dbo.OrdersBig
 INNER JOIN dbo.Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
GO

CREATE STATISTICS Stats1 ON vw_View1(Shipped_Date, OrderDate)
GO

-- Mundo "pelo menos isso" perfeito!
IF OBJECT_ID('vw_View1') IS NOT NULL
  DROP VIEW vw_View1
GO
CREATE VIEW vw_View1
WITH SCHEMABINDING
AS
SELECT OrdersBig.OrderID,
       Order_DetailsBig.ProductID,
       Order_DetailsBig.Shipped_Date,
       OrdersBig.OrderDate
  FROM dbo.OrdersBig
 INNER JOIN dbo.Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
GO

-- Para criar uma estatística em view o SQL requer um índice cluster
CREATE UNIQUE CLUSTERED INDEX ix1 ON vw_View1(OrderID, ProductID)
GO

-- Estimativa continua errada
SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE Order_DetailsBig.Shipped_Date < OrdersBig.OrderDate
GO

-- Criando a estatística para ajudar o otimizador
-- DROP STATISTICS vw_View1.Stats1
CREATE STATISTICS Stats1 ON vw_View1(Shipped_Date, OrderDate)
GO

-- Continua não usando
SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE Order_DetailsBig.Shipped_Date < OrdersBig.OrderDate
GO

-- Mundo "nem isso?" perfeito!

-- Select tem que ser na view e com o hint NOEXPAND
-- Continua usando a densidade e gerando estimativa errada
SELECT Shipped_Date, OrderDate
  FROM Vw_View1 WITH(NOEXPAND)
 WHERE Shipped_Date < OrderDate
GO

-- Consultar estatísticas da view 
-- criou 2 estatísticas uma para a coluna OrderDate e outra pra
-- Shipped_Date
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('Vw_View1')
 GO

 -- Mundo real

 -- Teriamos que criar a view indexada já com o filtro
IF OBJECT_ID('vw_View1') IS NOT NULL
  DROP VIEW vw_View1
GO
CREATE VIEW vw_View1
WITH SCHEMABINDING
AS
SELECT OrdersBig.OrderID,
       Order_DetailsBig.ProductID,
       Order_DetailsBig.Shipped_Date,
       OrdersBig.OrderDate
  FROM dbo.OrdersBig
 INNER JOIN dbo.Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE Order_DetailsBig.Shipped_Date < OrdersBig.OrderDate
GO

-- Para criar uma estatística em view o SQL requer um índice cluster
CREATE UNIQUE CLUSTERED INDEX ix1 ON vw_View1(OrderID, ProductID)
GO

-- Estimativa correta, porém a view só serve pra isso...
-- e o custo para mante-la é muito alto...
SELECT Order_DetailsBig.Shipped_Date, OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN Order_DetailsBig
    ON OrdersBig.OrderID = Order_DetailsBig.OrderID
 WHERE Order_DetailsBig.Shipped_Date < OrdersBig.OrderDate
GO



/* 
  Espero muito ver novidades em relação a este assunto no SQL Server, 
  existe uma patente sobre "statistics on views" para a Microsoft
  http://www.google.com/patents/US7509311 -- Use of statistics on views in query optimization    
*/
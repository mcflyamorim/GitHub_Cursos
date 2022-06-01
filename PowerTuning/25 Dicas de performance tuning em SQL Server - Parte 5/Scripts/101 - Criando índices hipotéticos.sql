USE NorthWind
GO

/*
  Hypothetical Indexes
*/

-- Criando um índice comum
CREATE INDEX ix_OrderDate_Comum ON OrdersBig(OrderDate)
GO
DROP INDEX OrdersBig.ix_OrderDate_Comum
GO

-- Criando um índice hipotético
-- DROP INDEX OrdersBig.ix_OrderDate_Hipotetico
CREATE INDEX ix_OrderDate_Hipotetico ON OrdersBig(OrderDate) WITH STATISTICS_ONLY = -1
GO

-- Visualizando o índice
sp_HelpIndex OrdersBig
GO

-- Visualizando as estatísticas do índice
DBCC SHOW_STATISTICS(OrdersBig, ix_OrderDate_Hipotetico)
GO


-- Tentando usar o índice
SELECT * 
  FROM OrdersBig WITH(index=ix_OrderDate_Hipotetico)
 WHERE OrderDate = '20100101'
GO

-- Usando o indexid
SELECT * 
  FROM OrdersBig WITH(index=3)
 WHERE OrderDate = '20100101'
GO


-- Custo da consulta sem o índice alto
-- Clustered Index Scan na pk
SELECT * 
  FROM OrdersBig
 WHERE OrderDate = '20100101'
GO

-- Pergunta: Como simular o uso do índice hipotético?




-- Lendo dados necessários para rodar o comando DBCC AUTOPILOT
SELECT name, id, Indid, Dpages, rowcnt 
  FROM sysindexes
 WHERE id = object_id('OrdersBig')
GO

-- Visualizando a sintaxe do comando
DBCC TRACEON (2588)
DBCC HELP ('AUTOPILOT')
GO
/*
  dbcc AUTOPILOT (typeid [, dbid [, {maxQueryCost | tabid [, indid [, pages [, flag [, rowcounts]]]]} ]])
*/
SELECT DB_ID('NorthWind')
GO


DBCC AUTOPILOT (0, 5, 1330103779, 1) -- Índice cluster
DBCC AUTOPILOT (0, 5, 1330103779, 5) -- Índice ix_OrderDate_Hipotetico
GO
SET AUTOPILOT ON
GO
SELECT *
  FROM OrdersBig
 WHERE OrderDate = '20120315'
GO
SET AUTOPILOT OFF
GO



-- Que tal usar a proc st_TestHipotheticalIndexes ?

-- Exemplo 1
EXEC dbo.st_TestHipotheticalIndexes @SQLIndex = 'CREATE INDEX ix_12 ON Products (Unitprice, CategoryID, SupplierID) INCLUDE(ProductName);CREATE INDEX ix_Quantity ON Order_Details (Quantity);', 
                                    @Query = 'SELECT p.ProductName, p.UnitPrice, s.CompanyName, s.Country, od.quantity
                                                FROM Products as P
                                               INNER JOIN Suppliers as S
                                                  ON P.SupplierID = S.SupplierID
                                               INNER JOIN order_details as od
                                                  ON p.productID = od.productid
                                               WHERE P.CategoryID in (1,2,3) 
	                                                AND P.Unitprice < 20
	                                                AND S.Country = ''uk'' 
	                                                AND od.Quantity < 90'

-- Exemplo 2
EXEC dbo.st_TestHipotheticalIndexes @SQLIndex = 'CREATE INDEX ix ON ProductsBig (ProductName);',
                                    @Query = 'SELECT * FROM ProductsBig WHERE ProductName = ''Mishi Kobe Niku 1A11B764'''
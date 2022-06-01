USE Northwind
GO

IF OBJECT_ID('TestTabXML') IS NOT NULL
  DROP TABLE TestTabXML
GO

CREATE TABLE TestTabXML
(
  ID INT PRIMARY KEY, 
  ColXML XML
)
GO


-- Inserir 20 mil linhas...
-- Aprox 3 minutos para rodar...
SET NOCOUNT ON
DECLARE @counter INT = 1
DECLARE @row VARCHAR(MAX) 
WHILE @counter <= 30000
BEGIN
 
  WITH Orders AS
  (
    --use ROW_NUMBER() to enumerate SalesOrderHeader records
    SELECT ROW_NUMBER() OVER(ORDER BY SalesOrderID) AS RowNum, *
    FROM AdventureWorks2012.Sales.SalesOrderHeader
  ) 
  SELECT @row = (
        SELECT  o.SalesOrderID AS '@SalesOrderID',
          o.OrderDate,
          o.PurchaseOrderNumber,
          o.SalesPersonID,
          (
            --associated SalesOrderDetail records
            SELECT  d.SalesOrderDetailID  AS '@SalesOrderDetailID',
              d.OrderQty,
              d.rowguid AS 'RowGUID',
              d.ProductID,
              d.LineTotal,
              d.UnitPrice
            FROM AdventureWorks2012.Sales.SalesOrderDetail AS d
            WHERE o.SalesOrderID = d.SalesOrderID
            FOR XML PATH('SalesOrderDetail'), TYPE
           ) AS SalesOrderDetails
        FROM Orders AS o 
        WHERE o.RowNum = @counter
        FOR XML PATH('SalesOrder'), ROOT('SalesOrders')
      )
 
  INSERT TestTabXML VALUES(@counter, CONVERT(XML,@row))
 
  SET @counter += 1
END
GO


-- Selecionar todos registros de SalesPersonID = 278 ...
-- Ver XML... Pedidos e detalhes dos itens...
SELECT * 
  FROM TestTabXML
 WHERE ColXML.exist('/SalesOrders/SalesOrder/SalesPersonID[.=278]') = 1
GO


SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT * 
  FROM TestTabXML
 WHERE ColXML.exist('/SalesOrders/SalesOrder/SalesPersonID[.=278]') = 1
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO


-- Se necessário... Habilitar sp_db_selective_xml_index no DB
-- EXECUTE NorthWind.sys.sp_db_selective_xml_index Sales_XML, TRUE


-- Criar índice selective em 
-- DROP INDEX ix_Selective_SalesPersonID ON TestTabXML
CREATE SELECTIVE XML INDEX ix_Selective_SalesPersonID
ON TestTabXML(ColXML)
FOR 
(
    pathSalesPersonID = '/SalesOrders/SalesOrder/SalesPersonID'
)
GO


SET STATISTICS TIME ON
SET STATISTICS IO ON
SELECT * 
  FROM TestTabXML
 WHERE ColXML.exist('/SalesOrders/SalesOrder/SalesPersonID[.=278]') = 1
SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO



-- https://www.simple-talk.com/sql/learn-sql-server/precision-indexing-basics-of-selective-xml-indexes-in-sql-server-2012/

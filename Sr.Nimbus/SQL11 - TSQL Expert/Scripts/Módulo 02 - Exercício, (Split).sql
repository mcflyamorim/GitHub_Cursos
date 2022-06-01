USE Northwind
GO

-- Preparando demo
IF NOT EXISTS(SELECT * FROM sysindexes WHERE name = 'ixCustomerID' and id = OBJECT_ID('OrdersBig'))
  CREATE INDEX ixCustomerID ON OrdersBig (CustomerID)
GO
IF OBJECT_ID('tempdb.dbo.#tmp') IS NOT NULL
  DROP TABLE #TMP
GO
SELECT TOP 1000
       CustomerID,
       ContactName,
       (SELECT CONVERT(VarChar(30), OrderID) + ';' AS "text()"
          FROM OrdersBig 
         WHERE OrdersBig.CustomerID = CustomersBig.CustomerID FOR XML PATH('')) AS Col1
  INTO #TMP
  FROM CustomersBig
GO
UPDATE #TMP SET Col1 = SUBSTRING(Col1, 0, LEN(Col1))
GO


---------------------------------
--- Split da coluna #TMP.Col1 ---
---------------------------------
/*
  Escreva uma consulta que retorne informações
  da coluna Col1 em uma tabela.
  Retornar CustomerID e OrderID ("desplitado")

  Banco: NorthWind
  Tabelas: #TMP
*/

-- Exemplo resultado esperado:
/*
  CustomerID	OrderID
  1 	        14920
  1 	        26312
  1	         57422
  ...
*/
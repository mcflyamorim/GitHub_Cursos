/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

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


-- Criando function para fazer split
IF OBJECT_ID('fn_Split') IS NOT NULL
  DROP FUNCTION dbo.fn_Split
GO
CREATE FUNCTION dbo.fn_Split (@RowData nvarchar(MAX), @SplitOn nvarchar(5))
RETURNS @ReturnValue 
  TABLE (Data NVARCHAR(MAX))
AS
BEGIN
  Declare @Counter int
  Set @Counter = 1
  While (Charindex(@SplitOn,@RowData)>0)
  Begin  
    Insert Into @ReturnValue (data)  
    Select Data =
        ltrim(rtrim(Substring(@RowData,1,Charindex(@SplitOn,@RowData)-1)))
    Set @RowData =
        Substring(@RowData,Charindex(@SplitOn,@RowData)+1,len(@RowData))
    Set @Counter = @Counter + 1  
  End
  Insert Into @ReturnValue (data)  
  Select Data = ltrim(rtrim(@RowData))  
  Return  
END
GO

SELECT * 
  FROM dbo.fn_Split ('1;2;3;4;5', ';')
GO

-- Criar function em CLR


-- Exemplos


-- Solução com XML
SELECT CustomerID,
       Tab1.ColXML.value('@Ind', 'VarChar(80)') AS Value
  FROM (SELECT *,
               CONVERT(XML, '<Test Ind="' + Replace(Col1, ';','"/><Test Ind="') + '"/>') AS ColXML
          FROM #TMP) AS Tab
CROSS APPLY Tab.ColXML.nodes('/Test') As Tab1 (ColXML)
ORDER BY CustomerID
GO

-- Solução "nativa"
SELECT CustomerID, Data AS OrderID
  FROM #TMP
 CROSS APPLY dbo.fn_Split(Col1, ';')
ORDER BY CustomerID
GO

-- Solução com CLR
SELECT CustomerID, fn_CLRSplit.Output AS OrderID
  FROM #TMP
 CROSS APPLY dbo.fn_CLRSplit(Col1, ';')
 ORDER BY CustomerID
GO
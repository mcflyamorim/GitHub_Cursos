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
       ISNULL(Tab1.Col, '') AS Col1
  INTO #TMP
  FROM CustomersBig
 CROSS APPLY ((SELECT CONVERT(VarChar(30), OrderID) + ';' AS "text()"
                 FROM OrdersBig 
                WHERE OrdersBig.CustomerID = CustomersBig.CustomerID 
                  FOR XML PATH(''))) AS Tab1 (Col)
  ORDER BY Tab1.Col DESC
GO
UPDATE #TMP SET Col1 = SUBSTRING(Col1, 0, LEN(Col1))
GO



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

-- Não use essa opção
SELECT * 
  FROM dbo.fn_Split ('1;2;3;4;5', ';')
GO

-- Criar function em CLR


-- Exemplos

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
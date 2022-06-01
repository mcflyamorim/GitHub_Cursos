USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- OFFSET FETCH NEXT do SQL 2012
DECLARE @NumeroPag AS INT, @LinhasPag AS INT
SET @NumeroPag = 1
SET @LinhasPag = 100

SELECT * 
  FROM OrdersBig
ORDER BY OrderID
OFFSET ((@NumeroPag - 1) * @LinhasPag) ROWS
FETCH NEXT @LinhasPag ROWS ONLY;
GO

-- Coluna que não tem índice vai precisar de um Sort
DECLARE @NumeroPag AS INT, @LinhasPag AS INT
SET @NumeroPag = 1
SET @LinhasPag = 100

SELECT * 
  FROM OrdersBig
ORDER BY Value
OFFSET ((@NumeroPag - 1) * @LinhasPag) ROWS
FETCH NEXT @LinhasPag ROWS ONLY;
GO

-- Com OPTION recompile QO consegue usar o algorítmo otimizado pra
-- processar até 100 linhas... (Internals Módulo 3, Memória Parte 2 - Demo - SortWarning TOP101.mp4)
DECLARE @NumeroPag AS INT, @LinhasPag AS INT
SET @NumeroPag = 1
SET @LinhasPag = 100

SELECT * 
  FROM OrdersBig
ORDER BY Value
OFFSET ((@NumeroPag - 1) * @LinhasPag) ROWS
FETCH NEXT @LinhasPag ROWS ONLY
OPTION (RECOMPILE);
GO


-- E antes do SQL2012? 
DECLARE @NumeroPag AS INT, @LinhasPag AS INT
SET @NumeroPag = 2
SET @LinhasPag = 10

;WITH CTE_1
AS
(
  SELECT *, ROW_NUMBER() OVER(ORDER BY OrderID) AS rn
    FROM OrdersBig
)
SELECT *
  FROM CTE_1
 WHERE rn BETWEEN ((@NumeroPag - 1) * @LinhasPag + 1) AND (@NumeroPag * @LinhasPag)
GO


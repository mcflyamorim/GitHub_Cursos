USE Northwind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(DATETIME, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

-- Proc pra retornar dados com filtro em OrderDate
DROP PROC IF EXISTS st_1
GO
CREATE PROC st_1 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT *
  FROM OrdersBig
 WHERE OrderDate >= @dt1 
   AND OrderDate < DATEADD(DAY , 1, @dt2)
 ORDER BY Value
OPTION (MAXDOP 1)
GO

-- Testando a proc
-- Estimativa correta... 
EXEC st_1 @dt1 = '20210101', @dt2 = '20210110'
GO

-- Mas e se eu quiser usar apenas filtro de data inicial?
-- Nesse caso, passar NULL pra @dt2 não funciona...
EXEC st_1 @dt1 = '20210101', @dt2 = NULL
GO

-- Vamos modificar a proc pra tratar os NULL
DROP PROC IF EXISTS st_1
GO
CREATE PROC st_1 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT *
  FROM OrdersBig
 WHERE OrderDate >= ISNULL(@dt1, '99991231')
   AND OrderDate < ISNULL(DATEADD(DAY , 1, @dt2), '99991231')
 ORDER BY Value
OPTION (MAXDOP 1)
GO

-- E a estimativa, como ficou? 
EXEC st_1 @dt1 = '20210101', @dt2 = NULL
GO

-- Recompile resolve... Mas e se eu não puder usar recompile por causa do custo? 
DROP PROC IF EXISTS st_1
GO
CREATE PROC st_1 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT *
  FROM OrdersBig
 WHERE OrderDate >= ISNULL(@dt1, '99991231')
   AND OrderDate < ISNULL(DATEADD(DAY , 1, @dt2), '99991231')
 ORDER BY Value
OPTION (RECOMPILE, MAXDOP 1)
GO

-- Com recompile, estimativa correta, e não faz spill
EXEC st_1 @dt1 = '20210101', @dt2 = NULL
GO

-- Pra evitar problema na estimativa 
-- podemos fazer assim... 
DROP PROC IF EXISTS st_1
GO
CREATE PROC st_1 @dt1 DATETIME, @dt2 DATETIME
AS
SELECT *
  FROM OrdersBig
 WHERE (OrderDate >= @dt1 OR @dt1 IS NULL) 
   AND (OrderDate < DATEADD(DAY , 1, @dt2) OR @dt2 IS NULL)
 ORDER BY Value
OPTION (MAXDOP 1)
GO

EXEC st_1 @dt1 = '20210101', @dt2 = NULL
GO


-- Outro exemplo
USE Northwind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(DATE, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
INSERT INTO OrdersBig
(
    CustomerID,
    OrderDate,
    Value
)
SELECT TOP 50000
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       NULL AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO

-- Gambiarra com SET ANSI_NULLS OFF na hora de criar a proc...
-- Não seje essa pessoa que faz isso, please...
DROP PROC IF EXISTS st_1
GO
SET ANSI_NULLS OFF
GO
CREATE PROC st_1 @dt1 DATETIME
AS
SELECT *
  FROM OrdersBig
 WHERE OrderDate = @dt1
 ORDER BY Value
OPTION (MAXDOP 1)
GO
-- Volta pro default...
SET ANSI_NULLS ON
GO


-- Agora funciona
EXEC st_1 @dt1 = NULL
GO


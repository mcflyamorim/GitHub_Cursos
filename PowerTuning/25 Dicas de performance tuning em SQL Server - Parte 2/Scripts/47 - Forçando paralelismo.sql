/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

EXEC sys.sp_configure N'cost threshold for parallelism', N'100'
GO
RECONFIGURE WITH OVERRIDE
GO


IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 10000000
       IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 10000000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Não gera plano em paralelo...
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
-- Cost = 70
-- +- 20 segundos para rodar
SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
GO


-- Basta fazer o cross apply com a make_parallel() :-)
-- Melhor usar essa opção... pois é suportada pela MS... TF8649 é outra opção, mas não é "suportada" (já usei muito em prod)
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
-- Cost = Eita -- 991775
-- +- 20 segundos para rodar
SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 CROSS APPLY dbo.make_parallel()
OPTION (MAXDOP 12) 
-- Se necessário, posso forçar o MAXDOP pra fazer considerar + cores do que está config na instância
-- Nego que gosta de colocar maxdop 8 em uma maq com 256 CPUs... 
-- você pode ter queries mais rápidas usando + threads mudando o maxdop
GO

-- Qual código é mais rápido? 
-- Depende né...

-- http://sqlblog.com/blogs/adam_machanic/archive/2013/07/11/next-level-parallel-plan-porcing.aspx
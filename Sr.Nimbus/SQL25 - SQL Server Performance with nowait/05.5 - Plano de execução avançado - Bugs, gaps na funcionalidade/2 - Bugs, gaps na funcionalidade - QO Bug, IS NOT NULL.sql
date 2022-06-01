/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

-- Preparar demo
-- 41 segundos para rodar...
IF OBJECT_ID('OrdersBigBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBigBig
END
GO
CREATE TABLE [dbo].[OrdersBigBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBigBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 100000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM OrdersBig A
 CROSS JOIN OrdersBig B
 CROSS JOIN OrdersBig C
 CROSS JOIN OrdersBig D
GO
ALTER TABLE OrdersBigBig ADD CONSTRAINT xpk_OrdersBigBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
  DROP TABLE CustomersBig
END
GO
SELECT TOP 1000000 
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
-- inserir cinco mil cidades
INSERT INTO Cities
        ( CityName, Col1, Col2 )
VALUES  ( NEWID(), -- CityName - varchar(200)
          '', -- Col1 - varchar(250)
          ''  -- Col2 - varchar(250)
          )
GO 5000
UPDATE STATISTICS Cities WITH FULLSCAN
GO


-- Deixar somente 10 Customers com Cidade cadastrada
UPDATE CustomersBig SET CityID = NULL
WHERE CustomerID > 10
GO

-- Criar um índice por CityID na tabela de Customers
CREATE INDEX ixCityID ON CustomersBig (CityID) INCLUDE(ContactName)
GO
-- Criar índice na FK de OrdersBig X CustomersBig
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
GO


DBCC FREEPROCCACHE()
GO
/* 
  Query 1: Selecionar todos os Pedidos de Clientes com Cidade cadastrada 
  (WHERE CityID IS NOT NULL)
  Query bem otimizada fazendo um seek em Customers.ix usando o SeekPredicate "IsNotNull"
  Optimization Level = FULL
*/
SELECT OrdersBig.OrderID, 
       CustomersBig.ContactName, 
       Cities.CityName
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 INNER JOIN Cities
    ON CustomersBig.CityID = Cities.CityID
 WHERE CustomersBig.CityID IS NOT NULL
GO

/* 
  Query 2: Exatamente a mesma consulta que a Query 1, 
  porém agora estou usando o Hint WITH(RECOMPILE)
  Plano pior comparado ao primeiro
  Obs.: No SQL 2005 o QO gera o mesmo plano que o a Query 1
*/
SELECT OrdersBig.OrderID, 
       CustomersBig.ContactName, 
       Cities.CityName
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 INNER JOIN Cities
    ON CustomersBig.CityID = Cities.CityID
 WHERE CustomersBig.CityID IS NOT NULL
OPTION (RECOMPILE, MAXDOP 1)
GO


-- Como resolver o problema ?(a.k.a. workarounds)

/*
  Alternativa 1:fazer o filtro em uma consulta derivada.
*/ 
SELECT OrdersBig.OrderID, Tab.ContactName, Cities.CityName
  FROM (SELECT CustomerID, CityID, ContactName
          FROM CustomersBig
         WHERE CustomersBig.CityID IS NOT NULL) AS Tab
 INNER JOIN Cities
    ON Tab.CityID = Cities.CityID
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = Tab.CustomerID
OPTION (RECOMPILE)
GO

/*
  Alternativa 2: Forçar o Seek usando o hint FORCESEEK (somente SQL2008)
*/ 
SELECT OrdersBig.OrderID, CustomersBig.ContactName, Cities.CityName
  FROM CustomersBig WITH(FORCESEEK)
 INNER JOIN Cities
    ON CustomersBig.CityID = Cities.CityID
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.CityID IS NOT NULL
OPTION (RECOMPILE)
GO

/*
  Alternativa 3: Usar o ISNULL na coluna Cidade
  ISNULL Não é SARGable, mas o QO o torna SARGable
  trocando o filtro pela expressão:
  "CityID < -1 AND CityID > -1"
*/ 
SELECT OrdersBig.OrderID, CustomersBig.ContactName, Cities.CityName
  FROM CustomersBig
 INNER JOIN Cities
    ON CustomersBig.CityID = Cities.CityID
 INNER JOIN OrdersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE ISNULL(CustomersBig.CityID,-1) <> -1
OPTION (RECOMPILE)
GO


-- Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/587729/query-optimizer-create-a-bad-plan-when-is-not-null-predicate-is-used#details

-- Chupa essa Fabiano, seu chorão...
/*
  Hello,
  After carefully evaluating all of the suggestion items in 
  our pipeline, 
  we are closing items that we will not implement in the 
  near future 
  due to current higher priority items. 
  We will re-evaluate the closed suggestions again in the future 
  based on the product roadmap.
  Thanks again for providing the product suggestion and 
  continued support for our product.
  --
  Jos de Bruijn - SQL Server PM
*/
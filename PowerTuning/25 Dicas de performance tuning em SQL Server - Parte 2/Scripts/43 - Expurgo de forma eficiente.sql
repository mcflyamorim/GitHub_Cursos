/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO
-- Preparar ambiente... 
-- 2 segundos para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO



IF EXISTS(SELECT * FROM sys.partition_schemes WHERE name = 'psche')
  DROP PARTITION SCHEME psche
GO

IF EXISTS(SELECT * FROM sys.partition_functions WHERE name = 'pfunc')
  DROP PARTITION FUNCTION pfunc
GO

-- Cria a função da partição para definir o Range
CREATE PARTITION FUNCTION pfunc (int)
AS RANGE LEFT FOR VALUES (2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
GO

-- Cria o schema da partição para mapear a função da partição para o FileGroup(s)
-- DROP PARTITION SCHEME psche
CREATE PARTITION SCHEME psche
AS PARTITION pfunc ALL TO ([Primary])
GO


-- Criar coluna para ser utilizada na chave da partição
-- ALTER TABLE OrdersBig DROP COLUMN YearOrderDate
ALTER TABLE OrdersBig ADD YearOrderDate AS ISNULL(YEAR(OrderDate),1900) PERSISTED
GO
-- ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK

-- Recriar a PK
ALTER TABLE OrdersBig DROP CONSTRAINT [xpk_OrdersBig]
-- ALTER TABLE OrdersBig ADD CONSTRAINT [xpk_OrdersBig] PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig ADD CONSTRAINT [xpk_OrdersBig] PRIMARY KEY(OrderID, YearOrderDate) ON psche(YearOrderDate)
GO

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBig b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBig a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Criar tabela para receber dados históricos ou ser removida...
IF OBJECT_ID('OrdersBigHistory') IS NOT NULL
  DROP TABLE OrdersBigHistory
GO
CREATE TABLE OrdersBigHistory([OrderID] [int] NOT NULL IDENTITY(1, 1),
                              [CustomerID] [int] NULL,
                              [OrderDate] [date] NULL,
                              [Value] [numeric] (18, 2) NOT NULL,
                              YearOrderDate AS ISNULL(YEAR(OrderDate),1900) PERSISTED) ON psche(YearOrderDate)
GO
ALTER TABLE OrdersBigHistory ADD CONSTRAINT [xpk_OrdersBigHistory] PRIMARY KEY(OrderID, YearOrderDate) ON psche(YearOrderDate)
GO


-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBigHistory b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBigHistory a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Fazer expurgo da primeira partição
-- Move a primeira partição da tabela OrdersBig para a primeira partição da tabela OrdersBigHistory
ALTER TABLE OrdersBig SWITCH PARTITION 1 TO OrdersBigHistory PARTITION 1
ALTER TABLE OrdersBig SWITCH PARTITION 2 TO OrdersBigHistory PARTITION 2
ALTER TABLE OrdersBig SWITCH PARTITION 3 TO OrdersBigHistory PARTITION 3
...
ALTER TABLE OrdersBig SWITCH PARTITION 6 TO OrdersBigHistory PARTITION 6
GO


-- Verifica os dados da tabela OrdersBigHistory
SELECT * FROM OrdersBigHistory
GO


-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBig b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBig a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBigHistory b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBigHistory a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Limitações
-- Transferring Data Efficiently by Using Partition Switching
-- ms-help://MS.SQLCC.v10/MS.SQLSVR.v10.en/s10de_1devconc/html/e3318866-ff48-4603-a7af-046722a3d646.htm


-- Da um trabalho né? criar a tabela nova e fazer o switch??... se você tiver SQL 2016, pode tentar o seguinte:

-- WOW! Nice!
TRUNCATE TABLE OrdersBig
WITH (PARTITIONS (1 TO 5));
GO


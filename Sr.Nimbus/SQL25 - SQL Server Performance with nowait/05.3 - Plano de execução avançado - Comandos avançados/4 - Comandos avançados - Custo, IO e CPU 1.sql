/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Desabilitar default trace para não atrapalhar no monitoramento do ProcessExplorer
EXEC master.dbo.sp_configure 'default trace enabled', 0;
GO
RECONFIGURE WITH OVERRIDE;
GO



DBCC TRACEON(3604) WITH NO_INFOMSGS 
GO

-- Mostra peso atual...
DBCC SHOWWEIGHTS WITH NO_INFOMSGS 
GO


/*
  -- Seta custo padrão
  DBCC SETIOWEIGHT(1) WITH NO_INFOMSGS
  DBCC SETCPUWEIGHT(1) WITH NO_INFOMSGS
*/


------------- IO -----------
------- Testar mais --------

-- Criar novo banco para testes no HD Externo
--USE master
--GO
--DROP DATABASE [DBTestCosts]
--GO

--CREATE DATABASE [DBTestCosts]
-- ON  PRIMARY 
--( NAME = N'DBTestCosts', FILENAME = N'D:\Temp\DBTestCosts.mdf' , SIZE = 1048576KB , FILEGROWTH = 1024KB )
-- LOG ON 
--( NAME = N'DBTestCosts_log', FILENAME = N'D:\Temp\DBTestCosts_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
--GO

USE DBTestCosts
GO
-- Preparar ambiente... 
-- Criar tabelas com 1 milhões de linhas e páginas, cabe apenas 1 linha por página(vide Col1)...
-- 1 hora e 15 mins para rodar
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       ISNULL(CONVERT(Char(7000), NewID()), '') AS Col1
  INTO OrdersBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixValue ON OrdersBig(Value)
GO


-- Criar mesma tabela no SSD
USE Northwind
GO

-- Confirmar se o banco Northwind está no SSD (C:\)
SELECT * FROM sysfiles
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       ISNULL(CONVERT(Char(7000), NewID()), '') AS Col1
  INTO OrdersBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixValue ON OrdersBig(Value)
GO


-- Teste custo I/O

/*
  Cost is elapsed time in seconds
  Random 		0.003125 = 1/320 
  Sequential 		0.00074074 = 1/1350
  Random: 		320 IOPS
  Sequential 		1350 pages/sec, or 10.8MB/s
*/


-- Teste custo I/O - HDD
USE DBTestCosts
GO

-- Criar tabela com 1 linha por página para testes
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
CREATE TABLE Tab1 (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Int, Col2 Int, Col3 Char(7000))
GO
INSERT INTO Tab1 (Col1, Col2, Col3) VALUES(1, 1, 'Fabiano 1')
GO
CHECKPOINT;
GO

/*
  Quanto tempo de fato demorou para executar a operação de I/O ?
  Ver duration com ProcessMonitor
  Filtrar por:
    PID = SQL
    Path = E:\temp\DBTestCosts.mdf
    Path = C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012\MSSQL\Data\northwnd.mdf
*/

DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;

-- Custo de uma operação (uma página) aleatória de I/O = 0,003125
DECLARE @I BigInt
SELECT @i = COUNT_Big(*)
  FROM DBTestCosts.dbo.Tab1
OPTION (RECOMPILE)
GO 1000




-- Teste custo I/O - SSD
USE Northwind
GO
-- Criar tabela com 1 linha por página para testes
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
CREATE TABLE Tab1 (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Int, Col2 Int, Col3 Char(7000))
GO
INSERT INTO Tab1 (Col1, Col2, Col3) VALUES(1, 1, 'Fabiano 1')
GO
CHECKPOINT;
GO


/*
  Quanto tempo de fato demorou para executar a operação de I/O ?
  Ver duration com ProcessMonitor
  Filtrar por:
    PID = SQL
    Path = E:\temp\DBTestCosts.mdf
    Path = C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012\MSSQL\Data\northwnd.mdf
*/
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;
-- Custo de uma operação (uma página) aleatória de I/O = 0,003125
DECLARE @I BigInt
SELECT @i = COUNT_Big(*)
  FROM Northwind.dbo.Tab1
OPTION (RECOMPILE)
GO 1000


/*
  Média HDD = 0.009405915
  Média de 106 (1 / 0.009405915) IOs por segundo...

  Média SSD = 0.000390443
  Média de 2561 (1 / 0.000390443) IOs por segundo...

  Média fixa do SQL Server = 0.003125
  Média de 320 (1 / 0.003125) IOs por segundo...

  SELECT 1 / 0.003125 = 106
*/


-- Continuar testes no SSD
USE Northwind
GO

-- Vamos confirmar se para fazer 2 I/Os o custo muda?


-- Inserindo outra linha para gerar 2 I/Os
INSERT INTO Tab1 (Col1, Col2, Col3) VALUES(2, 2, 'Fabiano 2')
UPDATE STATISTICS Tab1 WITH FULLSCAN
GO
CHECKPOINT
GO

DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;
-- Custo de uma operação (uma página) aleatória de I/O = 0,003125
-- + custo de uma operação sequencial já que dados estão "ordenados" (scan no cluster)
-- = 0.00074074 ... 
-- Total = 0.003125 + 0.00074074 = 0.00386574
-- Bater com valor exibido no plano!
DECLARE @I BigInt
SELECT @i = COUNT_Big(*)
  FROM Northwind.dbo.Tab1
OPTION (RECOMPILE)
GO


-- Porque isso importa? 

-- SQL Server subestima o custo/tempo para executar operações de I/O...
-- Meu SSD consegue ler em menos tempo e com custo menor para operações aleatórias


-- Exemplo, com o clássico Seek+Lookup

-- Até quando vale a pena usar o índice por Value?

SET STATISTICS IO ON
GO

-- Cold Cache
DBCC TRACEON(652) --Desabilitar read ahead
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

-- Quanto tempo para fazer o scan? (validar se plano gerou scan)
-- Plano sem forçar nada...
-- Média de 2mins e 2/9 segundos para rodar...
SET STATISTICS IO ON
DECLARE @Col1 Int, @Col2 Int, @Col3 Date, @Col4 Numeric(18,2)
SELECT @Col1 = OrderID, @Col2 = CustomerID, @Col3 = OrderDate, @Col4 = Value
  FROM OrdersBig
 WHERE Value < 550
OPTION (MAXDOP 1, RECOMPILE)
GO

DBCC TRACEOFF(652)

-- Table 'OrdersBig'. Scan count 1, logical reads 1002003, physical reads 893250, read-ahead reads 0

-- Será que não compensava fazer o Seek+Lookup?
-- Consideremos o tempo de resposta como medida...
-- Média de 1 min e 2 segundos para rodar...
-- Cold Cache
CHECKPOINT; DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS; DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO
SET STATISTICS IO ON
DECLARE @Col1 Int, @Col2 Int, @Col3 Date, @Col4 Numeric(18,2)
SELECT @Col1 = OrderID, @Col2 = CustomerID, @Col3 = OrderDate, @Col4 = Value
  FROM OrdersBig WITH(FORCESEEK)
 WHERE Value < 550
OPTION (MAXDOP 1, RECOMPILE 
        ,QueryRuleOff EnforceSort -- Desabilitar Sort explícito
       )
GO
-- Table 'OrdersBig'. Scan count 1, logical reads 1489625, physical reads 345189, read-ahead reads 0

-- Aaaa, mas fez mais leituras de páginas... Sério, fez mesmo?... Look well!


-- Reduzir peso do I/O em 50%
DBCC SETIOWEIGHT(0.5e0) -- I/O multiplier = 0.5

-- Ver plano e custo de I/O
DECLARE @Col1 Int, @Col2 Int, @Col3 Date, @Col4 Numeric(18,2)
SELECT @Col1 = OrderID, @Col2 = CustomerID, @Col3 = OrderDate, @Col4 = Value
  FROM OrdersBig
 WHERE Value < 800
OPTION (MAXDOP 1, RECOMPILE 
        ,QueryRuleOff EnforceSort -- Desabilitar Sort explícito
       )
GO


-- Reset para valor padrão
DBCC SETIOWEIGHT(1) WITH NO_INFOMSGS
GO
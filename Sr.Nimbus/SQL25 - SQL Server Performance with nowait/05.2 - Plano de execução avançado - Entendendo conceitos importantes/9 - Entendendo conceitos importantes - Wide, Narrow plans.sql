/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-- Criar novo banco para testes no HD Externo
USE master
GO
DROP DATABASE [DBTestWideNarrowPlans]
GO

CREATE DATABASE [DBTestWideNarrowPlans]
 ON  PRIMARY 
( NAME = N'DBTestWideNarrowPlans', FILENAME = N'E:\Temp\DBTestWideNarrowPlans.mdf' , SIZE = 1048576KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'DBTestWideNarrowPlans_log', FILENAME = N'E:\Temp\DBTestWideNarrowPlans_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO

USE DBTestWideNarrowPlans
GO

-- Preparar ambiente... Criar tabelas com 5 milhões de linhas...
-- Tempo para criar tabela de aproximadamente 2 minutos...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 5000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
CREATE INDEX ixValue ON OrdersBig(Value)
GO


-- Delete para apagar dados de 2010
CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache"
BEGIN TRAN
GO

-- Para apagar várias linhas, gera wide plan com sort pela chave dos índices
-- para evitar leituras aleatórias...
-- Aprox. 41 segundos para rodar...
-- Ver response time no resource monitor
DELETE FROM OrdersBig
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (MAXDOP 1)
GO

-- 1 min para rollback
ROLLBACK TRAN
GO


CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache"
BEGIN TRAN
GO

-- Para apagar poucas linhas, gera narrow plan com delete de todos os índices em único operador.
-- Aprox. 1 min e 12 segundos para rodar...
-- Ver response time no resource monitor
DECLARE @Top Bigint = 9223372036854775807
DELETE TOP (@Top) FROM OrdersBig
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (MAXDOP 1, OPTIMIZE FOR(@Top = 10))
GO

ROLLBACK TRAN
GO



-- Qual é melhor? ... 
-- Depende do número de linhas sendo atualizadas e o custo das operações de sort versus leituras aleatórias



-- No SSD daria tanta diferença assim?

USE Northwind
GO
-- Confirmar se o banco Northwind está no SSD (C:\)
SELECT * FROM sysfiles
GO

-- Preparar ambiente... Criar tabelas com 5 milhões de linhas...
-- Tempo para criar tabela de aproximadamente 2 minutos...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 5000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Northwind.dbo.Orders A
 CROSS JOIN Northwind.dbo.Orders B CROSS JOIN Northwind.dbo.Orders C CROSS JOIN Northwind.dbo.Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

CREATE INDEX ixCustomerID ON OrdersBig(CustomerID)
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
CREATE INDEX ixValue ON OrdersBig(Value)
GO



-- Delete para apagar dados de 2010
CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache"
BEGIN TRAN
GO

-- Para apagar várias linhas, gera wide plan com sort pela chave dos índices
-- para evitar leituras aleatórias...
-- Aprox. 10 segundos para rodar...
-- Ver response time no resource monitor
DELETE FROM OrdersBig
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (MAXDOP 1)
GO

-- 5 segundos para rollback
ROLLBACK TRAN
GO


CHECKPOINT; DBCC FREEPROCCACHE; DBCC DROPCLEANBUFFERS; -- "cold cache"
BEGIN TRAN
GO

-- Para apagar poucas linhas, gera narrow plan com delete de todos os índices em único operador.
-- Aprox. 11/12 segundos para rodar...
-- Ver response time no resource monitor
DECLARE @Top Bigint = 9223372036854775807
DELETE TOP (@Top) FROM OrdersBig
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (MAXDOP 1, OPTIMIZE FOR(@Top = 10))
GO

ROLLBACK TRAN
GO



-- Poucas linhas = narrow plan ... Consigo forçar com TOP + OPTIMZE FOR... 
-- Muitas linhas = wide plan ... Consigo forçar com TOP + OPTIMIZE FOR ou TF 8790



-- TF 8790, Force a wide plan 
DECLARE @Top Bigint = 9223372036854775807
DELETE TOP (@Top) FROM OrdersBig
WHERE OrderDate BETWEEN '20100101' AND '20101231'
OPTION (MAXDOP 1, OPTIMIZE FOR(@Top = 10), QueryTraceON 8790)
GO

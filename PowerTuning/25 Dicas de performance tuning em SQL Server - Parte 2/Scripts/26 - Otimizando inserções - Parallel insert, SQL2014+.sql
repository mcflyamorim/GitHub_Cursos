/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

-- Rodar apenas se necessário
-- Criar tablea com 50 milhoes de linhas para efetuar os testes
IF OBJECT_ID('OrdersBig_v1') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig_v1
END
GO
SELECT TOP 50000000
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig_v1
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO


-- Colocar tabela em cache
SELECT COUNT(*) FROM OrdersBig_v1
GO


IF OBJECT_ID('OrdersBig_TestInsert') IS NOT NULL
  DROP TABLE OrdersBig_TestInsert
GO
-- Operação de Table Insert rodando em paralelo
SELECT *
  INTO OrdersBig_TestInsert
  FROM OrdersBig_v1
GO

-- Caso plano não esteja em paralello, podemos forçar utilizando o hint ENABLE_PARALLEL_PLAN_PREFERENCE
SELECT *
  INTO OrdersBig_TestInsert
  FROM OrdersBig_v1
OPTION(USE HINT('ENABLE_PARALLEL_PLAN_PREFERENCE'))
GO

-- < 2016, usar TF 8649
SELECT *
  INTO OrdersBig_TestInsert
  FROM OrdersBig_v1
OPTION(QUERYTRACEON 8649)
GO


-- With(TabLock) é necessário para obter insert em paralelo com 
-- INSERT+SELECT
-- Nota: Antes do SQL Server 2016 SP1, INSERT+SELECT em tabelas temporárias, não precisavam de tablock... isso mudou no SP1
-- https://support.microsoft.com/en-in/help/3180087/poor-performance-when-you-run-insert-select-operations-in-sql-server-2

-- Query abaixo não roda em paralelo pois WITH TABLOCK não foi especificado
-- Demora 2 minutos e 7 segundos pra rodar
TRUNCATE TABLE OrdersBig_TestInsert
GO
INSERT INTO OrdersBig_TestInsert
           (CustomerID,
            OrderDate,
            Value)
SELECT CustomerID,
       OrderDate,
       Value
  FROM OrdersBig_v1
GO


-- Operação de Table Insert rodando em paralelo
-- Demora 6 segundos pra rodar
TRUNCATE TABLE OrdersBig_TestInsert
GO
INSERT INTO OrdersBig_TestInsert WITH(TABLOCK)
           (CustomerID,
            OrderDate,
            Value)
SELECT CustomerID,
       OrderDate,
       Value
  FROM OrdersBig_v1
GO



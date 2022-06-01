


-- Começando com duas informações importantes: 
-- 1 - "Each lock consumes memory (96 bytes per lock)"
-- 2 - The dynamic lock pool does not acquire more than 60 percent of the memory allocated to the Database Engine
-- 3 - By default, initial pool of 2,500 lock structures is acquired. 
-- As the lock pool is exhausted, additional memory is acquired for the pool.


USE Northwind
GO


-- Criando tabela para testes
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS CustomerID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Quantos locks temos na instância? ... 
SELECT * 
  FROM sys.dm_tran_locks
GO

-- Quanto de memória estamos utilizando? 
SELECT SUM(pages_kb) * 1024 AS SizeInBytes, SUM(pages_kb) / 1024. AS SizeInMB
  FROM sys.dm_os_memory_clerks
 WHERE type = 'OBJECTSTORE_LOCK_MANAGER' 
GO

-- Quantos lock blocks temos disponíveis? ... 
SELECT * 
  FROM sys.dm_os_memory_pools
 WHERE type = 'OBJECTSTORE_LOCK_MANAGER'
 AND Name = 'Lock Blocks'
GO

-- Contador "Memory Manager: Lock Memory (KB)" pode ser útil...
SELECT * 
  FROM sys.dm_os_performance_counters 
 WHERE counter_name = 'Lock Memory (KB)'
GO

SET TRAN ISOLATION LEVEL READ COMMITTED
GO

-- Rodar em nova sessão
-- Bora segurar alguns locks pra ver o número da DMV aumentar
SET TRAN ISOLATION LEVEL SERIALIZABLE
GO
BEGIN TRAN
GO
SELECT TOP 4000 * FROM CustomersBig
GO
--ROLLBACK TRAN
--GO

SET TRAN ISOLATION LEVEL READ COMMITTED
GO

-- Consultar sys.dm_tran_locks

-- Tá, mas isso pode ser problema? ... 
-- Vamos fazer alguns testes...

-- Criando tabela para testes...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
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
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       CONVERT(Date, '20180630') AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 1
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       CONVERT(Date, '20500101') AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO



-- Rodar em nova sessão
BEGIN TRAN
GO
-- Remover dados de 1 a 10 de Janeiro de 2018... +- 2328 linhas atualizadas...
DELETE OrdersBig
WHERE OrderDate BETWEEN '20180101' AND '20180110'
GO

--ROLLBACK TRAN
--GO




-- Se eu tentar ler dados de 20500101, vou conseguir?
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO


-- Criando um índice pra ajudar...
CREATE INDEX ixOrderDate ON OrdersBig(OrderDate)
GO


-- Rodar delete novamente...


-- E agora, se eu tentar ler dados de 20500101, vou conseguir? 
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO


-- Rodar em nova sessão
-- E se eu tentar apagar os 6 primeiros meses? 
BEGIN TRAN
GO
-- Remover dados de 1 a 31 de Janeiro de 2018...
DELETE OrdersBig
WHERE OrderDate BETWEEN '20180101' AND '20180630'
GO

--ROLLBACK TRAN
--GO


-- E agora, se eu tentar ler dados de 20500101, vou conseguir? 
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO

-- Nope.. e se eu tentar forçar o lock na linha no delete?


-- Rodar em nova sessão
-- E se eu tentar apagar os 6 primeiros meses? 
BEGIN TRAN
GO
-- Remover dados de 1 a 31 de Janeiro de 2018...
DELETE OrdersBig WITH(ROWLOCK)
WHERE OrderDate BETWEEN '20180101' AND '20180630'
GO

--ROLLBACK TRAN
--GO


-- E agora, se eu tentar ler dados de 20500101, vou conseguir? 
-- Still, no luck...
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO


-- Lock escalation disparado...


-- SET ( LOCK_ESCALATION = { AUTO (Partition->Table?) | TABLE | DISABLE } )
ALTER TABLE OrdersBig SET ( LOCK_ESCALATION = DISABLE)
GO


-- E agora?
-- Sucesso!
SELECT * FROM OrdersBig
WHERE OrderDate = '20500101'
GO

-- Mas a que custo? 


-- Quanto de memória estamos utilizando? 
SELECT SUM(pages_kb) * 1024 AS SizeInBytes, SUM(pages_kb) / 1024. AS SizeInMB
  FROM sys.dm_os_memory_clerks
 WHERE type = 'OBJECTSTORE_LOCK_MANAGER' 
GO

-- E tem como saber quando se lock escalation foi disparado pra uma determinada tabela/index?
-- Yep, podemos capturar via xEvents ou Traces... porém se foi algo que já aconteceu
---- podemos consultar a dm_db_index_operational_stats
SELECT index_id, ios.index_lock_promotion_count 
  FROM sys.dm_db_index_operational_stats(DB_ID(), OBJECT_ID('OrdersBig'), NULL, NULL) AS ios
GO

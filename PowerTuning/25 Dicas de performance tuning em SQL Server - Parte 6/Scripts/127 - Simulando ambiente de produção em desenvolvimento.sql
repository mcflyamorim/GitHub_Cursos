-- Como simular produção em DEV?

-- Metadata -- Backup? Generate scripts...
-- Session SET OPTIONS -- Backup? Generate scripts...
-- Estatísticas com histograma -- Backup? Generate scripts...
-- Available physical memory -- DBCC OPTIMIZER_WHATIF
-- Number of available CPUs -- DBCC OPTIMIZER_WHATIF
-- 32 or 64 bit system -- DBCC OPTIMIZER_WHATIF



/*
  Optimizer WhatIF
*/

/*
  Property
  1 CPUs = Número de CPUs
  2 MemoryMBs = Quantidade de Memória física em MBs
  3 Bits = 32 ou 64 Bits
*/


-- Habililta 3604 para enviar resultado dos comandos para console
DBCC TRACEON(3604) WITH NO_INFOMSGS
GO
-- Visualiza o status do WHATIF, e os parâmetros default
DBCC OPTIMIZER_WHATIF(Status) WITH NO_INFOMSGS;
GO



USE NorthWind
GO

-- Exemplo 1 - CPU
-- Gerando planos em paralelo para máquinas com mais CPUs

-- Dados de teste ... 2 segundos para rodar...
IF OBJECT_ID('TestRunningTotals') IS NOT NULL
  DROP TABLE TestRunningTotals
GO
CREATE TABLE TestRunningTotals (ID         Integer IDENTITY(1,1) PRIMARY KEY,
                                ID_Account Integer, 
                                ColDate    Date,
                                ColValue   Float)
GO
INSERT INTO TestRunningTotals(ID_Account, ColDate, ColValue)
SELECT TOP 500000
       ABS((CHECKSUM(NEWID()) /10000000)), 
       CONVERT(Date, GetDate() - (CHECKSUM(NEWID()) /1000000)), 
       (CHECKSUM(NEWID()) /10000000.)
FROM master.sys.columns AS c,
     master.sys.columns AS c2,
     master.sys.columns AS c3
GO
;WITH CTE1
AS
(
  SELECT ColDate, ROW_NUMBER() OVER(PARTITION BY ID_Account, ColDate ORDER BY ColDate) rn
    FROM TestRunningTotals
)
-- Removendo dados duplicados...
DELETE FROM CTE1
WHERE rn > 1
GO
CREATE UNIQUE INDEX ix ON TestRunningTotals (ID_Account, ColDate) INCLUDE(ColValue)
GO

-- Com 2 CPUs QO gera plano serial
DBCC OPTIMIZER_WHATIF(1, 2);
GO
-- Demora 4 mins e 48 segundos para rodar
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
SELECT ID_Account,
       ColDate,
       ColValue,
       (SELECT SUM(b.ColValue)
          FROM TestRunningTotals b
         WHERE b.ColDate <= a.ColDate) AS RunningTotal
  FROM TestRunningTotals a
 ORDER BY ID_Account, ColDate
OPTION (RECOMPILE)
GO


-- A partir de 8 CPUs QO começa a gerar plano paralelo
DBCC OPTIMIZER_WHATIF(1, 8);
GO
-- Demora 2 mins e 40 segundos para rodar
-- Obs.: CPU fica a 100% de uso, 
-- entendeu porque o SQL só gera o plano em paralelo quando tiver vários processadores?
CHECKPOINT; DBCC DROPCLEANBUFFERS()
GO
SELECT ID_Account,
       ColDate,
       ColValue,
       (SELECT SUM(b.ColValue)
          FROM TestRunningTotals b
         WHERE b.ColDate <= a.ColDate) AS RunningTotal
  FROM TestRunningTotals a
 ORDER BY ID_Account, ColDate
OPTION (RECOMPILE)
GO

-- Volta CPU para o normal
DBCC OPTIMIZER_WHATIF(1, 0);

-- Reset dos valores...
DBCC OPTIMIZER_WHATIF(ResetAll) WITH NO_INFOMSGS;
GO

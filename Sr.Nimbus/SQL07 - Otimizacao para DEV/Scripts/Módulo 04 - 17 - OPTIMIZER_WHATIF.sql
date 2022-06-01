/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Optimizer WhatIF
*/

 -- Habilita traceflag 2588 para mostrar a sintaxe de DBCCs não documentados
DBCC TRACEON (2588) WITH NO_INFOMSGS
GO
-- Visualiza sintaxe do OPTIMIZER_WHATIF
DBCC HELP ('OPTIMIZER_WHATIF') WITH NO_INFOMSGS
/*
  dbcc OPTIMIZER_WHATIF ({property/cost_number | property_name} [, {integer_value | string_value} ])
*/


/*
  Property
  1 CPUs = Número de CPUs
  2 MemoryMBs = Quantidade de Memória física em MBs
  3 Bits = 32 ou 64 Bits
*/

-- Desabilita TF 2588
DBCC TRACEOFF (2588) WITH NO_INFOMSGS
GO

-- Habililta 3604 para enviar resultado dos comandos para console
DBCC TRACEON(3604) WITH NO_INFOMSGS
GO
-- Visualiza o status do WHATIF, e os parâmetros default
DBCC OPTIMIZER_WHATIF(0) WITH NO_INFOMSGS;
GO


-- Seta o número de CPUs para 8
DBCC OPTIMIZER_WHATIF(1, 8);
GO
-- Seta a quantidade de memória para 2GB
DBCC OPTIMIZER_WHATIF(2, 2048);
GO
-- Seta 32 bits
DBCC OPTIMIZER_WHATIF(3, 32);
GO

-- Volta número de CPUs para default
DBCC OPTIMIZER_WHATIF(1, 0);
GO
-- Volta quantidade de memória para default
DBCC OPTIMIZER_WHATIF(2, 0);
GO
-- Volta processador para default
DBCC OPTIMIZER_WHATIF(3, 0);
GO

USE Northwind
GO

-- Exemplo 1 - CPU
-- Gerando planos em paralelo para máquinas com mais CPUs
IF OBJECT_ID('TestRunningTotals') IS NOT NULL
  DROP TABLE TestRunningTotals
GO
CREATE TABLE TestRunningTotals (ID         Integer IDENTITY(1,1) PRIMARY KEY,
                                ID_Account Integer, 
                                ColDate    Date,
                                ColValue   Float)
GO
-- inserting some garbage data (almost 33 seconds to run)
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
-- Removing duplicated dates
DELETE FROM CTE1
WHERE rn > 1
GO
CREATE UNIQUE INDEX ix ON TestRunningTotals (ID_Account, ColDate) INCLUDE(ColValue)
GO

-- Com 2 CPUs QO gera plano serial
DBCC OPTIMIZER_WHATIF(1, 2);
GO
-- Demora 4 mins e 48 segundos para rodar
DBCC DROPCLEANBUFFERS()
SELECT ID_Account,
       ColDate,
       ColValue,
       (SELECT SUM(b.ColValue)
          FROM TestRunningTotals b
         WHERE b.ColDate <= a.ColDate) AS RunningTotal
  FROM TestRunningTotals a
 ORDER BY ID_Account, ColDate
OPTION (RECOMPILE)

-- A partir de 12 CPUs QO começa a gerar plano paralelo
DBCC OPTIMIZER_WHATIF(1, 12);
GO
-- Demora 2 mins e 40 segundos para rodar
-- Obs.: CPU fica a 100% de uso, 
-- entendeu porque o SQL só gera o plano em paralelo quando tiver vários processadores?
DBCC DROPCLEANBUFFERS()
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
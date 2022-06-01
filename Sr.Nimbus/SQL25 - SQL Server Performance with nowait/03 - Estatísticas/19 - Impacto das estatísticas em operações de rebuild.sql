/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

------------------------------------------------------
-- Impacto das estatísticas em operações de rebuild --
------------------------------------------------------
use master
GO
DROP DATABASE TestRebuild_and_Stats
GO

CREATE DATABASE TestRebuild_and_Stats
GO

USE TestRebuild_and_Stats
GO

-- Preparando base
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
                   Col1 VarChar(200) DEFAULT NEWID(),
                   Col2 VarChar(200) DEFAULT NEWID(),
                   Col3 VarChar(200) DEFAULT NEWID(),
                   Col4 VarChar(200) DEFAULT NEWID(),
                   Col5 VarChar(200) DEFAULT NEWID(),
                   Col6 VarChar(200) DEFAULT NEWID(),
                   Col7 VarChar(200) DEFAULT NEWID(),
                   Col8 VarChar(200) DEFAULT NEWID(),
                   Col9 VarChar(200) DEFAULT NEWID(),
                   Col10 VarChar(200) DEFAULT NEWID(),
                   Col11 VarChar(200) DEFAULT NEWID(),
                   Col12 VarChar(200) DEFAULT NEWID(),
                   Col13 VarChar(200) DEFAULT NEWID(),
                   Col14 VarChar(200) DEFAULT NEWID(),
                   Col15 VarChar(200) DEFAULT NEWID(),
                   Col16 VarChar(200) DEFAULT NEWID(),
                   Col17 VarChar(200) DEFAULT NEWID(),
                   Col18 VarChar(200) DEFAULT NEWID(),
                   Col19 VarChar(200) DEFAULT NEWID(),
                   Col20 VarChar(200) DEFAULT NEWID(),
                   Col21 VarChar(200) DEFAULT NEWID(),
                   Col22 VarChar(200) DEFAULT NEWID(),
                   Col23 VarChar(200) DEFAULT NEWID(),
                   Col24 VarChar(200) DEFAULT NEWID(),
                   Col25 VarChar(200) DEFAULT NEWID())
GO
BEGIN TRAN
GO
-- Aprox. 3 minutos para rodar
INSERT INTO Tab1 DEFAULT VALUES
GO 100000
COMMIT
GO

CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO

-- 40 segundos para fazer primeiro rebuild
DBCC DBREINDEX (Tab1)
GO

-- Rodar denovo pra ter certeza do tempo
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
-- média de 12 segundos para fazer um rebuild
DBCC DBREINDEX (Tab1)
GO


-- Cria uma estatística para cada coluna no banco de dados
sp_createstats
GO

-- Verifica estatísticas criadas
sp_helpstats Tab1
GO

-- Rodar o mesmo comando de REBUILD porém com trace 8721 ligado
-- pra ver o tempo gasto no update das estatísiticas
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
DBCC TRACEON(3605, 8721)
GO
DBCC DBREINDEX (Tab1)
GO
DBCC TRACEOFF(3605, 8721)
GO

-- Teste apagando as estatísticas
DROP STATISTICS Tab1.Col1 
DROP STATISTICS Tab1.Col2 
DROP STATISTICS Tab1.Col3 
DROP STATISTICS Tab1.Col4 
DROP STATISTICS Tab1.Col5 
DROP STATISTICS Tab1.Col6 
DROP STATISTICS Tab1.Col7 
DROP STATISTICS Tab1.Col8 
DROP STATISTICS Tab1.Col9 
DROP STATISTICS Tab1.Col10
DROP STATISTICS Tab1.Col11
DROP STATISTICS Tab1.Col12
DROP STATISTICS Tab1.Col13
DROP STATISTICS Tab1.Col14
DROP STATISTICS Tab1.Col15
DROP STATISTICS Tab1.Col16
DROP STATISTICS Tab1.Col17
DROP STATISTICS Tab1.Col18
DROP STATISTICS Tab1.Col19
DROP STATISTICS Tab1.Col20
DROP STATISTICS Tab1.Col21
DROP STATISTICS Tab1.Col22
DROP STATISTICS Tab1.Col23
DROP STATISTICS Tab1.Col24
DROP STATISTICS Tab1.Col25


-- Ver a diferença do tempo e uso de recurso no profiler
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
DBCC TRACEON(3605, 8721)
GO
DBCC DBREINDEX (Tab1)
GO
DBCC TRACEOFF(3605, 8721)
GO



-- Rodar ALTER INDEX que não atualiza estatísticas...
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
DBCC TRACEON(3605, 8721)
GO
ALTER INDEX ALL ON Tab1 REBUILD
GO
DBCC TRACEOFF(3605, 8721)
GO

-- Dica, se isso for um problema apague as estatísticas que nunca foram utilizadas
-- Com o TF 8666 é possível visualizar as estatísticas utilizadas em um plano
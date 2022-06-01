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
                   Col25 VarChar(200) DEFAULT NEWID(),
                   Col26 VarChar(200) DEFAULT NEWID(),
                   Col27 VarChar(200) DEFAULT NEWID(),
                   Col28 VarChar(200) DEFAULT NEWID(),
                   Col29 VarChar(200) DEFAULT NEWID(),
                   Col30 VarChar(200) DEFAULT NEWID(),
                   Col31 VarChar(200) DEFAULT NEWID(),
                   Col32 VarChar(200) DEFAULT NEWID(),
                   Col33 VarChar(200) DEFAULT NEWID(),
                   Col34 VarChar(200) DEFAULT NEWID(),
                   Col35 VarChar(200) DEFAULT NEWID(),
                   Col36 VarChar(200) DEFAULT NEWID(),
                   Col37 VarChar(200) DEFAULT NEWID(),
                   Col38 VarChar(200) DEFAULT NEWID(),
                   Col39 VarChar(200) DEFAULT NEWID(),
                   Col40 VarChar(200) DEFAULT NEWID(),
                   Col41 VarChar(200) DEFAULT NEWID(),
                   Col42 VarChar(200) DEFAULT NEWID(),
                   Col43 VarChar(200) DEFAULT NEWID(),
                   Col44 VarChar(200) DEFAULT NEWID(),
                   Col45 VarChar(200) DEFAULT NEWID(),
                   Col46 VarChar(200) DEFAULT NEWID(),
                   Col47 VarChar(200) DEFAULT NEWID(),
                   Col48 VarChar(200) DEFAULT NEWID(),
                   Col49 VarChar(200) DEFAULT NEWID(),
                   Col50 VarChar(200) DEFAULT NEWID(),
                   ColFoto VarBinary(MAX))
GO

-- 2/3 segundos para rodar
INSERT INTO Tab1 (Col1, ColFoto)
SELECT TOP 5000
       NEWID() AS Col1, 
       CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000)) 
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
GO

-- Cria uma estatística para cada coluna no banco de dados
-- 12 segundos para rodar...
sp_createstats
GO

-- Verifica estatísticas criadas
sp_helpstats Tab1
GO


-- 14/16 segundos para rodar
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
DBCC TRACEON(3604,  8721)
GO
DBCC DBREINDEX (Tab1)
GO
DBCC TRACEOFF(3604, 8721)
GO


-- Rodar ALTER INDEX que não atualiza estatísticas... (atualiza apenas estatísticas de índices...)
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
DBCC TRACEON(3604, 8721)
GO
ALTER INDEX ALL ON Tab1 REBUILD
GO
DBCC TRACEOFF(3604, 8721)
GO




-- Apagar as estatísticas
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
DROP STATISTICS Tab1.Col26
DROP STATISTICS Tab1.Col27
DROP STATISTICS Tab1.Col28
DROP STATISTICS Tab1.Col29
DROP STATISTICS Tab1.Col30
DROP STATISTICS Tab1.Col31
DROP STATISTICS Tab1.Col32
DROP STATISTICS Tab1.Col33
DROP STATISTICS Tab1.Col34
DROP STATISTICS Tab1.Col35
DROP STATISTICS Tab1.Col36
DROP STATISTICS Tab1.Col37
DROP STATISTICS Tab1.Col38
DROP STATISTICS Tab1.Col39
DROP STATISTICS Tab1.Col40
DROP STATISTICS Tab1.Col41
DROP STATISTICS Tab1.Col42
DROP STATISTICS Tab1.Col43
DROP STATISTICS Tab1.Col44
DROP STATISTICS Tab1.Col45
DROP STATISTICS Tab1.Col46
DROP STATISTICS Tab1.Col47
DROP STATISTICS Tab1.Col48
DROP STATISTICS Tab1.Col49
DROP STATISTICS Tab1.Col50
DROP STATISTICS Tab1.ColFoto
GO



CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO
-- 0 segundos para fazer rebuild
DBCC DBREINDEX (Tab1)
GO



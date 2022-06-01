/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-------------------------------
-------- Prefetching ----------
-------------------------------
USE Master
GO
CREATE DATABASE TestPrefetch ON  PRIMARY 
( NAME = N'TestPrefetch1', FILENAME = N'G:\TestPrefetch1.mdf' , SIZE = 512000KB , FILEGROWTH = 1024KB ), 
( NAME = N'TestPrefetch2', FILENAME = N'I:\TestPrefetch2.ndf' , SIZE = 512000KB , FILEGROWTH = 1024KB ), 
( NAME = N'TestPrefetch3', FILENAME = N'J:\TestPrefetch3.ndf' , SIZE = 512000KB , FILEGROWTH = 1024KB ), 
( NAME = N'TestPrefetch4', FILENAME = N'K:\TestPrefetch4.ndf' , SIZE = 512000KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'TestPrefetch_log', FILENAME = N'C:\TestPrefetch_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE TestPrefetch SET RECOVERY SIMPLE 
GO

USE TestPrefetch
GO
IF OBJECT_ID('TestTab1') IS NOT NULL
  DROP TABLE TestTab1
GO
CREATE TABLE TestTab1 (ID Int IDENTITY(1,1) PRIMARY KEY,
                       Col1 Char(5000),
                       Col2 Char(1250),
                       Col3 Char(1250),
                       Col4 Numeric(18,2))
GO
-- 6 mins to run
INSERT INTO TestTab1 (Col1, Col2, Col3, Col4)
SELECT TOP 1000 NEWID(), NEWID(), NEWID(), ABS(CHECKSUM(NEWID())) / 10000000.
  FROM sysobjects a
 CROSS JOIN sysobjects b
 CROSS JOIN sysobjects c
 CROSS JOIN sysobjects d
GO 30
CREATE INDEX ix_Col4 ON TestTab1(Col4)
GO
CHECKPOINT
GO

-- Dados estão separados em discos/arquivos diferentes...
SELECT TOP 1000 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID],
       *
  FROM TestTab1
GO


-- Teste COM prefetch
CHECKPOINT
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 15.0
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN,
        QueryTraceON 2340) -- Desabilitar BatchSort
GO

-- Teste SEM prefetch
CHECKPOINT
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
GO
SELECT *
  FROM TestTab1
 WHERE Col4 < 15.0
OPTION (MAXDOP 1, RECOMPILE, LOOP JOIN,
        QueryTraceON 2340, -- Desabilitar BatchSort
        QueryTraceON 8744) -- Desabilitar Prefetch
GO


-- Outro teste forçando cenário ruim
-- Discos ocupados...
/*
SQLIO
c:\sqlio\sqlio.exe -kR -t16 -dG -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dI -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dJ -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dK -s99999 -b64

Com prefetch 29 segundos...
Sem prefetch 1 minuto e 34 segundos
*/


IF OBJECT_ID('st_Test1') IS NOT NULL
  DROP PROC st_Test1
GO
CREATE PROC st_Test1 @i Numeric(18,2)
AS
BEGIN
  SELECT *
    FROM TestTab1
   WHERE TestTab1.Col4 < @i
END
GO

-- Plano sem prefetch
-- Estima que menos de 25 linhas serão lidas da outer table
-- plano sem prefetch é criado
-- 1 segundo
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 0.05
GO
-- Reutilizando plano sem prefetching
-- 18 segundos
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 15.0
GO

-- Pedindo para recompilar...
-- 3 segundos
DBCC DROPCLEANBUFFERS() WITH NO_INFOMSGS
EXEC st_Test1 @i = 15.0 WITH RECOMPILE
GO


/*

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO

SELECT *, sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID] 
  FROM TestTab1
 ORDER BY 4

DBCC TRACEON(652) WITH NO_INFOMSGS -- disable read a-head
DBCC TRACEOFF(652) WITH NO_INFOMSGS -- enable read a-head

SQLIO
c:\sqlio\sqlio.exe -kR -t16 -dG -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dI -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dJ -s99999 -b64
c:\sqlio\sqlio.exe -kR -t16 -dK -s99999 -b64

*/
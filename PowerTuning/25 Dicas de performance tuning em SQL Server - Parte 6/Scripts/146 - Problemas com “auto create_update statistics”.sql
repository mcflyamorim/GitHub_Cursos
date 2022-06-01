USE Northwind
GO

IF OBJECT_ID('TestBlobTab') IS NOT NULL
  DROP TABLE TestBlobTab
GO
CREATE TABLE TestBlobTab (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Int, Foto VarBinary(MAX))
GO

-- 8/12 segundos para rodar
INSERT INTO TestBlobTab (Col1, Foto)
SELECT TOP 5000
       CheckSUM(NEWID()) / 1000000, 
       CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000))
FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d 
GO

INSERT INTO TestBlobTab (Col1, Foto)
SELECT CheckSUM(NEWID()) / 1000000, 
       NULL
GO 100

-- Demora uma eternidade para criar a estatística na coluna Foto...
-- 16 segundos para criar a estatística
-- Consulta roda em 0 segundos

SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
OPTION (RECOMPILE)
GO



-- E o auto update? Também demora?
-- 55 segundos para rodar...
UPDATE TOP (30) PERCENT TestBlobTab SET Foto = CONVERT(VarBinary(MAX),REPLICATE(CONVERT(VarBinary(MAX), CONVERT(VarChar(250), NEWID())), 5000))
GO

-- Desabilitando plano trivial...
SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
OPTION (RECOMPILE, QueryTraceOn 8757) -- desabilitar trivial plan
GO



-- Mais informações aqui...
http://blogs.msdn.com/b/psssql/archive/2009/01/22/how-it-works-statistics-sampling-for-blob-data.aspx



-- Workaround --

-- NO_RECOMPUTE

-- Identificando as estatísticas criadas automaticamente
SELECT * 
  FROM sys.stats
 WHERE Object_ID = OBJECT_ID('TestBlobTab')
GO

DROP STATISTICS TestBlobTab._WA_Sys_00000003_7405149D
GO

-- Criando manualmente com clausula NORECOMPUTE
-- DROP STATISTICS TestBlobTab.StatsFoto
CREATE STATISTICS StatsFoto ON TestBlobTab(Foto) WITH NORECOMPUTE, SAMPLE 0 PERCENT
GO

SELECT COUNT(*)
  FROM TestBlobTab
 WHERE Foto IS NULL
OPTION (RECOMPILE)

-- Boa prática, criar estatísticas em colunas LOB e controlar manualmente quando ela 
-- será atualizada...
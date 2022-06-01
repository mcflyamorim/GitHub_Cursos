/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

/*
  Advanced Scan (a.k.a. Merry-go-round scan)
*/

USE NorthWind
GO

IF OBJECT_ID('TMP_ProductsBig') IS NOT NULL
  DROP TABLE TMP_ProductsBig
GO
SELECT TOP 100 *, CONVERT(Char(7000), 'x') AS Col2
  INTO TMP_ProductsBig
  FROM ProductsBig
GO
ALTER TABLE TMP_ProductsBig ADD CONSTRAINT xpkTMP_ProductsBig PRIMARY KEY (ProductID)
GO
CHECKPOINT
GO
SELECT * FROM TMP_ProductsBig WITH(NOLOCK)
GO
-- "Fingir" que a tabela é grande para gerar o advanced scanning
UPDATE STATISTICS TMP_ProductsBig WITH ROWCOUNT = 1000000, PAGECOUNT = 1000000
GO

-- Criar tabela que irá receber os dados do scan
IF OBJECT_ID('Tab_MerryGoRound') IS NOT NULL
  DROP TABLE Tab_MerryGoRound
GO
CREATE TABLE Tab_MerryGoRound (ID INT Identity(1,1) PRIMARY KEY, Col1 VarChar(500), Col2 XML)
GO

-- Consulta que gera o Scan (rodar no SQLQueryStress em várias sessões)
DECLARE @txt VarChar(500), @xml XML
SET @xml = (SELECT ProductID,
                   sys.fn_PhysLocFormatter (%%physloc%%) AS Physical_RID
              FROM TMP_ProductsBig WITH(NOLOCK)
               FOR XML AUTO)

SET @txt = CONVERT(VarChar(MAX), @xml)

INSERT INTO Tab_MerryGoRound (Col1, Col2) VALUES(@txt, @xml)
GO

TRUNCATE TABLE Tab_MerryGoRound
GO
-- Consulta tabela para ver se tem linhas com ordem diferente
SELECT a.ID, a.Col1, a.Col2
  FROM Tab_MerryGoRound a



-- Teste com 10000 linhas mais linhas
IF OBJECT_ID('TMP_ProductsBig') IS NOT NULL
  DROP TABLE TMP_ProductsBig
GO
SELECT TOP 10000 *, CONVERT(Char(7000), 'x') AS Col2
  INTO TMP_ProductsBig
  FROM ProductsBig
GO
ALTER TABLE TMP_ProductsBig ADD CONSTRAINT xpkTMP_ProductsBig PRIMARY KEY (ProductID)
GO
CHECKPOINT
GO
SELECT * FROM TMP_ProductsBig WITH(NOLOCK)
GO
-- "Fingir" que a tabela é grande para gerar o advanced scanning
UPDATE STATISTICS TMP_ProductsBig WITH ROWCOUNT = 1000000, PAGECOUNT = 1000000
GO


TRUNCATE TABLE Tab_MerryGoRound
GO
-- Consulta tabela para ver se tem linhas com ordem diferentes
SELECT a.ID, a.Col1, a.Col2
  FROM Tab_MerryGoRound a
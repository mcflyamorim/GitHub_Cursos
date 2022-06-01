USE Northwind
GO

IF OBJECT_ID('ProductsBig') IS NOT NULL
  DROP TABLE ProductsBig
GO
SELECT TOP 10000 IDENTITY(Int, 1,1) AS ProductID, 
       dbo.fn_ReturnProductName() + ' ' + SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1
  INTO ProductsBig
  FROM Products A
 CROSS JOIN Products B
 CROSS JOIN Products C
 CROSS JOIN Products D
GO
INSERT INTO ProductsBig (ProductName, Col1)
VALUES  ('Produto TV 50 com nome Fabiano e código - 98872167', 'Alguma coisa'), 
        ('SAMSUNG UN50JS7200GXZD LED 50" UHD SMART 4X HDMI', 'TVs SAMSUNG'), 
        ('SAMSUNG UN32J4300AGXZD TV LED 32" HD SMART 2HDMI 1USB', 'TVs SAMSUNG')
GO
ALTER TABLE ProductsBig ADD CONSTRAINT xpk_ProductsBig PRIMARY KEY(ProductID)
GO


-- Procurar por parte do código... Ou seja, string no meio do texto...
SELECT * FROM ProductsBig
WHERE ProductName LIKE '%7200G%'
GO

-- Procurarando por "bian"
SELECT * FROM ProductsBig
WHERE ProductName LIKE '%bian%'
GO

-- E se eu procurar por fragmentos? ... 
-- explico


-- Baseado em uma string, gerar possibilitade de combinações de 3 em 3 caracteres...
SELECT SUBSTRING('bian', Num, 3), *
  FROM dbo.fnSequencial(LEN('bian'))

-- Removendo as strings com menos de 2 caracteres...
SELECT SUBSTRING('bian', Num, 3), *
  FROM dbo.fnSequencial(LEN('bian') -2)

-- Removendo duplicados, caso existam...
SELECT DISTINCT SUBSTRING('bian', Num, 3)
  FROM dbo.fnSequencial(LEN('bian') -2)

-- Removendo espaços...
SELECT DISTINCT SUBSTRING(REPLACE('bian', ' ', ''), Num, 3)
  FROM dbo.fnSequencial(LEN(REPLACE('bian', ' ', '')) -2)
GO


-- Função para gerar os fragmentos... fnGeraFragmentos
IF OBJECT_ID('fnGeraFragmentos') IS NOT NULL
  DROP FUNCTION fnGeraFragmentos
GO
CREATE FUNCTION dbo.fnGeraFragmentos(@Str VarChar(MAX)) RETURNS TABLE 
AS
RETURN
  (
    SELECT DISTINCT SUBSTRING(REPLACE(@Str, ' ', ''), Num, 3) AS Fragmento
      FROM dbo.fnSequencial(LEN(REPLACE(@Str, ' ', '')) -2)
  )
GO

-- Teste function 1
SELECT * FROM dbo.fnGeraFragmentos('Fabiano Amorim')
GO


-- Teste function 2
SELECT Products.ProductID, fnGeraFragmentos.Fragmento
  FROM Products
 CROSS APPLY dbo.fnGeraFragmentos(Products.ProductName)
GO

-- Tabela de fragmentos
-- Obs.: Excelente canditada a compressão
IF OBJECT_ID('TabFragmentos') IS NOT NULL
  DROP TABLE TabFragmentos
GO
CREATE TABLE TabFragmentos (ProductID Integer NOT NULL,
                            Fragmento  char(3) NOT NULL,
                            CONSTRAINT pk_TabFragmentos PRIMARY KEY (Fragmento, ProductID))
GO
CREATE INDEX ix_ProductID ON TabFragmentos(ProductID)
GO
ALTER INDEX ALL ON TabFragmentos REBUILD WITH(DATA_COMPRESSION=PAGE) 
GO


-- 5 segundos para criar a tabela...
INSERT INTO TabFragmentos WITH(TABLOCK)
SELECT ProductsBig.ProductID, fnGeraFragmentos.Fragmento
  FROM ProductsBig
 CROSS APPLY dbo.fnGeraFragmentos(ProductsBig.ProductName)
GO


-- Cria view com dados de distribuição por Fragmento
IF OBJECT_ID('vwFragmentoStatistics') IS NOT NULL
  DROP VIEW vwFragmentoStatistics
GO
CREATE VIEW vwFragmentoStatistics
WITH SCHEMABINDING
AS 
SELECT Fragmento, COUNT_BIG(*) AS Cnt
  FROM dbo.TabFragmentos
 GROUP BY Fragmento
GO
-- Materializar a view
CREATE UNIQUE CLUSTERED INDEX ix ON vwFragmentoStatistics(Fragmento)
GO

'abian'



SELECT * FROM TabFragmentos
WHERE Fragmento = 'abi'

SELECT * FROM TabFragmentos
WHERE Fragmento = 'bia'

SELECT * FROM TabFragmentos
WHERE Fragmento = 'ian'

SELECT * FROM ProductsBig
WHERE ProductName LIKE '%abian%'


-- Consultando a view
SELECT * FROM vwFragmentoStatistics
GO



-- Procurando por %BIAN%
DECLARE @Nome VarChar(200)
SET @Nome = 'abian'

DECLARE @Fragmento1 char(3);

WITH CTE_1
AS 
(
  SELECT Fragmento,
         cnt,
         rn = ROW_NUMBER() OVER (ORDER BY cnt)
    FROM vwFragmentoStatistics
   WHERE EXISTS(SELECT *
                  FROM dbo.fnGeraFragmentos(@Nome)
                 WHERE fnGeraFragmentos.Fragmento = vwFragmentoStatistics.Fragmento)
)

SELECT @Fragmento1 = Fragmento
  FROM CTE_1
 WHERE rn = 1

 SELECT @Fragmento1

SELECT *
  FROM ProductsBig
 WHERE ProductName LIKE '%' + @Nome + '%'
   AND EXISTS (SELECT *
                 FROM TabFragmentos
                WHERE TabFragmentos.ProductID = ProductsBig.ProductID
                AND TabFragmentos.Fragmento = @Fragmento1)
GO


-- Trigger para manter tabela de fragmentos
IF OBJECT_ID('tr_AtualizaFragmentos') IS NOT NULL
  DROP TRIGGER tr_AtualizaFragmentos
GO
CREATE TRIGGER tr_AtualizaFragmentos ON ProductsBig
FOR INSERT, UPDATE, DELETE 
AS
BEGIN
  SET XACT_ABORT ON
  SET NOCOUNT ON
  -- Exit trigger in case no rows are deleted or inserted ...
  IF NOT EXISTS (SELECT * FROM inserted) AND
     NOT EXISTS (SELECT * FROM deleted)
    RETURN

  -- Exist trigger in case Value column was not updated... 
  IF EXISTS (SELECT * FROM inserted) AND NOT UPDATE(ProductName)
    RETURN
  -- Remove changed fragments
  DELETE TabFragmentos
    FROM TabFragmentos
   INNER JOIN (SELECT ProductID FROM Inserted 
                UNION ALL 
               SELECT ProductID FROM Deleted) AS Tab
      ON TabFragmentos.ProductID = Tab.ProductID
  
  -- Re-insert fragments
  INSERT TabFragmentos (Fragmento, ProductID)
  SELECT dbo.fnGeraFragmentos.Fragmento, Inserted.ProductID
    FROM Inserted
    CROSS APPLY dbo.fnGeraFragmentos(Inserted.ProductName)
END
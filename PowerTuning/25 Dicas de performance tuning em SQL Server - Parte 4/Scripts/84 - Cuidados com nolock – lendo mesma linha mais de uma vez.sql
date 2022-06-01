-- LENDO MESMA LINHA MAIS DE UMA VEZ

USE Northwind
GO


-- Preparando o ambiente
IF OBJECT_ID('Tab1', 'U') IS NOT NULL
  DROP TABLE Tab1;
GO
-- Criar tabela e definir PK como GUID para gerar MUITOS page splits
CREATE TABLE Tab1(Col1 VarChar(250) NOT NULL DEFAULT(NEWID()) PRIMARY KEY,
                  Col2 Char(2000) NOT NULL DEFAULT('Teste'));
GO

-- Deixar rodando consulta na Conexão 1
TRUNCATE TABLE Tab1
GO
WHILE 1=1
  INSERT INTO Tab1 DEFAULT VALUES
GO

-- Opcional: Consulta Fragmentação da tabela
SELECT avg_fragmentation_in_percent 
  FROM sys.dm_db_index_physical_stats (DB_ID('NorthWind'),OBJECT_ID('Tab1'),1,NULL,NULL);
GO

-- Conexão 2
IF OBJECT_ID('tempdb.dbo.#Tab1', 'U') IS NOT NULL
  DROP TABLE #Tab1;
GO
SET NOCOUNT ON;
WHILE 1 = 1
BEGIN
  -- Joga os dados da tabela Tab1 em uma tabela temporária
  -- Atenção no uso do NOLOCK para forçar a leitura por ordem de alocação
  SELECT *, sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
    INTO #Tab1 
    FROM Tab1 WITH(NOLOCK)

  -- Agrupa os dados por Col1 (Coluna com NEWID() como Default)
  -- Se existir mais que uma linha para um único valor
  -- significa que os dados foram lidos mais de uma vez
  IF EXISTS(SELECT Col1
              FROM #Tab1 
             GROUP BY Col1 
            HAVING COUNT(*) > 1)
  BEGIN     
    BREAK
  END
  DROP TABLE #Tab1
END
GO

-- Consulta os registros lidos em duplicidade
SELECT Col1, COUNT(*) AS cnt
  FROM #Tab1 
 GROUP BY Col1
HAVING COUNT(*) > 1;
GO

-- Procura o registro na tabela original
SELECT * 
  FROM Tab1
 WHERE Col1 = '81416138-CC2E-401D-982E-35F869CD9564'

-- Procura o registro na tabela temporária
-- Como um registro pode estar em duas páginas ao mesmo tempo?
SELECT * 
  FROM #Tab1
 WHERE Col1 = '81416138-CC2E-401D-982E-35F869CD9564'
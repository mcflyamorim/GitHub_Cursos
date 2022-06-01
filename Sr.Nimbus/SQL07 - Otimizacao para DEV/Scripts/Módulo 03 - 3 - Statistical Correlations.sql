/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

/*
  Statistical Correlations
*/

-- Preparando o ambiente
SET NOCOUNT ON;
IF OBJECT_ID('AluguelCarros') IS NOT NULL
  DROP TABLE AluguelCarros
GO
CREATE TABLE AluguelCarros(ID Int NOT NULL IDENTITY(1,1) PRIMARY KEY,
                           TipoCarro VarChar(200),
                           Value Numeric(18,2),
                           Carro VarChar(200) NOT NULL DEFAULT NEWID())
GO

;WITH TipoCarros
AS
 (
  SELECT * FROM (VALUES(50, 70, 'Economico'), 
                       (71, 90, 'Intermediario'),
                       (91, 120, 'Executivo'),
                       (120, 200, 'Luxo')) AS Tab(MenorValue, MaiorValue, TipoCarro)
 )
INSERT INTO AluguelCarros(TipoCarro, Value)
SELECT TipoCarro, MenorValue+ ABS(CHECKSUM(NEWID())) % (MaiorValue-MenorValue)
  FROM TipoCarros
GO 1000


-- Consultando os dados da tabela
SELECT * 
  FROM AluguelCarros
GO

/*
  Veriricar todos os carros do tipo Luxo com Value menor que 110 reais
  
  QO estima que 137,5 linhas serão retornadas.  
*/
SELECT * 
  FROM AluguelCarros
 WHERE TipoCarro = 'Luxo'
   AND Value < 60
OPTION (RECOMPILE)
GO

-- Vamos criar um índice para ajudar o SQL na estimativa
-- DROP INDEX ix_TipoCarro_Value ON AluguelCarros 
CREATE INDEX ix_TipoCarro_Value ON AluguelCarros (TipoCarro, Value)
GO

-- E agora a estimativa?
-- Continua com 137,5 linhas, e não usou o índice
SELECT * 
  FROM AluguelCarros
 WHERE TipoCarro = 'Luxo'
   AND Value < 60
OPTION (RECOMPILE)
GO

-- Como ele chegou nestas 137,5 linhas?
/*
  Como o SQL não consegue entender a correlação entre as colunas
  ele utiliza a densidade das colunas para poder fazer a estimativa.
  
  1 - Calcula a densidade da coluna TipoCarro
  2 - Cria uma estatística para a coluna Value
  3 - Calcula a densidade da coluna Value
  4 - Densidade do TipoCarro * Densidade do Value
  5 - Densidade da multiplicação (passo 4)

  Vamos simular estes passos com o código abaixo
*/

DBCC SHOW_STATISTICS(AluguelCarros, ix_TipoCarro_Value)
GO
SELECT 1000./4000. -- Densidade = 0.250000

-- Vericar se existe mais alguma estatística na tabela
SELECT * 
  FROM sys.stats
 WHERE object_id = object_id('AluguelCarros')
GO

-- Consultar a estatística da coluna Value
DBCC SHOW_STATISTICS(AluguelCarros, _WA_Sys_00000003_49C3F6B7)
GO

SELECT 550./4000. -- Densidade = 0.137500
GO

SELECT 0.250000 * 0.137500 -- Densidade final = 0.034375000000
GO

SELECT 0.034375000000 * 4000.
GO


/*
  1 - Alternativa
  Forçar o uso do índice
*/

-- Corrige o problema de fazer o Scan, mas não corrige a estimativa
SELECT * 
  FROM AluguelCarros WITH(index=ix_TipoCarro_Value)
 WHERE TipoCarro = 'Luxo'
   AND Value < 60
OPTION (RECOMPILE)
GO

/*
  2 - Alternativa
  Criar um índice coberto
*/

CREATE INDEX ix_Covered_Index ON AluguelCarros(TipoCarro, Value) INCLUDE(Carro)
GO
-- Continua corrigindo o problema de fazer o Scan, mas sem corrigir a estimativa
SELECT * 
  FROM AluguelCarros
 WHERE TipoCarro = 'Luxo'
   AND Value < 60
OPTION (RECOMPILE)
GO

DROP INDEX ix_Covered_Index ON AluguelCarros
GO

/*
  3 - Alternativa
  Filtered Statistics
*/

CREATE STATISTICS ix_AluguelCarros_Economico ON AluguelCarros(Value) 
 WHERE TipoCarro = 'Economico'
GO
CREATE STATISTICS ix_AluguelCarros_Intermediario ON AluguelCarros(Value) 
 WHERE TipoCarro = 'Intermediario'
GO
CREATE STATISTICS ix_AluguelCarros_Executivo ON AluguelCarros(Value) 
 WHERE TipoCarro = 'Executivo'
GO
CREATE STATISTICS ix_AluguelCarros_Luxo ON AluguelCarros(Value) 
 WHERE TipoCarro = 'Luxo'
GO
-- Criar uma estatísticas para cobrir novas categorias
CREATE STATISTICS ix_AluguelCarros_Outros ON AluguelCarros(Value) 
 WHERE TipoCarro <> 'Luxo' 
   AND TipoCarro <> 'Executivo' 
   AND TipoCarro <> 'Intermediario'
   AND TipoCarro <> 'Economico'
GO

-- Consulta utilizando o índice corretamente
SELECT * 
  FROM AluguelCarros
 WHERE TipoCarro = 'Luxo'
   AND Value < 60
OPTION (RECOMPILE)
GO


-- TraceFlag 4137 
-- http://support.microsoft.com/kb/2658214
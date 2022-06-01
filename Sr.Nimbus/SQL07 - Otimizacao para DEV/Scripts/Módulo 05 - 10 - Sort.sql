/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO
/*
  Sort
*/

-- ALTER TABLE ProductsBig DROP COLUMN ColTest
-- Consulta simples para mostrar o Sort por Col1
SELECT * FROM ProductsBig
ORDER BY Col1
OPTION (MAXDOP 1)

-- Profiler: Sort Warnings
/*
  SQL reserva 246mb de memória
*/
SELECT * FROM ProductsBig
 ORDER BY Col1
OPTION (MAXDOP 1)

-- Rodar em outra sessão
SELECT session_id,
       granted_memory_kb,
       granted_memory_kb / 1024 AS granted_memory_mb,
       used_memory_kb,
       used_memory_kb / 1024 AS used_memory_mb,
       ideal_memory_kb,
       ideal_memory_kb / 1024 AS ideal_memory_mb
  FROM sys.dm_exec_query_memory_grants
 WHERE session_id <> @@SPID

/*
  Alterar quantidade de memória disponível para disparar 
  o warning no profiler
*/
EXEC sys.sp_configure N'max server memory (MB)', N'64'
GO
RECONFIGURE WITH OVERRIDE
GO

SELECT * FROM ProductsBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Rodar em outra sessão
SELECT session_id,
       granted_memory_kb,
       granted_memory_kb / 1024 AS granted_memory_mb,
       used_memory_kb,
       used_memory_kb / 1024 AS used_memory_mb,
       ideal_memory_kb,
       ideal_memory_kb / 1024 AS ideal_memory_mb
  FROM sys.dm_exec_query_memory_grants
 WHERE session_id <> @@SPID
GO

EXEC sys.sp_configure N'max server memory (MB)', N'512'
GO
RECONFIGURE WITH OVERRIDE
GO


/*
  Memory Grant e Sorts
*/

-- ALTER TABLE ProductsBig DROP COLUMN ColTest
ALTER TABLE ProductsBig ADD ColTest Char(2000) NULL
GO
/*
  2746 = Bom
  2747 = Ruim
  
  Achar o Value(intervalo) onde a consulta começa a ficar ruim
  Comparar os planos  
*/

SELECT *
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2746 -- 1800, 2000, 2300
 ORDER BY ColTest

/*
  Quanto de memória foi alocada?
*/
WHILE 1=1
BEGIN
  DECLARE @Str VarChar(200)
  SELECT @Str = ProductName
    FROM ProductsBig
   WHERE ProductID BETWEEN 1 AND 2747 -- 1800, 2000, 2300
   ORDER BY ColTest
END
GO

-- Rodar em outra sessão
SELECT session_id,
       granted_memory_kb,
       granted_memory_kb / 1024 AS granted_memory_mb,
       used_memory_kb,
       used_memory_kb / 1024 AS used_memory_mb,
       ideal_memory_kb,
       ideal_memory_kb / 1024 AS ideal_memory_mb
  FROM sys.dm_exec_query_memory_grants
 WHERE session_id <> @@SPID
GO

/*
  A quantidade de memória alocada para a consulta não foi o suficiente
  Como influenciar na quandidade de memória alocada para a consulta?
*/

-- Alternativa 1

-- Alterar a quantidade de memória mínima por consulta para 7mb
-- Configuração default é de 1024

exec sys.sp_configure N'min memory per query (KB)', N'7168'
go
reconfigure with override
go
SET STATISTICS TIME ON
DECLARE @Str VarChar(200)
SELECT @Str = ProductName
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2747
 ORDER BY ColTest
SET STATISTICS TIME OFF
GO
-- 7 mb não é o suficiente, vamos aumentar para 10mb. SELECT 10 * 1024
exec sys.sp_configure N'min memory per query (KB)', N'10240'
go
reconfigure with override
go
SET STATISTICS TIME ON
DECLARE @Str VarChar(200)
SELECT @Str = ProductName
  FROM ProductsBig
 WHERE ProductID BETWEEN 1 AND 2747
 ORDER BY ColTest
SET STATISTICS TIME OFF
GO

-- Voltar o padrão
exec sys.sp_configure N'min memory per query (KB)', N'1024'
go
reconfigure with override
go


-- Alternativa 2
-- Alterar a consulta para aumentar o tamanho da linha
-- Analisar o plano, verificar o Value de row size do compute scalar
WHILE 1=1
BEGIN
  DECLARE @Str VarChar(200)
  SELECT @Str = ProductName
    FROM ProductsBig
   WHERE ProductID BETWEEN 1 AND 2747 -- 1800, 2000, 2300
   ORDER BY CONVERT(VarChar(8000), ColTest)
END
GO


-- Alternativa 3
-- Utilizar o hint OptimizeFor
DECLARE @MaxProductID Int
SET @MaxProductID = 2747
SELECT *
  FROM ProductsBig 
 WHERE ProductID BETWEEN 1 AND @MaxProductID
 ORDER BY ColTest
OPTION (OPTIMIZE FOR (@MaxProductID = 5000)) -- Ou... 2147483647, achar um número bom
GO

/*
  TOP 100 vs TOP 101
*/
-- Roda em 1 segundo
SELECT TOP 100 
       ProductID,
       ProductName,
       Col1,
       ColTest
  FROM ProductsBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO
-- Roda em aprox. 1 minuto
SELECT TOP 101 
       ProductID,
       ProductName,
       Col1,
       ColTest
  FROM ProductsBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Pergunta: Se as consultas tem o mesmo plano e custo, 
-- porque tamanha diferença no tempo?














-- Resposta: Algorítmo de Sort é diferente para Valuees 
-- maiores que 100.
-- E o algorítmo que ordena os Valuees maiores que 100 
-- escreve os dados no tempdb

-- Alternativa 1
SELECT Tab1.*, ProductsBig.ColTest
  FROM ProductsBig
 INNER JOIN (SELECT TOP 101 ProductID, ProductName, Col1 
               FROM ProductsBig
              ORDER BY Col1) AS Tab1
    ON ProductsBig.ProductID = Tab1.ProductID
 ORDER BY Tab1.Col1
OPTION (MAXDOP 1, RECOMPILE)
GO

-- Alternativa 2
SELECT TOP 101 
       ProductID,
       ProductName,
       Col1,
       CONVERT(VarChar(2000), ColTest)
  FROM ProductsBig
 ORDER BY Col1
OPTION (MAXDOP 1, RECOMPILE)
GO
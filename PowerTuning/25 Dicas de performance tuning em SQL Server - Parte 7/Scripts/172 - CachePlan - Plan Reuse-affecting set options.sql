
-- Demo ARITHABORT

USE Northwind
GO

IF OBJECT_ID('OrdersBig1') IS NOT NULL
  DROP TABLE OrdersBig1
GO
CREATE TABLE [dbo].[OrdersBig1](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig1] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 10000000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
IF OBJECT_ID('CustomersBig1') IS NOT NULL
  DROP TABLE CustomersBig1
GO
SELECT TOP 1000000 
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig1
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig1 ADD CONSTRAINT xpk_CustomersBig1 PRIMARY KEY(CustomerID)
GO
CREATE INDEX ixValue ON [OrdersBig1](Value) 
GO
DBCC FREEPROCCACHE
GO
DROP PROC IF EXISTS st_1
GO
CREATE PROC st_1 @i INT = 0
AS
BEGIN
  SELECT CustomersBig1.CustomerID, SUM(Value) AS v FROM OrdersBig1
  INNER JOIN CustomersBig1
   ON CustomersBig1.CustomerID = OrdersBig1.CustomerID
  WHERE Value <= @i
  GROUP BY CustomersBig1.CustomerID
END
GO

-- Abrir App em "D:\Fabiano\Trabalho\FabricioLima\Cursos\25 Dicas de performance tuning em SQL Server - Parte 7\Outros\SetOptions App"



-- Abrir Profiler pra capturar comando enviado pela APP
-- Abrir app e ver quanto tempo demora pra executar a proc
-- 11 segundos?

-- No SSMS demora quanto tempo?
EXEC st_1 @i = 1000
GO
-- Ué... 0 segundos? 

-- Será que é problema de Parameter Sniffing? 
-- Mas porque na minha execução no SSMS eu não reutilizei o plano criado pela App?

-- O que ficou no cache?
-- Ops, tem 2 planos pra Proc st_1?
-- Algo diferente em select->properties-> set options ?
SELECT text, query_plan, ECP.usecounts
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
WHERE dm_exec_sql_text.text LIKE '%st_1%'
AND "text" NOT LIKE '%dm_exec_cached_plans%'
GO


-- Limpar cache
DBCC FREEPROCCACHE
GO

-- Rodar Proc via app

-- Antes de rodar no SSMS ajustar o ARITHABORT
SET ARITHABORT OFF
GO
EXEC dbo.st_1 @i = 1000
GO


-- Ué, ainda assim ta rápido... o que mais tá diferente? 
-- Ver nos planos

-- Em select->properties-> set options não tem mais nada diferente
SELECT text, query_plan, ECP.usecounts
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
WHERE dm_exec_sql_text.text LIKE '%st_1%'
AND "text" NOT LIKE '%dm_exec_cached_plans%'
GO

-- Ver na sys.dm_exec_plan_attributes
-- Qual valor da set_options pro plano executado na App?
-- O valor muda se comparado ao plano executado via SSMS?
SELECT ecp.memory_object_address, ecp.usecounts, dm_exec_plan_attributes.*
FROM sys.dm_exec_cached_plans as ECP
CROSS APPLY sys.dm_exec_sql_text(ECP.plan_handle)
CROSS APPLY sys.dm_exec_query_plan(ECP.plan_handle)
CROSS APPLY sys.dm_exec_plan_attributes(ECP.plan_handle)
WHERE "text" LIKE '%st_1%'
AND "text" NOT LIKE '%dm_exec_cached_plans%'
GO

-- Traduzindo o SetOptions
declare @set_options int = 763
if ((1 & @set_options) = 1) print 'ANSI_PADDING'
if ((4 & @set_options) = 4) print 'FORCEPLAN'
if ((8 & @set_options) = 8) print 'CONCAT_NULL_YIELDS_NULL'
if ((16 & @set_options) = 16) print 'ANSI_WARNINGS'
if ((32 & @set_options) = 32) print 'ANSI_NULLS'
if ((64 & @set_options) = 64) print 'QUOTED_IDENTIFIER'
if ((128 & @set_options) = 128) print 'ANSI_NULL_DFLT_ON'
if ((256 & @set_options) = 256) print 'ANSI_NULL_DFLT_OFF'
if ((512 & @set_options) = 512) print 'NoBrowseTable'
if ((4096 & @set_options) = 4096) print 'ARITHABORT'
if ((8192 & @set_options) = 8192) print 'NUMERIC_ROUNDABORT'
if ((16384 & @set_options) = 16384) print 'DATEFIRST'
if ((32768 & @set_options) = 32768) print 'DATEFORMAT'
if ((65536 & @set_options) = 65536) print 'LanguageID'
GO

/*
ANSI_PADDING
CONCAT_NULL_YIELDS_NULL
ANSI_WARNINGS
ANSI_NULLS
QUOTED_IDENTIFIER
ANSI_NULL_DFLT_ON


ANSI_PADDING
CONCAT_NULL_YIELDS_NULL
ANSI_WARNINGS
ANSI_NULLS
QUOTED_IDENTIFIER
ANSI_NULL_DFLT_ON
NoBrowseTable
*/

-- Ajustando o NO_BROWSETABLE pra ficar o igual a App...
-- Agora sim, reutilizando o plano do cache gerado pela app...
SET NO_BROWSETABLE ON
SET ARITHABORT OFF
GO
EXEC dbo.st_1 @i = 1000
GO

-- Isso explica o porque quando a query que você roda no SSMS é mais rápida que a query da App... 
-- No SSMS você está criando um plano novo... na App está reutilizando plano do cache...
-- Um usuário diferente, também irá gerar um plano novo... 
-- Portanto o ideal seria rodar a query da app com o 
---- mesmo usuário e user settings utilizados na app

-- ARITHABORT é a única setting que o SSMS muda...
/*
  Setting                  | ADO .Net, ODBC or OLE DB	| SSMS	|
  ------------------------------------------------------------
  ANSI_NULL_DFLT_ON	       | ON	                      | ON	  |
  ANSI_NULLS	              | ON	                      | ON	  |
  ANSI_PADDING	            | ON	                      | ON	  |
  ANSI_WARNINGS	           | ON	                      | ON	  |
  CONACT_NULLS_YIELD_NULL	 | ON	                      | ON	  |
  QUOTED_IDENTIFIER	       | ON	                      | ON	  |
  ARITHABORT	              | OFF	                     | ON	  |
*/

-- Tools -> Options -> Query Execution - SQL Server - Advanced - SET ARITHABORT
-- Então vale a pena mudar isso no SSMS pra ficar igual as Apps? 
-- Calma ae... 

-- Afinal, o que ARITHABORT faz?
-- Em bancos com compatibility level 90+, nada... a não ser que
-- SET ANSI_WARNINGS esteja OFF... Default é ON.

-- Vamos mudar as duas configs pra ver a diff de comportamento

-- Utilizando a opção padrão do SSMS
SET ANSI_WARNINGS ON
SET ARITHABORT ON
GO
-- Da erro, certo?
SELECT 1/0
GO
SELECT CONVERT(TINYINT, 500), * FROM Orders
GO
-- Warning: Null value is eliminated by an aggregate or other SET operation.
SELECT COUNT(ShipRegion) FROM Orders
GO

-- Desligando ARITHABORT e ANSI_WARNINGS... 
SET ANSI_WARNINGS OFF
SET ARITHABORT OFF
GO
-- E agora?
SELECT 1/0
GO
SELECT CONVERT(TINYINT, 500), * 
  FROM Orders
GO
SELECT COUNT(ShipRegion) FROM Orders
GO

-- Risco de mudar isso... 

DROP INDEX IF EXISTS ixFiltered1 ON OrdersBig1
CREATE INDEX ixFiltered1 ON OrdersBig1 (Value)
WHERE OrderDate >= '20200101'
GO
--Msg 1934, Level 16, State 1, Line 218
--CREATE INDEX failed because the following SET options have incorrect settings: 'ANSI_WARNINGS'. Verify that SET options are correct for use with indexed views and/or indexes on computed columns and/or filtered indexes and/or query notifications and/or XML data type methods and/or spatial index operations.


-- Utilizando a opção padrão do SSMS
SET ANSI_WARNINGS ON
SET ARITHABORT ON
GO

DROP INDEX IF EXISTS ixFiltered1 ON OrdersBig1
CREATE INDEX ixFiltered1 ON OrdersBig1 (Value)
WHERE OrderDate >= '20200101'
GO

-- Desligando ARITHABORT e ANSI_WARNINGS... 
SET ANSI_WARNINGS OFF
SET ARITHABORT OFF
GO

-- Ops...
DELETE FROM OrdersBig1
WHERE CustomerID = -1
GO

-- Cleanup
-- Back to SSMS default
SET ANSI_WARNINGS ON
SET ARITHABORT ON
GO
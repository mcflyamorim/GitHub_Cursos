/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

------------------------------------
------------- xEvent ---------------
--- sort_memory_grant_adjustment ---
------------------------------------

USE NorthWind
GO


IF OBJECT_ID('TestOrdersBig_AdditionalMemoryGrant') IS NOT NULL
  DROP TABLE TestOrdersBig_AdditionalMemoryGrant
GO
SELECT TOP 1000000 * 
  INTO TestOrdersBig_AdditionalMemoryGrant
  FROM OrdersBig

/*
  A pergunta que não quer calar, se o existe memória disponível 
  no servidor, porque não pegar mais memória em tempo de execução
  da ordenação para evitar o SortWarning (acesso a disco)?

  De fato o SQL Server faz isso para ordenação na criação de um índice
*/
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
-- Sort warning
DECLARE @i Int
SELECT @i = OrderID
  FROM TestOrdersBig_AdditionalMemoryGrant
 ORDER BY CustomerID, OrderID
OPTION (MAXDOP 1, RECOMPILE)


/*
  Plano não gera sort Warning porque ele pega memória "on the fly"
  ou seja, durante a execução da ordenação o SQL utiliza mais memória
  do que o inicialmente estimado como necessário.
  Podemos visualizar isso acontecendo de 2 formas:
  1 - Consultando a sys.dm_exec_query_memory_grants veremos que granted_memory_kb é 
  maior que requested_memory_kb.
  2 - xEvents additional_memory_grant e sort_memory_grant_adjustment
*/
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
CREATE INDEX ix1 ON TestOrdersBig_AdditionalMemoryGrant(CustomerID, OrderID) WITH(MAXDOP = 1)
GO
IF EXISTS(SELECT 1 FROM sysindexes WHERE name = 'ix1' and id = OBJECT_ID('TestOrdersBig_AdditionalMemoryGrant'))
  DROP INDEX ix1 ON TestOrdersBig_AdditionalMemoryGrant
GO





/*
  Scripts uteis

-- Set 1GB of memory to the server
EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'max server memory (MB)', N'1024'
GO
RECONFIGURE WITH OVERRIDE
GO

-- Preparando a tabela para testes
-- 1:10 minuto para rodar
USE NorthWind
GO
IF OBJECT_ID('TestOrdersBig_AdditionalMemoryGrant') IS NOT NULL
BEGIN
  DROP TABLE TestOrdersBig_AdditionalMemoryGrant
END
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO TestOrdersBig_AdditionalMemoryGrant
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE TestOrdersBig_AdditionalMemoryGrant ADD CONSTRAINT xpk_TestOrdersBig_AdditionalMemoryGrant PRIMARY KEY(OrderID)
GO
*/
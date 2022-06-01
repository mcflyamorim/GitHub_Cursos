/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Exemplo de plano sendo reutilizado
*/

/* 
  Consulta um cliente.
*/

-- Cria um índice para a consulta não gerar um plano TRIVIAL
--DROP INDEX ix_ContactName ON Customers
CREATE INDEX ix_ContactName ON Customers(ContactName)
GO

-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO
SELECT * FROM Customers
 WHERE ContactName = 'Antonio Moreno'
GO

-- Consulta o plano de execução em cache
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
 WHERE "text" NOT LIKE '%sys.%'
   AND "text" LIKE '%SELECT * FROM Customers%'
GO

-- Executa novamente a consulta para visualizar a reutilização do plano
SELECT * FROM Customers
 WHERE ContactName = 'Antonio Moreno'
GO

-- Executa novamente a consulta alterando o Cliente
-- O SQL gera um novo plano para a consulta do Eduardo
SELECT * FROM Customers
 WHERE ContactName = 'Pedro Afonso'
GO

-- Executa a consulta novamente para o Eduardo com o "from"
-- em minusculo
-- O SQL gera um novo plano para a consulta
SELECT * from Customers
 WHERE ContactName = 'Pedro Afonso'
GO

/*
  Exemplo de Parametrização
*/

-- Setar o banco como PARAMETERIZATION FORCED
ALTER DATABASE NorthWind SET PARAMETERIZATION FORCED WITH NO_WAIT
GO
-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO
SELECT * FROM Customers
 WHERE ContactName = 'Pedro Afonso'
GO
SELECT * FROM Customers
 WHERE ContactName = 'Antonio Moreno'
GO
-- Consulta o plano de execução em cache
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan, *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
 WHERE "text" NOT LIKE '%sys.%'
   AND "text" LIKE '%SELECT * FROM Customers%'
GO

SELECT * FROM master.dbo.syscacheobjects

-- Voltar ao padrão, Setar o banco como PARAMETERIZATION SIMPLE
ALTER DATABASE NorthWind SET PARAMETERIZATION SIMPLE WITH NO_WAIT
GO

/*
  Quanto isso tudo REALMENTE afeta a performance?
*/
-- Limpar o PlanCache
DBCC FREEPROCCACHE
GO
SET STATISTICS TIME ON
GO
SELECT TOP 1 Aux = Orders.CustomerID
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Order_Details
    ON Orders.OrderID = Order_Details.OrderID
 WHERE Orders.OrderID = 10248
GO
SET STATISTICS TIME OFF
GO

-- Encapsular o código em uma Procedure
CREATE PROC st_TestRecompile @ID Integer, 
                             @ID_Saida Integer OUTPUT
AS
SELECT TOP 1 @ID_Saida = Orders.CustomerID
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 INNER JOIN Order_Details
    ON Orders.OrderID = Order_Details.OrderID
 WHERE Orders.OrderID = @ID

-- Test Proc
DECLARE @i Int
EXEC st_TestRecompile @ID = 10248, @ID_Saida = @i OUT
SELECT @i


/*
  Executar a proc acima 100 mil vezes
*/
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 100000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT

  SET @i = @i + 1 
END 
GO

-- Verificar quantas vezes o plano da proc foi reutilizado
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan, *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c


/*
  Executar a mesma proc 100 mil vezes
  mas desta vez pedindo para recompilar o plano
*/
DBCC FREEPROCCACHE
GO
DECLARE @i Integer, @Aux Int
SET @i = 0 
WHILE @i < 100000
BEGIN 
  EXEC st_TestRecompile @ID = @i, @ID_Saida = @Aux OUT WITH RECOMPILE

  SET @i = @i + 1 
END 
GO

/*
  Exemplo programa (.NET/Delphi) passando o datatype 
  errado gerando recompilação
  
  Analisar a consulta utilizando a sp_executeSQL no Profiler:
  exec sp_executesql N'SELECT * FROM Orders
                        INNER JOIN Customers
                           ON Orders.CustomerID = Customers.CustomerID
                        INNER JOIN Order_Details
                           ON Orders.OrderID = Order_Details.OrderID
                        WHERE Customers.ContactName = @P1
                        ',N'@P1 varchar(3)','Liu Wong'

  No programa Procurar por 
  "Ana"
  "Antonio Moreno"
  "Fabio"
  "Gilmar"
  "Gabriel"
  "Vinicius"
  "Alexandre"
  "Wellington"
*/

DBCC FREEPROCCACHE
GO
SELECT a.usecounts,
       a.cacheobjtype,
       a.objtype,
       b.text AS Comando_SQL,
       c.query_plan,
       d.query_hash, 
       *
  FROM sys.dm_exec_cached_plans a
 CROSS APPLY sys.dm_exec_sql_text (a.plan_handle) b
 CROSS APPLY sys.dm_exec_query_plan (a.plan_handle) c
 INNER JOIN sys.dm_exec_query_stats d
    ON a.plan_handle = d.plan_handle
 WHERE "text" NOT LIKE '%sys.%'
   AND "text" LIKE '%SELECT * FROM Orders%'
 ORDER BY creation_time ASC
 
/*
  sp_recompile vs DBCC FREEPROCCACHE(plan_handle)
*/
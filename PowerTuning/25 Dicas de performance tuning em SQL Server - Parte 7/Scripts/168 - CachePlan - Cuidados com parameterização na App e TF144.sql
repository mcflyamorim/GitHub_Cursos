USE Northwind
GO


DBCC FREEPROCCACHE()
GO

-- Abrir app 
-- D:\Fabiano\Trabalho\FabricioLima\Cursos\25 Dicas de performance tuning em SQL Server - Parte 7\Outros\Cache Plans Test\
/*
  Exemplo programa (Delphi) passando o tamanho do datatype errado
  
  Analisar a consulta utilizando a sp_executeSQL no Profiler:
  exec sp_executesql N'SELECT * FROM Orders
                        INNER JOIN Customers
                           ON Orders.CustomerID = Customers.CustomerID
                        INNER JOIN Order_Details
                           ON Orders.OrderID = Order_Details.OrderID
                        WHERE Customers.ContactName = @P1
                        ',N'@P1 varchar(3)','Liu Wong'

  No programa procurar por 
  "Ana"
  "Antonio Moreno"
  "Fabio"
  "Gilmar"
  "Gabriel"
  "Vinicius"
  "Alexandre"
  "Wellington"
*/

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
GO

-- Se possível, corrigir o app para passar o tamnanho do parâmetro corretamente
-- Caso não seja possível corrigir a app, considerar TF 144 -- 
https://techcommunity.microsoft.com/t5/sql-server/6-0-best-programming-practices/ba-p/383209

-- Habilitar T144 e rodar app novamnete...
EXEC xp_cmdShell 'Powershell.exe -Command "Set-DbaStartupParameter -SqlInstance DELLFABIANO\SQL2017 -TraceFlag 144 -Confirm:$false"'
GO
-- Reiniciar instância...
EXEC xp_cmdShell 'net stop MSSQL$SQL2017 && net start MSSQL$SQL2017'
GO
SELECT create_date FROM sys.databases WHERE name = 'tempdb'
GO
-- Verifica TF
DBCC TRACESTATUS(-1)
GO



-- Sucesso!

-- Obs. TF144 não funciona mais no SQL2019... :-( ...
-- <=SQL2017 funciona...

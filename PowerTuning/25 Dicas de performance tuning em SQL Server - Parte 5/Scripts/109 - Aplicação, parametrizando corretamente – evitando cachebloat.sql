
-- Abrir app em Scritps\Outros\Cache Plans Test\


/*
  Exemplo programa (.NET/Delphi) passando o datatype errado
  
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
 
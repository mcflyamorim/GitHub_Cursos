/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO
IF OBJECT_ID('st_Test_sp_Recompile') IS NOT NULL
  DROP PROC st_Test_sp_Recompile
GO
CREATE PROC st_Test_sp_Recompile
AS
BEGIN
  SELECT * FROM Orders
   INNER JOIN Order_Details
      ON Orders.OrderID = Order_Details.OrderID
END
GO

-- Teste da Proc
exec st_Test_sp_Recompile
GO


BEGIN TRAN
GO
ALTER PROC st_Test_sp_Recompile
AS
BEGIN
  SELECT * FROM Orders
   INNER JOIN Order_Details
      ON Orders.OrderID = Order_Details.OrderID
END
GO
WAITFOR DELAY '00:00:15'
GO
COMMIT
GO
/*
  Em outra sessão rodar o sp_recompile e dar um stop
  Esperar 15 segundos para o alter proc terminar de rodar, 
  voltar na sessão do sp_recompile e rodar o sp_recompile novamente
*/
sp_recompile st_Test_sp_Recompile


-- Teste da Proc
exec st_Test_sp_Recompile
GO







-- Alternativa
SELECT cp.plan_handle, st.[text]
  FROM sys.dm_exec_cached_plans AS cp
 CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE st.Text like '%st_Test_sp_Recompile%'
GO

DBCC FREEPROCCACHE(0x05001400293FAC4BB800090B000000000000000000000000)
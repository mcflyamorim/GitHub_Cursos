IF OBJECT_ID('fn_RetornaDia', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_RetornaDia
GO
CREATE FUNCTION dbo.fn_RetornaDia()
RETURNS Date
AS
BEGIN
  RETURN CONVERT(Date, GetDate())
END
GO

IF OBJECT_ID('CustomersBig_TMP') IS NOT NULL
  DROP TABLE CustomersBig_TMP

SELECT TOP 10 * 
  INTO CustomersBig_TMP
  FROM CustomersBig
GO


-- Qual o problema dessa query? A function é executada 
-- para todas as linhas da tabela Orders... 
-- Ver CPU no profiler
-- Function inibe o uso de paralelismo...
SELECT * 
  FROM OrdersBig
 INNER JOIN CustomersBig_TMP
    ON CustomersBig_TMP.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.OrderDate < dbo.fn_RetornaDia()
OPTION (RECOMPILE)
GO


-- Function excutada apenas 1 vez
DECLARE @dt Date
SET @dt = dbo.fn_RetornaDia()

SELECT * 
  FROM OrdersBig
 INNER JOIN CustomersBig_TMP
    ON CustomersBig_TMP.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.OrderDate < @dt
OPTION (RECOMPILE)
GO

-- Cuidado com esta alteração... 
-- lembre-se functions são executadas linha a linha... ou seja, 
-- se por acaso a query começar a rodar as 23:59 e demorar 5 mins para rodar
-- o resultado pode esr diferente já que no caso da primeira consulta o valor de
-- resultado da function será diferente se o dia mudar...
/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Compute Scalar
*/

-- Compute Scalar fazendo a concatenação
SELECT 'Teste Compute Scalar - ' + ContactName
  FROM Customers

/*
  Calcular o percentual do pedido baseado 
  em uma meta de vendas
  
  Rodar o script abaixo e comprar o uso de CPU 
  no resultado do Statistics Time
*/
-- Compute Scalar fazendo o calculo
SET STATISTICS TIME ON
SELECT OrderID,
       Value, 
       CONVERT(NUMERIC(18,2), ((Value / 2500) * 100)) AS Percentual,
       2500.00 AS Meta
  FROM OrdersBig
SET STATISTICS TIME OFF
GO

 SQL Server Execution Times:
   CPU time = 1092 ms,  elapsed time = 26691 ms.


-- ALTER TABLE OrdersBig DROP COLUMN Percentual
ALTER TABLE OrdersBig ADD Percentual 
  AS CONVERT(Numeric(18,2), ((Value / 2500) * 100)) PERSISTED
GO
/*
  Comparar uso de CPU com a coluna persistida
*/
SET STATISTICS TIME ON
SELECT OrderID,
       Value, 
       Percentual,
       2500.00 AS Meta
  FROM OrdersBig
SET STATISTICS TIME OFF
GO


/*
  No SQL Server 2008 o Compute Scalar é executado 
  implícitamente no plano.
  A variável é Integer mas a coluna é SmallInt, o SQL 
  converte a variável para SmallInt para poder fazer 
  a comparação.
  
  No SQL Server 2000 o SQL mostra o compute scalar 
  convertendo um Value recebido por uma Constant Scan
*/

-- Plano no SQL 2005/2008
DECLARE @Tab TABLE(ID SmallInt PRIMARY KEY)
DECLARE @iD_Int Integer
SELECT *
  FROM @Tab
 WHERE ID = @iD_Int
 
-- Mostrar Plano no SQL 2000
DECLARE @Tab TABLE(ID SmallInt PRIMARY KEY)
DECLARE @iD_Int Integer
SELECT *
  FROM @Tab
 WHERE ID = @ID_Int
 
 
/*
  IF EXISTS vs @@RowCount
*/
DBCC FREEPROCCACHE
GO
DECLARE @i Int
SET @i = 0

WHILE @i < 1000000
BEGIN
  IF EXISTS(SELECT * FROM Customers WHERE CustomerID = @i)
  BEGIN
    IF EXISTS(SELECT * FROM Products WHERE ProductID = @i)
    BEGIN
      IF EXISTS(SELECT * FROM Orders WHERE OrderID = @i)
      BEGIN
        PRINT 'Entrou no IF'
      END
    END
  END
  SET @i = @i + 1;
END
GO
DBCC FREEPROCCACHE
GO
DECLARE @i Int, @Var Int
SET @i = 0

WHILE @i < 1000000
BEGIN
  SELECT @Var = CustomerID FROM Customers WHERE CustomerID = @i
  IF @@RowCount > 0
  BEGIN
    SELECT @Var = ProductID FROM Products WHERE ProductID = @i
    IF @@RowCount > 0
    BEGIN
      SELECT @Var = OrderID FROM Orders WHERE OrderID = @i
      IF @@RowCount > 0
      BEGIN
        PRINT 'Entrou no IF'
      END
    END
  END
  SET @i = @i + 1;
END
GO




-- Function para retornar último caracter...
IF OBJECT_ID('RetornaUltimoCarac', 'FN') IS NOT NULL
  DROP FUNCTION dbo.RetornaUltimoCarac
GO
CREATE FUNCTION dbo.RetornaUltimoCarac(@Val VarChar(100), @Len Int)
RETURNS Int
AS
BEGIN
  RETURN RIGHT(@Val, @Len)
END
GO

SELECT SUM(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO

-- Quantas vezes executa a function?
-- Ver stream aggregate
-- 5/6 segundos para rodar...
SELECT SUM(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO


-- E com MAX que executa apenas 1 vez? Quanto tempo?
SELECT MAX(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO



-- Certeza de que o problema é a "function/calculo duplicado"?
SELECT SUM(Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2)))
  FROM OrdersBig
GO

-- Demo com apps do Windows Performance ToolKit
-- Recorder e Analyzer

-- SUM tem o dobro de calls em "InvokeTSQLScalarUDF" se comparado ao MIN
/*
  sqllang.dll!CXStmtQuery::InitForExecute
  sqllang.dll!CXStmtQuery::SetupQueryScanAndExpression
  sqlmin.dll!CQueryScan::StartupQuery
  sqlmin.dll!CQScanStreamAggregateNew::GetCalculatedRow
  sqlmin.dll!CQScanStreamAggregateNew::GetRowHelper
  sqltses.dll!CEsExec::GeneralEval4
      sqllang.dll!UDFInvoke
          sqllang.dll!CUdfExecInfo::InvokeTSQLScalarUDF
*/


-- Alternativa...
-- What, now?
SELECT SUM(Tab1.Col1)
  FROM OrdersBig
 CROSS APPLY (SELECT Convert(Numeric(18,2), dbo.RetornaUltimoCarac(Value, 2))) AS Tab1(Col1)
GO
-- Yep, a vida não é fácil...

-- Related Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/636382/scalar-expression-evaluated-twice-with-sum-aggregate
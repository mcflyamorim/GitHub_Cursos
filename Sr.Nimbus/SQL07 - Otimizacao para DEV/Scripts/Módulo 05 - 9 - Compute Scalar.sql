/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
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
       CONVERT(Numeric(18,2), ((Value / 2500) * 100)) AS Percentual,
       2500.00 AS Meta
  FROM OrdersBig
SET STATISTICS TIME OFF
GO
-- ALTER TABLE OrdersBig DROP COLUMN Percentual
ALTER TABLE OrdersBig ADD Percentual AS CONVERT(Numeric(18,2), ((Value / 2500) * 100)) PERSISTED
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
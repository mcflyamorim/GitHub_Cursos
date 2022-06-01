USE NorthWind
GO

/*
  Problema 1 - Leitura Suja
*/
-- Conexão 1
BEGIN TRAN

UPDATE Customers SET ContactName = 'Chico'
 WHERE CustomerID = 99

WAITFOR DELAY '00:00:15'
ROLLBACK TRAN
GO

-- Conexão 2
SELECT * 
  FROM Customers WITH(NOLOCK)
 WHERE CustomerID = 99

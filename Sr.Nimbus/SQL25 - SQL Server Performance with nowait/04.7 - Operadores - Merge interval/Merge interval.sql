/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE tempdb
GO
 
IF OBJECT_ID('Pedidos') IS NOT NULL
  DROP TABLE Pedidos
GO
 
CREATE TABLE Pedidos (ID INT IDENTITY(1,1) PRIMARY KEY,
        ID_Cliente INT NOT NULL,
        Quantidade SmallInt NOT NULL,
        Valor Numeric(18,2) NOT NULL,
        Data DATETIME NOT NULL)
GO
 
DECLARE @I SmallInt
SET @I = 0
 
WHILE @I < 10000
BEGIN
  INSERT INTO Pedidos(ID_Cliente, Quantidade, Valor, Data)
    SELECT ABS(CheckSUM(NEWID()) / 100000000),
           ABS(CheckSUM(NEWID()) / 10000000),
           ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
           GETDATE() - (CheckSUM(NEWID()) / 1000000)
  SET @I = @I + 1
END
GO

CREATE NONCLUSTERED INDEX ix_ID_Cliente ON Pedidos(ID_Cliente) INCLUDE (Valor)
GO
CREATE NONCLUSTERED INDEX ix_Data ON Pedidos(Data) INCLUDE (Valor)
GO


SELECT SUM(Valor) AS Val
  FROM Pedidos
 WHERE ID_Cliente IN (1,2,3,4)
GO

SELECT SUM(Valor) AS Val
  FROM Pedidos
 WHERE ID_Cliente IN (1,1,1,4)
GO

DECLARE @v1 Int = 1, 
        @v2 Int = 1,
        @v3 Int = 1,
        @v4 Int = 4

SELECT SUM(Valor) AS Val
  FROM Pedidos
 WHERE ID_Cliente IN (@v1, @v2, @v3, @v4)
GO


SELECT SUM(Valor) AS Val
  FROM Pedidos
 WHERE ID_Cliente BETWEEN 10 AND 25
    OR ID_Cliente BETWEEN 20 AND 30
GO

DECLARE @v_a1 Int = 10,
        @v_b1 Int = 20,
        @v_a2 Int = 25,
        @v_b2 Int = 30

SELECT SUM(Valor) AS Val
  FROM Pedidos
 WHERE ID_Cliente BETWEEN @v_a1 AND @v_a2
    OR ID_Cliente BETWEEN @v_b1 AND @v_b2

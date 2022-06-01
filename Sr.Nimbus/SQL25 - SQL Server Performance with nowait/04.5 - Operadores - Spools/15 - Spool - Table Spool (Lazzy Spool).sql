/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

---------------------------------
--- Table Spool - Lazzy Spool ---
---------------------------------

USE Northwind
GO

-- Preparando o ambiente
IF OBJECT_ID('Orders_LazySpool') IS NOT NULL
  DROP TABLE Orders_LazySpool
GO
CREATE TABLE Orders_LazySpool (ID         Integer IDENTITY(1,1) PRIMARY KEY,
                               Customer   Integer NOT NULL,
                               Employee   VarChar(30) NOT NULL,
                               Quantity   SmallInt NOT NULL,
                               Value      Numeric(18,2) NOT NULL,
                               OrderDate  DateTime NOT NULL)
GO
DECLARE @i SmallInt
  SET @i = 0
WHILE @i < 100
BEGIN
  INSERT INTO Orders_LazySpool(Customer, Employee, Quantity, Value, OrderDate)
  VALUES(ABS(CheckSUM(NEWID()) / 100000000),
         'Fabiano',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Neves',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Amorim',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000))
  SET @i = @i + 1
END
GO

-- Visualizando os dados
SELECT * FROM Orders_LazySpool

/*
  Consulta para selecionar todas as compras de um cliente
  com valor menor que a média de compras do mesmo cliente
*/
SELECT Ped1.Customer, Ped1.Value
  FROM Orders_LazySpool Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Customer = Ped1.Customer)
OPTION (MAXDOP 1, RECOMPILE)

/*
  1 - Clustered index scan faz o scan dos pedidos
  2 - Sort por Customer para trabalhar apenas com o segmento de um cliente por vez
  3 - Segment mantém apenas um segmento de clientes por vêz
  4 - Table Spool (lazzy spool) mantém as linhas passadas pelo segmento no cache do spool
  5 - Nested Loops recebe a linha do Outer Loop (Spool) e começa a fazer Inner Loop
      6 - TableSpool passa as linhas do primeiro segmento de clientes para o Stream Aggregate que 
          faz um SUM e COUNT para gerar a média
      7 - Compute Scalar faz o cálculo da média (SUM  / COUNT) prevendo erro por divisão por zero
      8 - Nested Loops recebe a linha do Outer Loop (Spool) e começa a fazer Inner Loop
      9 - Table Spool devolve uma linha para o Loop Join que valida se o valor faz 
          match baseado no predicate do join ([Ped1].[Value]<[Expr1004])
*/

-- Qual é a média de linhas para um cliente específico?
WITH CTE_1
AS
(
  SELECT 1. / COUNT(DISTINCT Customer) AS DensidadeColunaCustomer,
         COUNT(*) QtdeLinhas
    FROM Orders_LazySpool
)
SELECT *, DensidadeColunaCustomer * QtdeLinhas AS MediaPorCliente
  FROM CTE_1
GO

-- Sem o Spool como seria? 
SELECT Ped1.Customer, Ped1.Value
  FROM Orders_LazySpool Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Customer = Ped1.Customer)
OPTION (MAXDOP 1, RECOMPILE, QueryRuleOFF BuildGbApply)
GO


-- Melhorando a consulta
-- DROP INDEX ix_Customer_Include_Value ON Orders_LazySpool
CREATE INDEX ix_Customer_Include_Value ON Orders_LazySpool(Customer) INCLUDE(Value)
GO

-- Mesmo plano, porém agora sem o Operador de Sort
SELECT Ped1.Customer, Ped1.Value
  FROM Orders_LazySpool AS Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Customer = Ped1.Customer)
OPTION (MAXDOP 1, RECOMPILE)
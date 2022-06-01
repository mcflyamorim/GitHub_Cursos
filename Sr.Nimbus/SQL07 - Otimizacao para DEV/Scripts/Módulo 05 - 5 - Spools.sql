/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Eager Spool - Halloween Problem
*/
SET NOCOUNT ON
IF OBJECT_ID('Funcionarios') IS NOT NULL
  DROP TABLE Funcionarios
GO
CREATE TABLE Funcionarios(ID      Int IDENTITY(1,1) PRIMARY KEY,
                          ContactName    Char(7000),
                          Salario Numeric(18,2));
GO
-- Inserir 4 registros para alocar 4 páginas
INSERT INTO Funcionarios(ContactName, Salario)
VALUES('Fabiano', 1900),('Felipe',2050),('Nilton', 2070),('Diego', 2090)
GO
CREATE NONCLUSTERED INDEX ix_Salario ON Funcionarios(Salario)
GO

-- Consultar os dados da tabela
SELECT * FROM Funcionarios

-- Aumento do salário em 10%
-- Utiliza o operador Eager Spool
UPDATE Funcionarios SET Salario = Salario * 1.1
  FROM Funcionarios WITH(index=ix_Salario)
 WHERE Salario < 3000
GO

-- Simular o update com um dynamyc cursor
BEGIN TRAN
DECLARE @ID INT
DECLARE TMP_Cursor CURSOR DYNAMIC 
    FOR SELECT ID 
          FROM Funcionarios WITH(index=ix_Salario)
         --WHERE Salario < 3000

OPEN TMP_Cursor
FETCH NEXT FROM TMP_Cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT * FROM Funcionarios WITH(index=ix_Salario)

  UPDATE Funcionarios SET Salario = Salario * 1.1 
   WHERE ID = @ID

  FETCH NEXT FROM TMP_Cursor INTO @ID
END
CLOSE TMP_Cursor
DEALLOCATE TMP_Cursor
SELECT * FROM Funcionarios
ROLLBACK TRAN
GO

-- Simular o update com um static cursor 
-- simulando o Spool que grava uma cópia dos dados no tempdb
BEGIN TRAN
DECLARE @ID INT
DECLARE TMP_Cursor CURSOR STATIC 
    FOR SELECT ID 
          FROM Funcionarios WITH(index=ix_Salario)
         WHERE Salario < 3000

OPEN TMP_Cursor
FETCH NEXT FROM TMP_Cursor INTO @ID

WHILE @@FETCH_STATUS = 0
BEGIN
  SELECT * FROM Funcionarios WITH(index=ix_Salario)

  UPDATE Funcionarios SET Salario = Salario * 1.1 
   WHERE ID = @ID

  FETCH NEXT FROM TMP_Cursor INTO @ID
END
CLOSE TMP_Cursor
DEALLOCATE TMP_Cursor
SELECT * FROM Funcionarios
ROLLBACK TRAN
GO


/*
  Pergunta: Rodando em TRANSACT ISOLATION LEVEL SNAPSHOT precisamos do Lazy Spool?
*/

/*
  Lazy Spool
*/

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
WHILE @i < 50
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
  Consulta para selecionar todas as compras de um Customer
  com Value menor que a média de compras do mesmo Customer
*/
SELECT Ped1.Customer, Ped1.Value
  FROM Orders_LazySpool Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Customer = Ped1.Customer)
OPTION (MAXDOP 1, RECOMPILE)
/*
  Nota: O Custo de manter o spool é maior o acesso a tabela duas vezes, porém o 
  tempo de execução é mais rápido comparado a um join entre as tabelas.
  Mais testes no arquivo "18.1 - Spools, Consultas Lazy Spool.sql"
*/

DROP INDEX ix_Customer_Include_Value ON Orders_LazySpool
CREATE INDEX ix_Customer_Include_Value ON Orders_LazySpool(Customer) INCLUDE(Value)
GO

-- Mesmo plano, porém agora sem o Operador de Sort
SELECT Ped1.Customer, Ped1.Value
  FROM Orders_LazySpool AS Ped1
 WHERE Ped1.Value < (SELECT AVG(Ped2.Value)
                       FROM Orders_LazySpool Ped2
                      WHERE Ped2.Customer = Ped1.Customer)
OPTION (MAXDOP 1, RECOMPILE)

/*
  Index Spool
*/

-- Preparando o ambiente
IF OBJECT_ID('Orders_IndexSpool') IS NOT NULL
  DROP TABLE Orders_IndexSpool
GO
CREATE TABLE Orders_IndexSpool (ID        Integer IDENTITY(1,1),
                                Customer  Integer NOT NULL,
                                Employee  VarChar(30) NOT NULL,
                                Quantity  SmallInt NOT NULL,
                                Value     Numeric(18,2) NOT NULL,
                                OrderDate DateTime NOT NULL)
GO
CREATE UNIQUE CLUSTERED INDEX ix_PK ON Orders_IndexSpool(ID)
GO
DECLARE @I SmallInt 
SET @I = 0

WHILE @I < 50
BEGIN
  INSERT INTO Orders_IndexSpool(Customer, Employee, Quantity, Value, OrderDate)
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
  SET @I = @I + 1;
END
SET @I = 0
WHILE @I < 2
BEGIN
  INSERT INTO Orders_IndexSpool(Customer, Employee, Quantity, Value, OrderDate)
  SELECT Customer, Employee, Quantity, Value, OrderDate
  FROM Orders_IndexSpool
  
  SET @I = @I + 1;
END
UPDATE Orders_IndexSpool SET OrderDate = CONVERT(Date, OrderDate)
GO

SELECT *
  FROM Orders_IndexSpool Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
GO
/*
  Nota: Criar um índice por OrderDate e Value irá elimitar a criação 
  do índice Eager Spool.
*/
CREATE INDEX ix_OrderDate_Value ON Orders_IndexSpool(OrderDate, Value)
GO

/*
  Lazy Index Spool mantém em cache os Valores dos registros calculados.
  Caso o Value procurado seja um que está em cache, o Spool não precisa
  chamar o StreamAggregate novamente, basta procurar no cache(índice)
  e retornar o Value para o Loop.
*/
SELECT *
  FROM Orders_IndexSpool AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE)
GO

/*
  Pergunta: O que faz o Index Spool tão especial?
  
  Resposta: Ao contrario dos outros Spools, 
  ele não trunca os dados do Cache a cada rebind. 
  Ele mantém o cache completo.
  
  Como vimos no plano do Table Spool, o Table Spool trunca os Valores do cache
  para manter apenas um "Grupo" (gerado pelo segment lembra?) em cache.
  
  Rebind??? vamos entender isso melhor.
*/
/*
  Entendendo Rebind e Rewind
  
  Rebind e Rewind são utilizados em vários operadores, 
  dentre eles os de Spool.
  
  Vejamos seu comportamento no "Table Spool"
  
  Supondo que a tabela Orders_IndexSpool contênha 4 linhas
  na seguinte ordem "19831203", "19831203", "20100622" e "19831203"
  Uma representação do Rebind e Rewind seria o seguinte:
  
  * Value = "19831203". Ocorre um rebind, já que é a primeira vez que o operador é chamado.
  * Value = "19831203". Ocorre um rewind, já que o Value já foi lido, e está no spool cache.
  * Value = "20100622". O Value mudou, portanto o cache é apagado e um novo rebind ocorre,
                        já que o Value "20100622" não está no cache.
  * Value = "19831203". Um rebind ocorre novamente, já que o Value do cache é o "20100226",
                        e o Value lido no passo 1 foi truncado no passo 3.                      
  
  Números finais: 3 Rebinds (passos 1,3 e 4) e apenas um rewind (passo 2).
  
  Com o script abaixo podemos tirar a prova:
*/

TRUNCATE TABLE Orders_IndexSpool
GO
SET IDENTITY_INSERT Orders_IndexSpool ON
INSERT INTO Orders_IndexSpool(ID, Customer, Employee, Quantity, Value, OrderDate)
VALUES(1,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203'),
      (2,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203'),
      (3,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '20100622'),
      (4,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203')
SET IDENTITY_INSERT Orders_IndexSpool OFF
GO
DROP INDEX ix_OrderDate_Value ON Orders_IndexSpool
GO

-- Visualizando os dados
SELECT * FROM Orders_IndexSpool
GO

-- Atualizar estatísticas para forçar o table spool
UPDATE STATISTICS Orders_IndexSpool WITH ROWCOUNT = 300000, PAGECOUNT = 50000
GO
-- Analisar o Rebind Rewind do operador Table Spool
SELECT *
  FROM Orders_IndexSpool AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO

/*
  Segundo nossas contas (texto acima) o Value esperado é o seguinte:
  Rebind = 3
  Rewind = 2
  
  Value atual do plano é o seguinte:
  Rebind = 2
  Rewind = 2
  
  Pergunta: Porque os Valores não bateram?
  
  
  
  
  
  
  
  
  
  Dica: Reparou no Sort gerado no plano de execução?
  
  
  
  
  
  
  
  
  
  Resposta: O SQL reordenou os dados para aumentar as chances do Rewind :-)
  Ou seja, ele trocou nossas dados de:
    * 19831203
    * 19831203
    * 20100622
    * 19831203 
  Para:
    * 19831203
    * 19831203
    * 19831203
    * 20100622
*/

/*
  Vejamos o comportamento do Rebind e Rewind no "Index Spool"
  
  Novamente supondo que a tabela Orders_IndexSpool contêm 4 linhas
  na seguinte ordem "19831203", "19831203", "20100622" e "19831203"
  Uma representação do Rebind e Rewind seria o seguinte:
  
  * Value = "19831203". Ocorre um rebind, já que é a primeira vez que o operador é chamado.
  * Value = "19831203". Ocorre um rewind, já que o Value já foi lido, e está no spool cache.
  * Value = "20100622". Ocorre um rebind já que o Value "20100622" ainda não está no cache.
  * Value = "19831203". Um rewind ocorre, este Value foi lido no passo 1, e continua no cache.

  Números finais: 2 Rebinds (passos 1 e 3) e 2 rewinds (passos 2 e 4).
  
  Com o script abaixo podemos tirar a prova:
*/

-- Analisar o Rebind Rewind do operador Index Spool
UPDATE STATISTICS Orders_IndexSpool WITH ROWCOUNT = 500, PAGECOUNT = 18
GO
-- Analisar o Rebind Rewind do operador Table Spool
SELECT *
  FROM Orders_IndexSpool AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO

/*
  Segundo nossas contas (texto acima) o Value esperado é o seguinte:
  Rebind = 2
  Rewind = 2
  
  Value atual do plano é o seguinte:
  Rebind = 3
  Rewind = 1
  
  Pergunta: Porque os Valores não bateram?
  
  
  
  

  
  
  
  
  
  
  
  
  
  Resposta: Por que o SQL está mentindo. :-)
  
  To quote from “Inside Microsoft SQL Server 2005 Query Tuning and Optimization”, 
  this is what Craig Freedman wrote about this situation:

  “Note that rewinds and rebinds are counted the same way for index and nonindex spools. 
  As described previously, a reexecution is counted as a rewind only if the 
  correlated parameter(s) remain the same as the immediately prior execution, 
  and is counted as a rebind if the correlated parameter(s) change from the prior execution. 
  This is true even for reexecutions, in which the same correlated parameter(s) 
  were encountered in an earlier, though not the immediately prior, execution.
  However, since lazy index spools, like the one in this example, 
  retain results for all prior executions and all previously encountered 
  correlated parameter values, the spool may treat some reported rebinds as rewinds.
  In other words, by failing to account for correlated parameter(s) that were seen 
  prior to the most recent execution, the query plan statistics may overreport the
  number of rebinds for an index spool.”
*/

-- Agora que entendemos o Rebind e Rewind, vamos ver um caso interessante.
-- Para isso vamos incluir os dados iniciais novamente na tabela
IF OBJECT_ID('Orders_IndexSpool') IS NOT NULL
  DROP TABLE Orders_IndexSpool
GO
CREATE TABLE Orders_IndexSpool (ID         Integer IDENTITY(1,1),
                                 Customer    Integer NOT NULL,
                                 Employee   VarChar(30) NOT NULL,
                                 Quantity SmallInt NOT NULL,
                                 Value      Numeric(18,2) NOT NULL,
                                 OrderDate       DateTime NOT NULL)
GO
CREATE UNIQUE CLUSTERED INDEX ix_PK ON Orders_IndexSpool(ID)
DECLARE @I SmallInt
  SET @I = 0
WHILE @I < 10000
BEGIN
  INSERT INTO Orders_IndexSpool(Customer, Employee, Quantity, Value, OrderDate)
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
  SET @I = @I + 1;
END
SET @I = 0
WHILE @I < 5
BEGIN
  INSERT INTO Orders_IndexSpool(Customer, Employee, Quantity, Value, OrderDate)
  SELECT Customer, Employee, Quantity, Value, OrderDate
  FROM Orders_IndexSpool
  
  SET @I = @I + 1;
END
UPDATE Orders_IndexSpool SET OrderDate = CONVERT(Date, OrderDate)
GO
CREATE INDEX ix_OrderDate_Value ON Orders_IndexSpool(OrderDate, Value)
GO

--DBCC SHOW_STATISTICS (Orders_IndexSpool, [ix_PK]) WITH STATS_STREAM
---- Atualizar estatísticas para forçar o index spool
--UPDATE STATISTICS Orders_IndexSpool WITH ROWCOUNT = 999999, PAGECOUNT = 50000
--GO

/*
  Pergunta: Porque o SQL fez 19200 rebinds no plano inicial?
  Temos várias OrderDates duplicadas, ele não deveria ter feito 
  alguns rewinds para estes Valores duplicados?
*/
-- Faz 19200 Rebinds
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value
  FROM Orders_IndexSpool AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO




















/*
  Resposta: Porque os dados não estão sendo localizados em ordem de OrderDate e sim
  em ordem de ID
*/

-- Alternativa 1: Forçar o SORT
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value
  FROM (SELECT TOP 999999999 * FROM Orders_IndexSpool ORDER BY OrderDate)Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO

-- Alternativa 2: Criar um índice por order de OrderDate
-- DROP INDEX ix_OrderDate ON Orders_IndexSpool
CREATE INDEX ix_OrderDate ON Orders_IndexSpool(OrderDate) INCLUDE(Customer, Employee, Value)
GO

SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value
  FROM Orders_IndexSpool Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE)
GO

-- Alternativa 3: Criar o cluster por OrderDate
DROP INDEX ix_OrderDate ON Orders_IndexSpool
DROP INDEX [ix_PK] ON Orders_IndexSpool
CREATE CLUSTERED INDEX ix_OrderDate ON Orders_IndexSpool(OrderDate)
GO

SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value
  FROM Orders_IndexSpool Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM Orders_IndexSpool AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE)
GO

/*
  Nota: Lembre-se de que o Index Spool mantem o cache, apesar
  de estar aparecendo vários rebinds isso não significa que não ocorreram
  rewinds.
*/


/*
  Row Count Spool
*/

-- Preparando o ambiente
UPDATE Orders SET OrderDate = '20090101'
WHERE OrderID = 10248
/*
  Exemplo Row Count Spool, 
  armazena o resultado da SubQuery em um Cache e depois 
  consulta o Value no cache e não na tabela Orders
*/
UPDATE STATISTICS Orders WITH ROWCOUNT = 20000, PAGECOUNT = 85
GO
SET STATISTICS IO ON
SELECT OrderID,
       Value
  FROM Orders Ped1
 WHERE NOT EXISTS(SELECT 1 -- Vida longa aos gatinhos
                    FROM Orders Ped2
                   WHERE Ped2.OrderDate = '20090101'
                     AND Ped2.Value > 100)
OPTION(RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF

/*
  Simulando o não uso do Row Count Spool
*/
UPDATE STATISTICS Orders WITH ROWCOUNT = 10, PAGECOUNT = 1
GO
SET STATISTICS IO ON
SELECT OrderID,
       Value
  FROM Orders Ped1
 WHERE NOT EXISTS(SELECT 1
                    FROM Orders Ped2
                   WHERE Ped2.OrderDate = '20090101'
                     AND Ped2.Value > 100)
OPTION(RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF
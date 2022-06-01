/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Hash Join
*/

-- Aprox. 9 mins para rodar o script abaixo
/*
SET NOCOUNT ON
IF OBJECT_ID('Alunos_Hash') IS NOT NULL
BEGIN
  DROP TABLE Alunos_Hash
  DROP TABLE Cursos_Hash
END
GO
CREATE TABLE Cursos_Hash (ID_Cursos INT IDENTITY(1,1) PRIMARY KEY, ContactName_Curso Char(200))
CREATE TABLE Alunos_Hash (ID_Alunos INT IDENTITY(1,1) PRIMARY KEY, ContactName_Aluno Char(200), ID_Cursos INT)
GO
begin tran
GO
DECLARE @I INT
SET @I = 0
WHILE @I < 500000
BEGIN
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Medicina ' + CONVERT(VARCHAR(80), NEWID()))
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Educação Física '+ CONVERT(VARCHAR(80), NEWID()))
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Sistemas de Informação '+ CONVERT(VARCHAR(80), NEWID()))
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Engenharia '+ CONVERT(VARCHAR(80), NEWID()))
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Física Quantica '+ CONVERT(VARCHAR(80), NEWID()))
  INSERT INTO Cursos_Hash (ContactName_Curso)  VALUES ('Paisagismo '+ CONVERT(VARCHAR(80), NEWID()))
  SET @I = @I + 1;
END
GO
COMMIT TRAN
GO
BEGIN TRAN
GO
DECLARE @I INT
SET @I = 0
WHILE @I < 1200000
BEGIN
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Fabiano Amorim ' + CONVERT(VARCHAR(80), NEWID()), 2)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Laerte Junior ' + CONVERT(VARCHAR(80), NEWID()), 6)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Fabricio Catae ' + CONVERT(VARCHAR(80), NEWID()), 5)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Thiago Zavaschi ' + CONVERT(VARCHAR(80), NEWID()), 3)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Diego Nogare ' + CONVERT(VARCHAR(80), NEWID()), 4)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Felipe Ferreira ' + CONVERT(VARCHAR(80), NEWID()), 3)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Rodrigo Fernandes ' + CONVERT(VARCHAR(80), NEWID()), 5)
  INSERT INTO Alunos_Hash (ContactName_Aluno, ID_Cursos)  VALUES ('Nilton Pinheiro ' + CONVERT(VARCHAR(80), NEWID()), 4)
  SET @I = @I + 1;
END
GO
COMMIT TRAN
GO
*/

/*
  Verificar o tamanho de cada tabela
*/
sp_Spaceused Alunos_Hash
GO
sp_Spaceused Cursos_Hash
GO

-- Verificar dados das tabelas
SELECT TOP 10 * FROM Alunos_Hash
SELECT TOP 10 * FROM Cursos_Hash

-- Força o Hash Join utilizando o Hint.
-- 3 mins para rodar
SELECT *
  FROM Alunos_Hash
 INNER JOIN Cursos_Hash
    ON Alunos_Hash.ID_Cursos = Cursos_Hash.ID_Cursos
OPTION (HASH JOIN, MAXDOP 1)
/*
  Hash Function
  
  Adaptando a CheckSum como HashFunction
  
  Para simular a criação dos buckets, podemos gerar um CheckSum 
  do ContactName do aluno, e depois pegar o modulo do valor.
  
  Como estamos utilizando um valor numérico, pode ser um pouco 
  mais simples, por ex:
*/
SELECT ABS(CHECKSUM(ContactName_Aluno)) % 500 AS Hash_Bucket,
       COUNT(*) AS Qtde_Linhas_No_Bucket
  FROM Alunos_Hash
 GROUP BY ABS(CHECKSUM(ContactName_Aluno)) % 500
 ORDER BY Hash_Bucket


/*
  Simulando um HashJoin do seguinte comando:
  SELECT Alunos_Hash.ContactName_Aluno, Cursos_Hash.ContactName_Curso
    FROM Alunos_Hash
   INNER JOIN Cursos_Hash
      ON Alunos_Hash.ID_Cursos = Cursos_Hash.ID_Cursos
  OPTION (HASH JOIN, MAXDOP 1)
*/

/*
  Criar a HashTable da menor tabela (Cursos_Hash), baseado na chave (ID_Cursos)
*/

-- Quebrando a tabela em 500 grupos com 1200 linhas, 
-- mantendo a ordem dos dados nos grupos
SELECT NTILE(500) OVER(ORDER BY ID_Cursos) AS Hash_Bucket,
       *
  FROM Cursos_Hash
 ORDER BY Hash_Bucket
OPTION (MAXDOP 1)

-- Quebrando a tabela em 500 grupos com 1200 linhas, 
-- sem manter a ordem dos dados nos grupos
SELECT ID_Cursos % 500 AS Hash_Bucket,
       *
  FROM Cursos_Hash
OPTION (MAXDOP 1)


/*
  Nota: Clausula Over
  Como escrever uma consulta que retorne o seguinte resultado?

ContactName      OrderID   Valor       Menor_Compra_Cliente   Maior_Compra_Cliente   Media_Compra_Por_Pedido_Cliente   Total_Compras_Cliente
--------- ----------- ----------- ---------------------- ---------------------- --------------------------------- ---------------------
Luciano   244         10763.77    468.78                 19747.11               10158.529436                      721255.59
Luciano   277         4109.94     468.78                 19747.11               10158.529436                      721255.59
Luciano   787         14531.08    468.78                 19747.11               10158.529436                      721255.59
Luciano   836         810.44      468.78                 19747.11               10158.529436                      721255.59
Luciano   893         5236.85     468.78                 19747.11               10158.529436                      721255.59
Luciano   1046        19100.72    468.78                 19747.11               10158.529436                      721255.59
Luciano   1510        11559.64    468.78                 19747.11               10158.529436                      721255.59
Luciano   2114        9151.50     468.78                 19747.11               10158.529436                      721255.59
Luciano   2832        10694.15    468.78                 19747.11               10158.529436                      721255.59
Luciano   3009        8603.24     468.78                 19747.11               10158.529436                      721255.59
...






-- Solução 1, Maior porém mais rápida
SELECT Customers.ContactName,
       Orders.OrderID,
       Orders.Valor,
       (SELECT MIN(a.Valor) FROM Orders a WHERE a.CustomerID = Customers.CustomerID) AS Menor_Compra_Cliente,
       (SELECT MAX(b.Valor) FROM Orders b WHERE b.CustomerID = Customers.CustomerID) AS Maior_Compra_Cliente,
       (SELECT AVG(c.Valor) FROM Orders c WHERE c.CustomerID = Customers.CustomerID) AS Media_Compra_Por_Pedido_Cliente,
       (SELECT SUM(d.Valor) FROM Orders d WHERE d.CustomerID = Customers.CustomerID) AS Total_Compras_Cliente
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
ORDER BY Customers.CustomerID
GO

-- Solução 2, mais elegante porém mais demorada
SELECT Customers.ContactName,
       Orders.OrderID,
       Orders.Valor,
       MIN(Orders.Valor) OVER(PARTITION BY Orders.CustomerID) AS Menor_Compra_Cliente,
       MAX(Orders.Valor) OVER(PARTITION BY Orders.CustomerID) AS Maior_Compra_Cliente,
       AVG(Orders.Valor) OVER(PARTITION BY Orders.CustomerID) AS Media_Compra_Por_Pedido_Cliente,
       SUM(Orders.Valor) OVER(PARTITION BY Orders.CustomerID) AS Total_Compras_Cliente
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
GO
  
  
*/

-- Quebrando a tabela em grupos uniformes
-- HashFunction = (Key * Key) DIV (TotalLinhas)
SELECT (CheckSum(ID_Cursos)/1000 * CheckSum(ID_Cursos)/1000) % COUNT(*) OVER() / 10 AS Hash_Bucket,
       *
  FROM Cursos_Hash
 ORDER BY Hash_Bucket
OPTION (MAXDOP 1)

-- Procurando o HaskBucket do valor 35381
SELECT (CheckSum(35381)/1000 * CheckSum(35381)/1000) % 600000 / 10

/*
  Hash Warning Event - Profiler
  Abrir profiler e ler o evento "Errors and Warnings":Hash Warning
  Analisar contador de memória no PerfMon
*/

-- Gera Hash BailOut (vários hash recursions...)
-- http://blogs.msdn.com/b/ialonso/archive/2012/09/05/what-s-the-maximum-level-of-recursion-for-the-hash-iterator-before-forcing-bail-out.aspx?CommentPosted=true#commentmessage
-- Demora 19 mins para rodar
DECLARE @i Int = 99999999
SELECT *
  FROM Alunos_Hash
 INNER JOIN Cursos_Hash
    ON Alunos_Hash.ID_Cursos = Cursos_Hash.ID_Cursos
 WHERE Alunos_Hash.ID_Alunos < @i
   AND Cursos_Hash.ID_Cursos < @i
OPTION (HASH JOIN, MAXDOP 1, OPTIMIZE FOR (@i = 1))
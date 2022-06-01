/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Loop Join
*/

IF OBJECT_ID('Alunos') IS NOT NULL
  DROP TABLE Alunos
GO
IF OBJECT_ID('Cursos_Desorganizada') IS NOT NULL
  DROP TABLE Cursos_Desorganizada
GO
IF OBJECT_ID('Cursos') IS NOT NULL
  DROP TABLE Cursos
GO
CREATE TABLE Cursos (ID_Cursos INT PRIMARY KEY, ContactName_Curso VARCHAR(80))
CREATE TABLE Cursos_Desorganizada (ID_Cursos INT, ContactName_Curso VARCHAR(80))
CREATE TABLE Alunos (ID_Alunos INT PRIMARY KEY, ContactName_Aluno VARCHAR(80), ID_Cursos INT)
GO

INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (1, 'Medicina')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (2, 'Educação Física')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (3, 'Sistemas de Informação')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (4, 'Engenharia')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (5, 'Física Quantica')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (6, 'Paisagismo')
INSERT INTO Cursos_Desorganizada
SELECT * FROM Cursos
ORDER BY 2
GO

INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim', 2)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (2, 'Laerte Junior', 6)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (3, 'Fabricio Catae', 5)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (4, 'Thiago Zavaschi', 3)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (5, 'Diego Nogare', 4)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (6, 'Felipe Ferreira', 3)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (7, 'Rodrigo Fernandes', 5)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (8, 'Nilton Pinheiro', 4)
GO

-- Verificar dados das tabelas
SELECT * FROM Alunos
SELECT * FROM Cursos

-- Utilizando as fichas qual é a maneira mais fácil de descobrir o curso que o Laerte faz ? 
-- R: Vai no cadastro de cursos e procura pelo ID 6, está fácil pois as fichas estão em ordenadas pelo ID

-- Mas e se o cadastro de cursos não estivesse organizado? 
-- R: Teria que procurar em todas as fichas. E talvez dar o azar de ser o a última ficha em que você olhar. (Com certeza será!)
SELECT * FROM Cursos_Desorganizada

-- Força o Loop Join utilizando o Hint.
-- Scan
SET STATISTICS PROFILE ON
SELECT CONVERT(VarChar, Alunos.ID_Alunos) + '-' + Alunos.ContactName_Aluno, 
       CONVERT(VarChar, Cursos.ID_Cursos) + '-' + Cursos.ContactName_Curso
  FROM Alunos
 INNER JOIN Cursos WITH(INDEX=0)
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (LOOP JOIN)
SET STATISTICS PROFILE OFF
GO

-- Para cada linha da tabela Alunos (normalmente a menor tabela), acessa a tabela Cursos e localiza o
-- ID correspondente.
-- Neste caso não selecionou a tabela Cursos porque ele aproveitou a pk da Cursos para fazer um seek.
SET STATISTICS PROFILE ON
SELECT CONVERT(VarChar, Alunos.ID_Alunos) + '-' + Alunos.ContactName_Aluno, 
       CONVERT(VarChar, Cursos.ID_Cursos) + '-' + Cursos.ContactName_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (LOOP JOIN)
SET STATISTICS PROFILE OFF

-- E se eu também criar um índice em Alunos.ID_Curso
-- DROP INDEX ix_ID_Curso ON Alunos
CREATE INDEX ix_ID_Curso ON Alunos(ID_Cursos) INCLUDE(ContactName_Aluno)

-- Agora o SQL prefere fazer o Scan na tabela de Cursos que é menor
-- e fazer o Seek na tabela de Alunos que é maior
SET STATISTICS PROFILE ON
SELECT CONVERT(VarChar, Alunos.ID_Alunos) + '-' + Alunos.ContactName_Aluno, 
       CONVERT(VarChar, Cursos.ID_Cursos) + '-' + Cursos.ContactName_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (LOOP JOIN)
SET STATISTICS PROFILE OFF

/*
  Bonus: Join entre valores Inteiros são melhores que join entre Strings?
  http://sqlinthewild.co.za/index.php/2011/02/15/are-int-joins-faster-than-string-joins-2/comment-page-1/#comment-1430
  
  E multi-columns vs one column? Alguma diferença?
*/

IF OBJECT_ID('TMP_OrdersBig') IS NOT NULL
  DROP TABLE TMP_OrdersBig
GO
SELECT * 
  INTO TMP_OrdersBig
  FROM OrdersBig
GO
IF OBJECT_ID('TMP_Order_DetailsBig') IS NOT NULL
  DROP TABLE TMP_Order_DetailsBig
GO
SELECT *
  INTO TMP_Order_DetailsBig
  FROM Order_DetailsBig
GO
CREATE CLUSTERED INDEX ix ON TMP_OrdersBig(OrderID)
CREATE CLUSTERED INDEX ix ON TMP_Order_DetailsBig(OrderID)
GO
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
CHECKPOINT
GO

-- Teste joins com colunas Integer
SELECT * 
  FROM TMP_OrdersBig
 INNER JOIN TMP_Order_DetailsBig
    ON TMP_Order_DetailsBig.OrderID = TMP_OrdersBig.OrderID
OPTION (MAXDOP 1)
GO
/*
  Resultado: CPU:      3791
             Reads:    7818
             Duration: 22558
*/


IF OBJECT_ID('TMP_OrdersBig') IS NOT NULL
  DROP TABLE TMP_OrdersBig
GO
SELECT CONVERT(VarChar(20), OrderID) AS OrderID,
       CustomerID,
       Data_Pedido,
       Valor
  INTO TMP_OrdersBig
  FROM OrdersBig
GO
IF OBJECT_ID('TMP_Order_DetailsBig') IS NOT NULL
  DROP TABLE TMP_Order_DetailsBig
GO
SELECT CONVERT(VarChar(20), OrderID) AS OrderID,
       ProductID,
       Data_Entrega,
       Quantidade
  INTO TMP_Order_DetailsBig
  FROM Order_DetailsBig
GO
CREATE CLUSTERED INDEX ix ON TMP_OrdersBig(OrderID)
CREATE CLUSTERED INDEX ix ON TMP_Order_DetailsBig(OrderID)
GO
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
CHECKPOINT
GO

-- Teste joins com colunas VarChar
SELECT * 
  FROM TMP_OrdersBig
 INNER JOIN TMP_Order_DetailsBig
    ON TMP_Order_DetailsBig.OrderID = TMP_OrdersBig.OrderID
OPTION (MAXDOP 1)
GO
/*
  Resultado: CPU:      4274
             Reads:    9820
             Duration: 23649
*/
/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

------------------------------------
------- Entendendo Merge Join ------
------------------------------------

USE NorthWind
GO

IF OBJECT_ID('Alunos') IS NOT NULL
BEGIN
  DROP TABLE Alunos
  DROP TABLE Cursos
END
GO
CREATE TABLE Cursos (ID_Cursos INT PRIMARY KEY, Nome_Curso VARCHAR(80))
CREATE TABLE Alunos (ID_Alunos INT PRIMARY KEY, Nome_Aluno VARCHAR(80), ID_Cursos INT)
GO

INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (1, 'Medicina')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (2, 'Educação Física')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (3, 'Sistemas de Informação')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (4, 'Engenharia')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (5, 'Física Quantica')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (6, 'Paisagismo')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (7, 'Agronomia')
GO

INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim', 2)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (2, 'Laerte Junior', 6)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (3, 'Fabricio Catae', 5)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (4, 'Thiago Zavaschi', 3)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (5, 'Diego Nogare', 4)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (6, 'Felipe Ferreira', 3)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (7, 'Rodrigo Fernandes', 5)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (8, 'Nilton Pinheiro', 4)
GO

-- Verificar dados das tabelas
SELECT * FROM Alunos
SELECT * FROM Cursos

-- Força o Merge Join utilizando o Hint. Verificar o SORT gerado.
-- Sort Merge Join
SELECT Alunos.Nome_Aluno, 
       Cursos.Nome_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)
GO

-- Cria um index por ID_Cursos para evitar o SORT
CREATE NONCLUSTERED INDEX ix_ID_Curso ON Alunos(ID_Cursos)
GO

-- Agora gerou o Lookup para ler a coluna Nome_Aluno
SELECT Alunos.Nome_Aluno, Cursos.Nome_Curso
FROM Alunos
INNER JOIN Cursos
ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)
GO

-- Cria um covered index por ID_Cursos e Nome_Aluno para evitar o Lookup
DROP INDEX ix_ID_Curso ON Alunos
CREATE NONCLUSTERED INDEX ix_ID_Curso_Nome_Aluno ON Alunos(ID_Cursos, Nome_Aluno)
GO

-- Index Merge Join
SELECT Alunos.Nome_Aluno, Cursos.Nome_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)


-- Merge join só consegue efetuar join com operações de igualdade
-- Gera erro...
SELECT Alunos.Nome_Aluno, Cursos.Nome_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos > Cursos.ID_Cursos
OPTION (MERGE JOIN)


-- Residual Predicates
SELECT Alunos.Nome_Aluno, Cursos.Nome_Curso
  FROM Alunos
  LEFT OUTER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
   AND Alunos.Nome_Aluno = 'Fabiano Amorim'
OPTION (MERGE JOIN)

/*
Verificar nas propriedades do Join (executio plan) que foi utilizado o Merge Join 
Many to Many = False, ou seja foi utilizado um Join do Tipo One to Many. 
Vamos analisar o pseudocode do Merge Join para entender o One to Many.

SELECT TOP 5 * FROM Cursos ORDER BY 1
SELECT TOP 3 ID_Cursos, Nome_Aluno FROM Alunos ORDER BY 1

Get first row Cursos from input 1
Get first row Alunos from input 2
While not at the end of either input
Begin
  If Cursos joins with Alunos
  Begin
    Output(Cursos, Alunos)
    Get next row Alunos from input 2
  end
  else if Cursos < Alunos
    get next row Cursos from input 1
  else
    get next row Alunos form input 2
end
*/


/*
  Merge Join - Many to Many = True
*/

IF OBJECT_ID('Alunos') IS NOT NULL
BEGIN
  DROP TABLE Alunos
  DROP TABLE Cursos
END
GO
CREATE TABLE Cursos (ID_Cursos INT, Nome_Curso VARCHAR(80))
CREATE TABLE Alunos (ID_Alunos INT, Nome_Aluno VARCHAR(80), ID_Cursos INT)

CREATE CLUSTERED INDEX ix_ID_Cursos ON Cursos(ID_Cursos)
CREATE CLUSTERED INDEX ix_ID_Alunos ON Alunos(ID_Alunos)
CREATE NONCLUSTERED INDEX ix_ID_Curso_Nome_Aluno ON Alunos(ID_Cursos, Nome_Aluno)
GO

INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (1, 'Medicina')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (2, 'Educação Física')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (3, 'Sistemas de Informação')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (4, 'Engenharia')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (5, 'Física Quantica')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (6, 'Paisagismo')
INSERT INTO Cursos (ID_Cursos, Nome_Curso)  VALUES (7, 'Agronomia')
GO

INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim', 2)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (2, 'Laerte Junior', 6)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (3, 'Fabricio Catae', 5)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (4, 'Thiago Zavaschi', 3)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (5, 'Diego Nogare', 4)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (6, 'Felipe Ferreira', 3)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (7, 'Rodrigo Fernandes', 5)
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (8, 'Nilton Pinheiro', 4)
GO

-- OK
SELECT Alunos.Nome_Aluno, Cursos.Nome_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)

-- Ex: 
INSERT INTO Alunos (ID_Alunos, Nome_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim 2', 2)

SELECT * FROM Alunos

/*
Após inserir a linha duplicada na tabela de Alunos vamos utilizar o mesmo 
PseudoCode do One to Many para entender bem o problema

SELECT TOP 3 ID_Cursos, Nome_Aluno FROM Alunos ORDER BY 1
SELECT TOP 5 * FROM Cursos ORDER BY 1

get first row Alunos from input 1
get first row Cursos from input 2
while not at the end of either input
begin
  if Alunos joins with Cursos
  begin
    output (Alunos, Cursos)
    get next row Cursos from input 2
  end
  else if Alunos < Cursos
    get next row Alunos from input 1
  else
    get next row Cursos from input 2
end
*/

-- Defina corretamente os índices, se for único, defina como único.
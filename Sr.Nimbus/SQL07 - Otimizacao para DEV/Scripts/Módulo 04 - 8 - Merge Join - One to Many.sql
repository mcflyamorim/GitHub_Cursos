/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Merge Join
*/

IF OBJECT_ID('Alunos') IS NOT NULL
BEGIN
  DROP TABLE Alunos
  DROP TABLE Cursos
END
GO
CREATE TABLE Cursos (ID_Cursos INT PRIMARY KEY, ContactName_Curso VARCHAR(80))
CREATE TABLE Alunos (ID_Alunos INT PRIMARY KEY, ContactName_Aluno VARCHAR(80), ID_Cursos INT)
GO

INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (1, 'Medicina')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (2, 'Educação Física')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (3, 'Sistemas de Informação')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (4, 'Engenharia')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (5, 'Física Quantica')
INSERT INTO Cursos (ID_Cursos, ContactName_Curso)  VALUES (6, 'Paisagismo')
GO

INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim', 2)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (2, 'Laerte Junior', 6)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (3, 'Fabricio Catae', 5)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (4, 'Thiago Zavaschi', 3)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (5, 'Diego Nogare', 4)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (6, 'Felipe Ferreira', 3)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (7, 'Rodrigo Fernandes', 5)
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (8, 'Nilton Pinheiro', 4)

-- Verificar dados das tabelas
SELECT * FROM Alunos
SELECT * FROM Cursos

-- Como fazer para retornar todos os alunos e seus respectivos cursos? 
-- R: Vai no fichario e para cada aluno percorra a tabela Cursos retornando os Cursos correspondentes.

-- E se ambas as tabelas estivessem ordenadas por ID_Cursos ?
SELECT * FROM Alunos ORDER BY ID_Cursos
SELECT * FROM Cursos

-- Como fazer para retornar todos os alunos e seus respectivos cursos? 
-- R: Vai no fichario e para cada aluno retornando os Cursos correspondentes.

-- Força o Merge Join utilizando o Hint. Verificar o SORT gerado.
-- Sort Merge Join
SET STATISTICS PROFILE ON
SELECT CONVERT(VarChar, Alunos.ID_Alunos)+'-'+Alunos.ContactName_Aluno, 
       CONVERT(VarChar, Cursos.ID_Cursos)+'-'+Cursos.ContactName_Curso
  FROM Alunos
 INNER JOIN Cursos
    ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)
SET STATISTICS PROFILE OFF
GO


-- Cria um index por ID_Cursos para evitar o SORT
CREATE NONCLUSTERED INDEX ix_ID_Curso ON Alunos(ID_Cursos)

-- Agora gerou o Lookup para ler a coluna ContactName_Aluno
SELECT Alunos.ContactName_Aluno, Cursos.ContactName_Curso
FROM Alunos
INNER JOIN Cursos
ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)

-- Cria um covered index por ID_Cursos e ContactName_Aluno para evitar o Lookup
CREATE NONCLUSTERED INDEX ix_ID_Curso_ContactName_Aluno ON Alunos(ID_Cursos, ContactName_Aluno)

-- OK
-- Index Merge Join
SELECT Alunos.ContactName_Aluno, Cursos.ContactName_Curso
FROM Alunos
INNER JOIN Cursos
ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)

-- OK
-- Residual Predicates
SELECT Alunos.ContactName_Aluno, Cursos.ContactName_Curso
FROM Alunos
LEFT OUTER JOIN Cursos
ON Alunos.ID_Cursos = Cursos.ID_Cursos
AND Alunos.ContactName_Aluno LIKE 'F%'
OPTION (MERGE JOIN)

/*
Verificar nas propriedades do Join (executio plan) que foi utilizado o Merge Join 
Many to Many = False, ou seja foi utilizado um Join do Tipo One to Many. 
Vamos analisar o pseudocode do Merge Join para entender o One to Many.

SELECT TOP 5 * FROM Cursos ORDER BY 1
SELECT TOP 3 ID_Cursos, ContactName_Aluno FROM Alunos ORDER BY 1

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

-- Analisar Merge Join - Many to Many
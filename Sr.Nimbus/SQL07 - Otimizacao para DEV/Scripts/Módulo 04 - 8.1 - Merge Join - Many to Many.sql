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
CREATE TABLE Cursos (ID_Cursos INT, ContactName_Curso VARCHAR(80))
CREATE TABLE Alunos (ID_Alunos INT, ContactName_Aluno VARCHAR(80), ID_Cursos INT)

CREATE CLUSTERED INDEX ix_ID_Cursos ON Cursos(ID_Cursos)
CREATE CLUSTERED INDEX ix_ID_Alunos ON Alunos(ID_Alunos)

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

-- Cria um convered index por ID_Cursos e ContactName_Aluno para evitar o Lookup
CREATE NONCLUSTERED INDEX ix_ID_Curso_ContactName_Aluno ON Alunos(ID_Cursos, ContactName_Aluno)

-- OK
SELECT Alunos.ContactName_Aluno, Cursos.ContactName_Curso
FROM Alunos
INNER JOIN Cursos
ON Alunos.ID_Cursos = Cursos.ID_Cursos
OPTION (MERGE JOIN)

/*
Agora ele utilizou o Many to Many, mas porque?
Porque ele não pode confiar que os valores na coluna "ID_Cursos" das tabelas serão unicos.

Quando isso acontece ele salva a linha que resultou no join e posteriormente caso o valor do input 1 
for duplicado ele volta nesta linha. E se o valor não for duplicado ele já descarta os dados salvos.

Pergunta para ganhar um brinde. Onde você acha que ele salva estas linhas?

*/

-- Ex: 
INSERT INTO Alunos (ID_Alunos, ContactName_Aluno, ID_Cursos)  VALUES (1, 'Fabiano Amorim', 2)

select * from Alunos

/*
Após inserir a linha duplicada na tabela de Alunos vamos utilizar o mesmo 
PseudoCode do One to Many para entender bem o problema

SELECT TOP 3 ID_Cursos, ContactName_Aluno FROM Alunos ORDER BY 1
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


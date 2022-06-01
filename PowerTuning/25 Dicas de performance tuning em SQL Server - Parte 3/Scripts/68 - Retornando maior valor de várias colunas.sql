USE Northwind
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO

CREATE TABLE Tab1 (Nome VARCHAR(200), Nota1 Int, Nota2 Int, Nota3 Int, Nota4 Int, Nota5 Int)
GO

INSERT INTO Tab1 VALUES('Fabiano', 2, 4, 6, 7, 10), 
                       ('Felipe', 2, 4, 6, 7, 4), 
                       ('João', 2, 4, 6, 7, 9), 
                       ('Carlos', 2, 4, 6, 7, 8)
GO

-- Qual foi a maior nota por aluno? 
SELECT * FROM Tab1


-- Row valued constructors + cross apply
SELECT Nome, MAX(Result1.Notas)
  FROM Tab1
 CROSS APPLY (VALUES(Nota1), (Nota2), (Nota3), (Nota4), (Nota5)) AS Result1(Notas)
 GROUP BY Nome
GO

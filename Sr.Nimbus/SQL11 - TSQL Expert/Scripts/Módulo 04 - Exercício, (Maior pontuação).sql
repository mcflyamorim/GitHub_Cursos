/*
  Sr.Nimbus - T-SQL Expert
         Módulo 04
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Exercício, qual a maior pontuação por Aluno?
DECLARE @TabPontuacao AS TABLE
(
   Nome varchar(15) PRIMARY KEY,
   Pontuacao1 tinyint,
   Pontuacao2 tinyint,
   Pontuacao3 tinyint
);

INSERT @TabPontuacao (Nome, Pontuacao1, Pontuacao2, Pontuacao3)
VALUES ('Fabiano', 3, 9, 10),
       ('Pedro', 16, 9, 8),
       ('Paulo', 8, 9, 8)

SELECT * FROM @TabPontuacao


-- Resultado esperado:
/*
  Nome            Maior_Pontuacao
  --------------- ---------------
  Fabiano                      10
  Paulo                         9
  Pedro                        16
*/
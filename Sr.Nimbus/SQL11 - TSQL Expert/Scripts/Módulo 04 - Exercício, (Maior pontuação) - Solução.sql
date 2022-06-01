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


-- Resposta 1:
;WITH CTE_1
AS
(
SELECT *
  FROM @TabPontuacao UNPIVOT (Valor FOR Pontuacao in ([Pontuacao1],[Pontuacao2],[Pontuacao3])) up
)
SELECT Nome, MAX(Valor) 
  FROM CTE_1
 GROUP BY Nome

-- Resposta 2
SELECT Tab1.Nome,
       MAX(Tab2.Pontuacao) AS Maior_Pontuacao
  FROM @TabPontuacao AS Tab1
 CROSS APPLY (VALUES (Tab1.Pontuacao1),
                     (Tab1.Pontuacao2),
                     (Tab1.Pontuacao3)) AS Tab2 (Pontuacao)
GROUP BY Tab1.Nome
ORDER BY Tab1.Nome;
GO




-- Testes performance 
IF OBJECT_ID('TMP') IS NOT NULL
  DROP TABLE TMP

SELECT TOP 100000
       ContactName AS Nome,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao1,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao2,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao3
  INTO TMP
  FROM CustomersBig
GO
INSERT INTO TMP
SELECT TOP 30000
       NULL AS Nome,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao1,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao2,
       ABS(CHECKSUM(NEWID()) / 10000000) AS Pontuacao3
  FROM CustomersBig
GO
CREATE CLUSTERED INDEX ix ON TMP (Nome)
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
-- Resposta 1:
;WITH CTE_1
AS
(
SELECT *
  FROM TMP UNPIVOT (Valor FOR Pontuacao in ([Pontuacao1],[Pontuacao2],[Pontuacao3])) AS up
)
SELECT Nome, MAX(Valor) 
  FROM CTE_1
 GROUP BY Nome
 ORDER BY Nome;
GO

CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE()
GO
-- Resposta 2
SELECT Tab1.Nome,
       MAX(Tab2.Pontuacao) AS Maior_Pontuacao
  FROM TMP AS Tab1
 CROSS APPLY (VALUES (Tab1.Pontuacao1),
                     (Tab1.Pontuacao2),
                     (Tab1.Pontuacao3)) AS Tab2 (Pontuacao)
GROUP BY Tab1.Nome
ORDER BY Tab1.Nome;
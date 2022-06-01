/*
  Sr.Nimbus - T-SQL Expert
        Query Tuning 
         Exercícios
  http://www.srnimbus.com.br
*/

----------------------------------------
--------- Identificando Ilhas ----------
----------------------------------------
/*
  Escreva uma consulta que retorne o período existente
*/

USE tempdb;
GO
IF OBJECT_ID('dbo.Tab1') IS NOT NULL
  DROP TABLE dbo.Tab1;
GO
CREATE TABLE dbo.Tab1 (Col1 INT NOT NULL CONSTRAINT PK_Tab1 PRIMARY KEY);
INSERT INTO dbo.Tab1(Col1) VALUES(1);
INSERT INTO dbo.Tab1(Col1) VALUES(2);
INSERT INTO dbo.Tab1(Col1) VALUES(5);
INSERT INTO dbo.Tab1(Col1) VALUES(6);
INSERT INTO dbo.Tab1(Col1) VALUES(7);
INSERT INTO dbo.Tab1(Col1) VALUES(15);
INSERT INTO dbo.Tab1(Col1) VALUES(16);
GO
SELECT * FROM Tab1

-- Resultado esperado Ilhas
/*
  InicioRange FimRange
  ----------- -----------
  1           2
  5           7
  15          16
*/


-- Resposta
SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b)
  FROM Tab1 a
GO

SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1),
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1 + 1) ProxLinha -- Exemplo como retornar próxima linha
  FROM Tab1 a
GO

SELECT * FROM Tab1 b
 WHERE NOT EXISTS(SELECT 1 
                    FROM Tab1 c 
                   WHERE c.Col1 = b.Col1 + 1)
GO

SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1
           AND NOT EXISTS(SELECT 1 
                            FROM Tab1 c 
                           WHERE c.Col1 = b.Col1 + 1))
  FROM Tab1 a
GO

SELECT MIN(Col1) AS InicioRange, 
       MAX(Col1) AS FimRange
  FROM (SELECT a.Col1, 
               (SELECT MIN(b.Col1)
                  FROM Tab1 b 
                 WHERE b.Col1 >= a.Col1
                   AND NOT EXISTS(SELECT 1 
                                    FROM Tab1 c 
                                   WHERE c.Col1 = b.Col1 +1)) as Grp
          FROM Tab1 a) AS Tab
 GROUP BY Grp
GO

-- Usando ROW_NUMBER

SELECT Col1, 
       ROW_NUMBER() OVER(ORDER BY Col1) AS rn
  FROM dbo.Tab1
GO

SELECT Col1, 
       Col1 - ROW_NUMBER() OVER(ORDER BY Col1) AS Grp
  FROM dbo.Tab1
GO

SELECT MIN(Col1) AS InicioRange, 
       MAX(Col1) AS FimRange
  FROM (SELECT Col1, 
               Col1 - ROW_NUMBER() OVER(ORDER BY Col1) AS Grp
          FROM dbo.Tab1) AS D
 GROUP BY Grp
GO

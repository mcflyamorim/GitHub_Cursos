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
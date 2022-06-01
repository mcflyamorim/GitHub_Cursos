/*
  Error 601
*/

-- Preparando o ambiente
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
CREATE TABLE Tab1 (ID INT, Col1 Char(500) DEFAULT NEWID())
GO
INSERT Tab1(ID) VALUES(0), (1)
GO
CREATE TABLE Tab2 (ID INT PRIMARY KEY, Col1 Char(500) DEFAULT NEWID())
GO
INSERT Tab2(ID) VALUES(0), (1)
GO

-- Conexão 1
BEGIN TRAN
-- Obter lock na linha com o ID 0
UPDATE Tab2 SET ID = ID 
WHERE ID = 0

-- Conexão 2
SELECT * FROM Tab1 WITH (NOLOCK)
WHERE EXISTS (SELECT * 
                FROM Tab2 
               WHERE Tab1.ID = Tab2.ID)

-- Conexão 1
-- A conexão 2 já leu o ID 0 pois a tabela Tab1 esta com o WITH Nolock, 
-- e esta esperando para fazer o join com a Tab2 que esta bloqueada
-- pelo Update
DELETE Tab1 WHERE ID = 0
COMMIT TRAN
GO

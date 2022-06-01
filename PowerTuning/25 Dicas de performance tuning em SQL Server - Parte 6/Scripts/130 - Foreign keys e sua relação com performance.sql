USE Northwind
GO

/*
  Foreign Keys Constraints
*/
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1

CREATE TABLE Tab1 (Tab1_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col2 Char(200))
CREATE TABLE Tab2 (Tab2_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col1 Integer NOT NULL, Tab2_Col2 Char(200))
ALTER TABLE Tab2 ADD CONSTRAINT fk FOREIGN KEY (Tab1_Col1) REFERENCES Tab1(Tab1_Col1)
GO


-- Plano bom... não lê dados da tabela Tab1...
SELECT Tab2.* 
  FROM Tab2
 INNER JOIN Tab1 
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1 
GO

IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Tab1_Col1 Integer NOT NULL, Tab1_Col2 Integer NOT NULL, Tab1_Col3 Char(200), PRIMARY KEY(Tab1_Col1, Tab1_Col2))
CREATE TABLE Tab2 (Tab2_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col1 Integer NOT NULL, Tab1_Col2 Integer NOT NULL, Tab2_Col2 Char(200))
ALTER TABLE Tab2 ADD CONSTRAINT fk FOREIGN KEY (Tab1_Col1, Tab1_Col2) REFERENCES Tab1(Tab1_Col1, Tab1_Col2)
CREATE INDEX ix ON Tab2(Tab1_Col1, Tab1_Col2)
GO
 
-- Multi colunas... não funciona... lixo...
SELECT Tab2.*
  FROM Tab2
 INNER JOIN Tab1 
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
   AND Tab1.Tab1_Col2 = Tab2.Tab1_Col2
GO

 
-- Porquê não aplicar otimização no índice ix...
-- Se Tab2.Tab1_Col2 = 10, então Tab1.Tab1_Col2 = 10... 
-- poderiamos ter algumas melhoras por aqui...
SELECT Tab2.* 
FROM Tab2
INNER JOIN Tab1
  ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
WHERE Tab2.Tab1_Col2 = 10
GO

-- Tipo isso...
SELECT Tab2.* 
FROM Tab2
INNER JOIN Tab1
  ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
WHERE Tab2.Tab1_Col2 = 10
AND Tab1.Tab1_Col2 = 10
GO


-- https://blogs.msdn.microsoft.com/conor_cunningham_msft/2009/11/12/conor-vs-foreign-key-join-elimination/
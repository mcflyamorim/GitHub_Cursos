/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

/*
  Foreign Keys
*/

-- Preparando o ambiente
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Tab1_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col2 Char(200))
CREATE TABLE Tab2 (Tab2_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col1 Integer NOT NULL, Tab2_Col2 Char(200))
ALTER TABLE Tab2 ADD CONSTRAINT fk FOREIGN KEY (Tab1_Col1) REFERENCES Tab1(Tab1_Col1)
GO
 
-- Execution plan não lê a tabela Tab1
SELECT Tab2.*
  FROM Tab2
 INNER JOIN Tab1 
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
GO

-- Verificar se a FK é trusted
SELECT Object_name(parent_object_id) AS Tabela, name, type_desc, is_not_trusted
  FROM sys.foreign_keys
 WHERE name = 'fk'
GO

-- Setar a FK como nontrusted
ALTER TABLE Tab2 NOCHECK CONSTRAINT fk
GO

-- Execution plan lê a tabela Tab1
SELECT Tab2.*
  FROM Tab2
 INNER JOIN Tab1 
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
GO

/*
  Quando não funciona mas deveria funcionar
*/

-- 1 - Quando utilizamos tabelas temporárias
-- Nota: Join elimination nunca é executada no banco tempdb

IF OBJECT_ID('tempdb.dbo.#Tab2') IS NOT NULL
  DROP TABLE #Tab2
GO
IF OBJECT_ID('tempdb.dbo.#Tab1') IS NOT NULL
  DROP TABLE #Tab1
GO
CREATE TABLE #Tab1 (Tab1_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col2 Char(200))
CREATE TABLE #Tab2 (Tab2_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col1 Integer NOT NULL, Tab2_Col2 Char(200))
ALTER TABLE #Tab2 ADD CONSTRAINT fk FOREIGN KEY (Tab1_Col1) REFERENCES #Tab1(Tab1_Col1)
GO

-- Fail
SELECT #Tab2.*
  FROM #Tab2
 INNER JOIN #Tab1 
    ON #Tab1.Tab1_Col1 = #Tab2.Tab1_Col1
GO

-- 2 - Quando selecionamos a coluna da tabela relacionada
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Tab1_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col2 Char(200))
CREATE TABLE Tab2 (Tab2_Col1 Integer NOT NULL PRIMARY KEY, Tab1_Col1 Integer NOT NULL, Tab2_Col2 Char(200))
ALTER TABLE Tab2 ADD CONSTRAINT fk FOREIGN KEY (Tab1_Col1) REFERENCES Tab1(Tab1_Col1)
GO

-- Ao invés de selecionar a coluna Tab1_Col1 da tabela Tab2
-- Seleciono a coluna da tabela Tab1. O que na teoria é a mesma coisa
SELECT Tab1.Tab1_Col1,
       Tab2.Tab2_Col2
  FROM Tab1
 INNER JOIN Tab2
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
GO

-- 3 - Quando aplicamos um filtro na coluna chave
SELECT Tab2.*
  FROM Tab1
 INNER JOIN Tab2
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
 WHERE Tab2.Tab1_Col1 = 1 -- Ou Tab1.Tab1_Col1 = 1
-- Nota Triste: No exemplo "Tab2.Tab1_Col1 = 1" o Oracle remove o join :-(
GO

-- 4 - Quando utilizamos multi-columns FKs
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
 
SELECT Tab2.*
  FROM Tab2
 INNER JOIN Tab1 
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
   AND Tab1.Tab1_Col2 = Tab2.Tab1_Col2

-- A consulta abaixo também poderia ser 
-- beneficiada da eliminação do join
-- Basta aplicar o mesmo filtro do where na Tab1.Tab1_Col2
SELECT Tab2.* 
  FROM Tab2
 INNER JOIN Tab1
    ON Tab1.Tab1_Col1 = Tab2.Tab1_Col1
 WHERE Tab2.Tab1_Col2 = 10
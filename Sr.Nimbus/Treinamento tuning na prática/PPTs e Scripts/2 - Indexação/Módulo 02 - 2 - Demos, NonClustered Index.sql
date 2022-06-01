/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/




USE NorthWind
GO

/*
  Índices nonclustered são pequenas cópias dos dados
  da tabela, com sua própria árvore balanceada.
  
  Índices nonclustered podem existir em tabelas HEAP
  ou Cluster.
  
  Quando a tabela é uma HEAP o índice nonclustered contém
  um RID para a localização da linha na HEAP.
  Quando a tabela tem um índice cluster, o índice 
  nonclustered contém a chave do índice cluster.
*/


-- Exemplo de falta de índice nonclustered
SET STATISTICS IO ON
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName = 'Folies gourmandes 15BB3518'
SET STATISTICS IO OFF

-- Na ausência da palavra NONCLUSTERED
-- o índice é considerado NONCLUSTERED.
CREATE NONCLUSTERED INDEX ix_CompanyName ON CustomersBig(CompanyName)
GO

/*
  Agora a consulta pode fazer proveito do índice ix_CompanyName
*/
SET STATISTICS IO ON
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName = 'Centro comercial Moctezuma B6950DA3'
SET STATISTICS IO OFF


-- Filtered Index --

/*
  No SQL Server 2008 temos os índices filtrados.
  Existem vários cenários onde podemos e devemos utilizar
  índices filtrados, vejamos alguns:
*/

/*
  Tenho uma tabela onde só consulto os dados mais recentes.
  No caso de minha tabela de Orders, digamos que eu sempre
  leio os dados maiores que 2017. 
  Porque então guardar os dados dos outros anos no índice?
*/

CREATE INDEX ix_OrderDate_Greater_Than_2005 ON OrdersBig(OrderDate)
WHERE OrderDate > '20170201'
GO

SET STATISTICS IO ON
SELECT OrderID, OrderDate
  FROM OrdersBig
 WHERE OrderDate > '20170201'
SET STATISTICS IO OFF

/*
  Filtered Index em Procedures
*/

-- DROP PROC st_TestFilteredIndex 
CREATE PROC st_TestFilteredIndex @Dt DateTime
AS
BEGIN
  SELECT OrderID, OrderDate
    FROM OrdersBig
   WHERE OrderDate > @Dt
END
GO

-- SQL não usa o índice porque o filtro é um parâmetro
EXEC st_TestFilteredIndex @Dt = '20170201'

-- Alternativa 1: Reescrever a proc com option recompile
DROP PROC st_TestFilteredIndex 
GO
CREATE PROC st_TestFilteredIndex @Dt DateTime
AS
BEGIN
  SELECT OrderID, OrderDate
    FROM OrdersBig
   WHERE OrderDate > @Dt
  OPTION (RECOMPILE)
END
GO
EXEC st_TestFilteredIndex @Dt = '20170201'

-- Alternativa 2: Reescrever a proc com o filtro fixo
DROP PROC st_TestFilteredIndex 
GO
CREATE PROC st_TestFilteredIndex @Dt DateTime
AS
BEGIN
  IF @Dt < '20170201'
  BEGIN
    SELECT OrderID, OrderDate
      FROM OrdersBig
     WHERE OrderDate > @Dt
  END
  ELSE
  BEGIN
    SELECT OrderID, OrderDate
      FROM OrdersBig
     WHERE OrderDate > @Dt
       AND OrderDate > '20170201'
  END
END
GO

-- Visualizar plano estimado (CTRL+L)
EXEC st_TestFilteredIndex @Dt = '20170201'

/*
  Plano que será incluído em cache contém o acesso a tabela 
  utilizando os dois índices
*/


/*
  Outro cenário complicado era é criação de índices únicos
  mas que aceitavam NULL.
  Vamos ver o problema.
*/

IF OBJECT_ID('TMP_Unique') IS NOT NULL
  DROP TABLE TMP_Unique
GO
CREATE TABLE TMP_Unique (ID Int)
GO

/*
  Como não posso permitir que os Valuees dupliquem, então crio um índice
  único com base na coluna ID
*/

CREATE UNIQUE INDEX ix_Unique ON TMP_Unique(ID)
GO

-- Vamos tentar inserir um o Value "1" duas vezes
INSERT INTO TMP_Unique (ID) VALUES(1) --  OK
INSERT INTO TMP_Unique (ID) VALUES(1) -- ERRO

INSERT INTO TMP_Unique (ID) VALUES(NULL) --  OK
INSERT INTO TMP_Unique (ID) VALUES(NULL) -- ERRO

/*
  Até ai ok, mas e se eu quiser aceitar Valuees NULL duplicados?
  A solução existente seria criar uma view indexada com o 
  WHERE IS NOT NULL
  Com o índice filtered ficou bem mais fácil
*/
TRUNCATE TABLE TMP_Unique
GO
DROP INDEX ix_Unique ON TMP_Unique
GO
CREATE UNIQUE INDEX ix_Unique ON TMP_Unique(ID)
WHERE ID IS NOT NULL

INSERT INTO TMP_Unique (ID) VALUES(NULL) -- OK
INSERT INTO TMP_Unique (ID) VALUES(NULL) -- OK

INSERT INTO TMP_Unique (ID) VALUES(1) -- OK
INSERT INTO TMP_Unique (ID) VALUES(1) -- ERRO


-- Computed Index --
/*
  Podemos indexar colunas calculadas para obter melhor performance.
  Um exemplo classico é o seguinte:
*/

SELECT *
  FROM OrdersBig
 WHERE YEAR(OrderDate) = 2010
 
/*
  Mesmo que você criar um índice por OrderDate o SQL 
  não irá utilizar o índice.
  Uma alternativa é criar uma coluna calculada e indexar a coluna.
*/

ALTER TABLE OrdersBig ADD Orders_Year AS YEAR(OrderDate)
GO

CREATE INDEX ix_Orders_Year ON OrdersBig(Orders_Year) INCLUDE(OrderDate, CustomerID, Value)
GO

SELECT * 
  FROM OrdersBig
 WHERE YEAR(OrderDate) = 2010

/*
  No oracle é bem mais fácil, é só criar o índice com base na expressão
  CREATE INDEX ix_Orders_Year ON OrdersBig(YEAR(OrderDate))
*/


-- Consulta o tamanho dos índices
SELECT Object_Name(p.Object_Id) As Tabela,
       I.Name As Indice, 
       Total_Pages,
       Total_Pages * 8 / 1024.00 As MB
  FROM sys.Partitions AS P
 INNER JOIN sys.Allocation_Units AS A 
    ON P.Hobt_Id = A.Container_Id
 INNER JOIN sys.Indexes AS I 
    ON P.object_id = I.object_id 
   AND P.index_id = I.index_id
 WHERE p.Object_Id = Object_Id('ProductsBig')

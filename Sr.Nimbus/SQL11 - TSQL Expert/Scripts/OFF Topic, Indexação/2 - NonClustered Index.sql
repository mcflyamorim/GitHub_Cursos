/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
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

/*
  Novamente, vamos simular os 6 IOs usando o DBCC PAGE
*/
-- Vamos identificar a página Root do índice ix_CompanyName
SELECT dbo.fn_HexaToDBCCPAGE(Root) 
  FROM sys.sysindexes
 WHERE name = 'ix_CompanyName'
   AND id = OBJECT_ID ('CustomersBig')

-- Vamos navegar pelo índice a partir da página Raiz procurando pelo Value
-- CustomerID = 80000
DBCC TRACEON (3604)
DBCC PAGE (Northwind,1,10594,3) -- 1 Leitura
DBCC PAGE (Northwind,1,10597,3) -- 2 Leitura
DBCC PAGE (Northwind,1,27829,3) -- 3 Leitura Encontramos o CompanyName = 'Centro comercial Moctezuma B6950DA3'

-- Com o CustomerID 74045, vamos navegar pelo índice cluster para 
-- achar o Value da coluna Col1, pois ela não pertence ao índice

SELECT dbo.fn_HexaToDBCCPAGE(Root)
  FROM sys.sysindexes
 WHERE name = 'xpk_CustomersBig'
   AND id = OBJECT_ID ('CustomersBig')

DBCC PAGE (Northwind,1,14730,3) -- 4 Leitura
DBCC PAGE (Northwind,1,14729,3)  -- 5 Leitura
DBCC PAGE (Northwind,1,21235,3) -- 6 Leitura Encontramos o CustomerID = 80000


-- Covered Index --

/*
  Para a consulta que utilizamos acima, poderiamos evitar este extra
  passo de buscar os dados da coluna Col1 e Col2 no índice criando um 
  covered index, ou seja, um índice que cobre toda minha consulta.
  No SQL Server 2000 a única forma de fazer isso era incluindo a
  coluna Col1 como chave do Índice, mas isso não faz muito sentido.
  Pois neste caso não fazemos filtro na coluna Col1 e Col2. Então só precisamos
  que o Value esteja no último nível do índice, para o SQL não precisar
  do lookup.
  
  A partir do SQL Server 2005 podemos utilizar a clausula INCLUDE.
  Ex:
*/

CREATE INDEX ix_CompanyName_Col1_Col2 ON CustomersBig(CompanyName) INCLUDE(Col1, Col2)
GO

SET STATISTICS IO ON
SELECT CustomerID, CompanyName, Col1 
  FROM CustomersBig
 WHERE CompanyName = 'Centro comercial Moctezuma B6950DA3'
SET STATISTICS IO OFF
/*
  Como podemos observar a consulta acima só necessita de 3 IOs
  O Value da Coluna Col1 e Col2 foi incluido no leaf level(nivel folha) 
  do índice.
*/

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
  Exclusão ímplicita de NULLs
*/

CREATE INDEX ix_CityID ON CustomersBig(CityID) INCLUDE(CompanyName)
WHERE CityID IS NOT NULL

/*
  A consulta abaixo ja sabe que estou procurando um Value
  que não é NULL, então ele pode usar o índice
*/
SELECT CustomerID, CityID, CompanyName
  FROM CustomersBig
 WHERE CityID = 2

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

-- Hash Index --

-- Preparando o banco
CREATE INDEX ix_ProductID ON Order_DetailsBig(ProductID)
/*
  Uma tentativa para minimizar os custos ocupados pelo espaço de um índice
  é gerar um hash de um Value e criar o índice com base neste hash.
  
  Um exemplo classico é na busca de colunas muito grandes, Código de barras
  Títulos, Descrição de Produtos etc...
  Vejamos a ídeia abaixo:
*/


-- A consulta abaixo faz um index scan pois não existe nenhum
-- índice nas colunas ProductName e col1
SELECT ProductsBig.ProductID, SUM(OrdersBig.Value)
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 WHERE ProductsBig.ProductName = 'Camembert Pierrot 4809558D'
   AND ProductsBig.Col1 = 'FF9B8A91-0652-409B-A095-A5B8296FC239'
 GROUP BY ProductsBig.ProductID
GO

-- DROP INDEX ix_ProductName_Col1 ON ProductsBig
CREATE INDEX ix_ProductName_Col1 ON ProductsBig(ProductName, Col1)
GO

-- Agora conseguimos usar o índice ix_ProductName_Col1 
SELECT ProductsBig.ProductID, SUM(OrdersBig.Value)
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 WHERE ProductsBig.ProductName = 'Camembert Pierrot 4809558D'
   AND ProductsBig.Col1 = 'FF9B8A91-0652-409B-A095-A5B8296FC239'
 GROUP BY ProductsBig.ProductID
GO

/*
  Mas qual o custo deste índice?... 
  Já que as colunas são bem grandes.
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

/*
  Resultado da consulta acima:
  Tabela        Indice                   Total_Pages  MB
  ------------- -------------------      ------------ -----------
  ProductsBig	  xpk_ProductsBig	         9869	        77.1015625
  ProductsBig	  ix_ProductName_Col1	     9590	        74.9218750
*/

/*
  Conforme podemos observar o tamanho do índice é praticamente
  o tamanho da tabela
*/


/*
  Vejamos se conseguimos melhor isso com o uso do HashIndex
*/

-- ALTER TABLE ProductsBig DROP COLUMN Hash_ProductName_Col1
ALTER TABLE ProductsBig ADD Hash_ProductName_Col1 AS BINARY_CHECKSUM(ProductName, Col1)
GO
-- DROP INDEX ix_Hash_ProductName_Col1 ON ProductsBig
-- DROP INDEX ix_ProductName_Col1 ON ProductsBig
CREATE INDEX ix_Hash_ProductName_Col1 ON ProductsBig(Hash_ProductName_Col1) 
GO

-- Cuidado pois o hash pode gerar colisões
SELECT Hash_ProductName_Col1, Count(*)
  FROM ProductsBig
 GROUP BY Hash_ProductName_Col1
HAVING Count(*) > 1
 ORDER BY 2 DESC

-- O SQL utilizou o HashIndex
SELECT ProductsBig.ProductID, SUM(OrdersBig.Value)
  FROM ProductsBig WITH(index=ix_Hash_ProductName_Col1)
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID    
 WHERE ProductsBig.Hash_ProductName_Col1 = BINARY_CHECKSUM('Camembert Pierrot 4809558D', 'FF9B8A91-0652-409B-A095-A5B8296FC239')
   AND ProductsBig.ProductName = 'Camembert Pierrot 4809558D'
   AND ProductsBig.Col1 = 'FF9B8A91-0652-409B-A095-A5B8296FC239'
 GROUP BY ProductsBig.ProductID

-- Vejamos o tamanho dos índices
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

/*
  Resultado da consulta acima:
  Tabela        Indice                   Total_Pages  MB
  ------------- -------------------      ------------ -----------
  ProductsBig	  xpk_ProductsBig	         9869	        77.1015625
  ProductsBig	  ix_Hash_ProductName_Col1	1781	        13.9140625
  ProductsBig	  ix_ProductName_Col1	     9590	        74.9218750
*/

-- Porque o SQL Server não usa meu índice ? -- 
/*
  Vamos analisar um exemplo bem interessante em relação a esta velha dúvida.
*/

-- Criando os dados para o teste
USE Tempdb
GO
IF OBJECT_ID('TABTeste') IS NOT NULL
  DROP TABLE TABTeste
GO

CREATE TABLE TabTeste(ID    Int Identity(1,1) Primary Key,
                      CompanyName  VarChar(50) NOT NULL,
                      Value Int NOT NULL)
GO
DECLARE @i INT
SET @i = 0
WHILE (@i < 1000)
BEGIN
    INSERT INTO TabTeste(CompanyName, Value)
    VALUES('Fabiano', 0) 
    SET @i = @i + 1
END;

-- Analisando os dados da tabela
SELECT * FROM TabTeste

-- Criando um índice por CompanyName e Value
CREATE NONCLUSTERED INDEX ix_TesteSem_Include ON TabTeste(CompanyName, Value)
GO

/*
  Consulta os dados de todos os registros onde CompanyName seja
  igual a 'Fabiano' e o Value seja menor ou igual a 10, 
  ordenado por ID, ou seja com estes dados, a tabela toda.
  
  A consulta abaixo não usa o índice:
*/
SELECT ID
  FROM TabTeste
 WHERE CompanyName = 'Fabiano'
   AND Value <= 10
 ORDER BY ID
 
-- Re-Criando o índice, mas desta vez incluindo a coluna Value 
-- como INCLUDE ele passa a utilizar o índice, porque?
CREATE NONCLUSTERED INDEX ix_Teste_Include ON TabTeste(CompanyName) INCLUDE(Value)
GO

-- Usando o índice ix_Teste_Include
SELECT ID
  FROM TabTeste
 WHERE CompanyName = 'Fabiano'
   AND Value <= 10
 ORDER BY ID
 
-- Apagar o indice para continuar os testes...
DROP INDEX TabTeste.ix_Teste_Include 
GO

-- Forçando o uso do índice com o hint INDEX
-- temos um sort pesado (82% do custo da consulta)
SELECT ID
  FROM TabTeste WITH(INDEX = ix_TesteSem_Include)
 WHERE CompanyName = 'Fabiano'
   AND Value <= 10
 ORDER BY ID
GO

/*
  A pergunta é, porque o SQL não pode confiar no ID 
  que esta no índice noncluster? 
  Porque é necessário fazer o SORT?
  Se eu remover o ORDER BY, os dados já vem na ordem de ID.
*/
SELECT ID
  FROM TabTeste WITH(INDEX = ix_TesteSem_Include)
 WHERE CompanyName = 'Fabiano'
   AND Value <= 10
GO

/*
  Vamos analisar como os dados estão armazenados no índice
*/

-- Pega o hexadecimal da primeira página do índice na coluna ROOT
SELECT id, name, root, dbo.fn_HexaToDBCCPAGE(Root) 
  FROM SysIndexes
 WHERE ID = OBJECT_ID('TabTeste')
   AND name = 'ix_TesteSem_Include'
   
-- Usando a fn_HexaToDBCCPAGE para gerar o DBCC PAGE
SELECT dbo.fn_HexaToDBCCPAGE(0xEE0000000100)

-- Vamos navegar pelo índice a partir da página Raiz
DBCC TRACEON (3604)
DBCC PAGE (2,1,238,3)
-- Pegamos o Value de ChildPageId para ver os dados da próxima página na árvore balanceada do índice
DBCC PAGE(2,1,187,3)
GO
DBCC PAGE(2,1,249,3)

/* 
  Como podemos ver os dados estão ordenados por ID no índice, 
  porque não confiar neste ordem? 
  
  E se eu fizer o seguinte insert?
*/

SET IDENTITY_INSERT TabTeste ON 
INSERT INTO TabTeste(ID, CompanyName, Value) VALUES(-1, 'Fabiano', 1) 
SET IDENTITY_INSERT TabTeste OFF 

-- Agora rodando novamente a consulta sem o order by para simular a leitura na ordem do indice
-- Esta ordenado?
SELECT ID
  FROM TabTeste
 WHERE CompanyName = 'Fabiano'
   AND Value <= 10
   
/*
  Lembre-se o índice esta ordenado por CompanyName e Value.
  A ordem do ID depende primeiro da ordenação de CompanyName e Value.
*/
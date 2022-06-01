/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

IF OBJECT_ID('HeapProducts', 'u') IS NOT NULL
  DROP TABLE HeapProducts
GO
-- Heap é uma tabela sem índice Cluster
CREATE TABLE HeapProducts (ProductID   Integer      NOT NULL,
                           ProductName VarChar(200) NOT NULL, 
                           Col1        VarChar(6000) NOT NULL)
GO

/*
  Insert de 1 milhão de linhas com minimal log
*/

sp_helpindex HeapProducts
GO

INSERT INTO HeapProducts WITH(TABLOCK)
SELECT ProductID, ProductName, NEWID() FROM ProductsBig
GO

IF OBJECT_ID('ClusterProducts', 'u') IS NOT NULL
  DROP TABLE ClusterProducts
GO
-- Heap é uma tabela sem índice Cluster
CREATE TABLE ClusterProducts (ProductID   Integer      NOT NULL PRIMARY KEY,
                              ProductName VarChar(200) NOT NULL, 
                              Col1        VarChar(6000) NOT NULL)
GO

INSERT INTO ClusterProducts WITH(TABLOCK)
SELECT * FROM ProductsBig
GO


-- ANTES DE PROSSEGUIR EXPLICAR ÍNDICE CLUSTER --







/*
  A estrutura de uma heap é composta apenas por páginas de dados
  sem nenhuma ordem específica.
  IAM (Index Allocation Map) contem as páginas utilizadas por uma heap.
  Todos os índices nonclustered contem o RID(FileID, PageID e SlotID)
  que é um ponteiro para a linha onde estão os dados de todas as 
  colunas da tabela.
  
  DBCC IND para identificar o ID da página IAM
  e a primeira página de dados
*/
DBCC TRACEON (3604)
DBCC IND (NorthWind, HeapProducts, 1)
DBCC PAGE(NorthWind, 1, 417, 3)
GO

/*
  Consulta sem NonClustered:
  Qualquer consulta em uma HEAP sem um índice nonclustered irá gerar um TableScan
  ou seja, o SQL irá varrer a tabela toda com base nas páginas especificadas no IAM
  para procurar o valor desejado.  
*/
SELECT * FROM HeapProducts
WHERE ProductID = 10

/*
  Caso exista um índice nonclustered o SQL irá utilizar este índice para
  localizar o registro, e depois irá fazer um lookup para a página heap
  utilizando o RID para ler os dados da tabela
  
  Vamos ver um exemplo de uma leitura NonClusterd + Heap:
*/
CREATE NONCLUSTERED INDEX ix_ProductID ON HeapProducts(ProductID)
GO

-- Vamos habilitar o STATISTICS IO para verificar quantas páginas 
-- são lidas para retornar o ProductID = 10
SET STATISTICS IO ON
SELECT * FROM HeapProducts
WHERE ProductID = 10
SET STATISTICS IO OFF

/*
  4 IOs foram realizados, vamos simular estas leituras utilizando DBCC PAGE
*/

-- Vamos identificar a página Root do índice ix_ProductID
SELECT dbo.fn_HexaToDBCCPAGE(Root)
  FROM sys.sysindexes
 WHERE name = 'ix_ProductID'

-- Vamos navegar pelo índice a partir da página Raiz procurando pelo valor ProductID = 10
DBCC TRACEON (3604)
DBCC PAGE (Northwind,1,51322,3) -- 1 Leitura
DBCC PAGE (Northwind,1,51320,3) -- 2 Leitura
DBCC PAGE (Northwind,1,51184,3) -- 3 Leitura Encontramos o ProductID 10
/* 
  Agora precisamos fazer o Lookup utilizando o RID na página HEAP, 
  antes precisamos converter o hexa que contem o RIP
  0xC89C000001000900
  0xC89C 0000 0100 0900
  0x9CC8 0000 0001 0009
  SELECT CONVERT(Int, 0x9CC8) -- Página 40136
  SELECT CONVERT(Int, 0x0001) -- Arquivo 1
  SELECT CONVERT(Int, 0x0009) -- Slot 9
*/
DBCC PAGE (Northwind,1,40136,3) -- 4 Leitura
/*
  Com a 4 leitura simulamos exatamente o que o SQL Server fez para ler o 
  registro na página.
*/


-- Forwarded Records --

/*
  Como nenhuma ordem é mantida, não ocorrem page splits nos inserts.
  Caso ocorra um UPDATE que atualiza um valor de uma pág. para
  um valor maior do que o disponível na página, o SQL implementa o
  que chamamos de "Forwarded Records".
  O SQL Server move a linha para uma nova página e deixa
  um ponteiro na página atual apontando para onde o registro foi 
  incluido.
  
  Isso evita com que o SQL tenha que manter o RID nos índices 
  nonclustered atualizados.
  Mas também faz com que uma nova leitura seja efetuada para 
  ler os dados da linha.
  Por ex:
  No nosso "SELECT * FROM HeapProducts WHERE ProductID = 10"
  fizemos a leitura de 4 páginas, mas se eu atualizar a coluna Col1
  com um valor que fará com que o registro não caiba mais na página
  o SQL irá mover o registro para uma nova página e deixar o ponteiro
  para a página atual.
  Quando eu navegar pelo índice nonclustered e chegar no RID lá 
  especificado, eu irei para a pág, e lá terá um novo ponteiro 
  dizendo onde o registro esta. Isso gera o overread.
*/

-- Vamos gerar o Forwarded Record para o ProductID 10
UPDATE HeapProducts SET Col1 = REPLICATE('x', 500)
 WHERE ProductID = 10

/*
  Para verificar quandos forwarded records existem em uma tabela
  podemos fazer o seguinte.
  No SQL Server 2000:
  DBCC SHOWCONTIG (HeapProducts) WITH TABLERESULTS
  Temos a coluna ForwardedRecords.
  No SQL Server 2005:
  SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'HeapProducts'), 0, NULL , 'DETAILED')
  Temos a coluna Forwarded_Record_Count
  
  Para a consulta abaixo, podemos observar que um novo IO foi efetuado:
*/

SET STATISTICS IO ON
SELECT * FROM HeapProducts
 WHERE ProductID = 10
SET STATISTICS IO OFF

/*
  Vamos copiar os DBCC PAGE que utilizamos para chegar na pág da Heap
  para verificar como ficou a página.
*/
DBCC PAGE (Northwind,1,40136,3) -- 4 Leitura
/*
Slot 9 Offset 0x1f04 Length 9

Record Type = FORWARDING_STUB        Record Attributes =                  Record Size = 9
Memory Dump @0x000000001064BF04
0000000000000000:   04a00100 00010000 00†††††††††††††††††. .......        
Forwarding to  =  file 1 page 416 slot 0    
*/

/*
  Podemos observar que o registro foi movido para o arquivo 1 
  pág 416 slot 0.
  Maravilha!, Vamos olhar a pág 416
*/

DBCC PAGE (Northwind,1,416,3) -- 5 Leitura

/*
  Pergunta, o que irá acontecer se o Registro ProductID = 10
  for atualizado novamente, e novamente com um valor que não cabe
  na pág. 416?
  
  Teremos um forwarded record de um forwarded record?
  Vamos ver o que acontece?
*/

/*
  Primeiro precisamos encher a Pág, para isso vamos
  atualizar os registros da pág.
  Para saber até onde devemos atualizar os registros precisamos
  saber quanto espaço livre tem na pág.
  Para isso é só olhar o valor do m_freeCnt no cabeçalho da pág.
  onde esta o registro ProductID = 10, que é a página que queremos
  "encher"
*/
-- Consulta a coluna m_freeCnt
DBCC PAGE (NorthWind,1,416,3)
GO
/*
  Caso exista alguma registro na pág. atualizamos ele para um 
  valor maior, caso não exista, vamos atualizar vários 
  registos da tabela para que vários Forward Records ocorram.
*/
UPDATE HeapProducts SET Col1 = REPLICATE('x', 5000)
 WHERE ProductID = <ID DE UM REGISTRO DA Pág>
GO
UPDATE HeapProducts SET Col1 = REPLICATE('x', 5000)
 WHERE ProductID BETWEEN 20 AND 50
GO

-- Consulta novamente a coluna m_freeCnt
DBCC PAGE (NorthWind,1,416,3)
GO
UPDATE HeapProducts SET Col1 = REPLICATE('x', 5000)
 WHERE ProductID = 10
GO


/*
  Agora o registro ProductID 10 não cabe mais na página
  416 slot 0, vamos ver o que tem lá agora.
*/ 

DBCC PAGE (NorthWind,1,416,3)
GO
/*
  O Slot 0 não existe mais ná página 416.
  Na verdade ele existe mas não esta mais sendo utilizado, 
  se rodarmos o DBCC Page com a opção 2 de visualização 
  vemos no slot array que o Slot 0 não esta mais sendo utilizado
*/
DBCC PAGE (NorthWind,1,416,2)
GO
/*
OFFSET TABLE:
Row - Offset                         
1 (0x1) - 818 (0x332)                
0 (0x0) - 0 (0x0)     
*/

/* 
  Mas se o registro não esta mais na página 416 
  onde ele está?
  Vamos olhar na pág do original do registro.
*/
DBCC PAGE (Northwind,1,40136,3) -- 4 Leitura

/*
Opa, maravilha, agora o SQL foi na página onde 
originalmente estava o registro e atualizou o valor da pág
e slot atual.

Slot 9 Offset 0x1eb2 Length 9
Record Type = FORWARDING_STUB        Record Attributes =                  Record Size = 9
Memory Dump @0x000000001064BEB2
0000000000000000:   0453d300 00010000 00†††††††††††††††††.SÓ......        
Forwarding to  =  file 1 page 54099 slot 0                               
*/
DBCC PAGE (NorthWind,1,54099,3)
/* 
  ProductID 10 lá esta ele. :-)
*/


/*
  Agora que já brincamos bastante com os forwarded records, 
  como resolver este tipo de fragmentação?
  
  A maneira mais simples seria criar um índice cluster na tabela
  e depois excluir o índice.
*/


-- Vamos ver quantos forwarded records temos na tabela
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'HeapProducts'), 0, NULL , 'DETAILED')
GO
CREATE CLUSTERED INDEX TempIndex ON HeapProducts (ProductID)
GO
DROP INDEX TempIndex ON HeapProducts
GO
-- Vamos ver quantos forwarded records temos na tabela
SELECT * FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(N'HeapProducts'), 0, NULL , 'DETAILED')
GO


-- Script para localizar todoas heaps do banco de dados
SELECT so.Name, si.rowcnt
  FROM sys.sysindexes si
 INNER JOIN sys.objects so
    ON si.id = so.object_id
 WHERE indid = 0
   AND so.type = 'U'
 ORDER BY 2 DESC
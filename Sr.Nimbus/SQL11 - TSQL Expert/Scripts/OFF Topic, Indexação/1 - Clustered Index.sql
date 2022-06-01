/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

-- Overview Índice --
/*
  Dados desordenados
  ?-----------------------?
  D  B  I  A  F  E  G  H  C

  SELECT * FROM Tab WHERE Letra = 'H'
  
  Varre a lista de valores procurando o 'H'
  Total de letras lidas será o total de letras
  existentes. Ou seja, 9.

  Dados ordenados
  ------------------------>
  A  B  C  D  E  F  G  H  I
  
  SELECT * FROM Tab WHERE Letra = 'H'
  
  Varre a lista de valores procurando o 'H'
  até achar a próxima ocorrência maior que 'H'
  Total de letras lidas = 9

  Dados Indexados (árvore b-tree)
  |-------------------------|
  |          | E |          |
  |-------------------------|
  |   | D |         | I |   |
  |-------------------------|
  ||A| |B| |C|   |F| |G| |H||
  |-------------------------|

  SELECT * FROM Tab WHERE Letra = 'H'
  
  Navega pela árvore balanceada procurando pelo 'H'
  Algoritmo de busca mais ou menos assim.
  
  Iniciando do nível raiz e faz a seguinte validação
  1 - 'H' é menor ou igual a 'E' ? Não.
  2 - 'H' é menor ou igual a 'I' ? Sim.
  3 - Lê o próximo valor ('F'). É igual a 'G'? Não.
  4 - Lê o próximo valor ('G'). É igual a 'G'? Sim.
  5 - Lê o próximo valor ('H'). É igual a 'G'? Não. Termina a leitura
  Total de letras lidas = 5
*/


/*
  Tab: ID, Nome, SobreNome, Idade...
  Montar estrutura de índice cluster e exemplificar como ler no índice um
  select * from tab
  
  select * from tab
  where id = 21
  
  select * from tab
  where nome = 'Jão' -- (Collate?)
  
  select id, nome from tab
  where nome = 'Jão'
  
  select id, nome from tab
  
  select id, nome, sobrenome from tab
  
  select id, nome from tab 
  where sobrenome = 'Souza'
  
  select id, nome, idade from tab 
  where sobrenome = 'Souza'
  
  E se eu apagar meu índice cluster? (RID)
  
  read ahead (comentar sobre Hit Ratio e Page life expenctancy)
  
*/

-- Analogia índice cluster --
/*
  Livro T-SQL Fundamentals (Itzik Ben-Gan)
  
  Quantos índices temos em um Livro?
  
  
  
  
  R: 3, o índice cluster do livro é o número das páginas
*/


/*
  Dados da tabela são ordenados na ordem da chave.
  Por isso quando efetuamos um select sem ORDER BY
  os dados vem na ordem da chave do índice
*/
SELECT * FROM Products
ORDER BY ProductID
/*
  Portanto, podemos dizer que o ORDER BY ProductID é 
  redundante? Pois se os dados já serão retornados na 
  ordem do índice não preciso de order by. Correto?
  
  
  
  
  R:Não. Pode me citar alguns exemplos onde a leitura 
  não será retornada na ordem esperada?
  
  R: NOLOCK, TABLOCK, READPAST, Advanced Scan, Parallelismo
  
  Nota: Você conhece todos os efeitos do uso do NoLock?
  Tem certeza?
  
  Repare que no plano de execução abaixo o SQL fez um 
  index scan e a propriedade Ordered do Clustered Index Scan
  é igual a True
*/

SELECT *
  FROM Products
 ORDER BY ProductID

-- Simulação leitura usando o índice cluster --

/*
  Consulta para ler o CustomerID = 80000
  Temos um índice cluster definido como primary key
  na coluna CustomerID, portanto o SQL consegue
  utilizar este índice para retornar os dados da consulta
*/
SET STATISTICS IO ON
SELECT *
  FROM CustomersBig
 WHERE CustomerID = 80000
SET STATISTICS IO OFF

/*
  Apenas 3 IOs, vamos verificar quais páginas foram lidas
  utilizando o DBCC PAGE
*/

-- Vamos identificar a página Root do índice xpk_CustomersBig
SELECT dbo.fn_HexaToDBCCPAGE(Root), * 
  FROM sys.sysindexes
 WHERE name = 'xpk_CustomersBig'

-- Usando a fn_HexaToDBCCPAGE para gerar o DBCC PAGE
SELECT dbo.fn_HexaToDBCCPAGE(0x0F0200000100)


-- Vamos navegar pelo índice a partir da página Raiz procurando pelo valor
-- CustomerID = 80000
DBCC TRACEON (3604)
DBCC PAGE (Northwind,1,19138,3)-- 1 Leitura
DBCC PAGE (Northwind,1,19137,3) -- 2 Leitura
DBCC PAGE (Northwind,1,22542,3) -- 3 Leitura Encontramos o CustomerID = 80000


-- E agora?
SET STATISTICS IO ON
SELECT *
  FROM CustomersBig
SET STATISTICS IO OFF


-- Uniquifier --
/*
  Quando a chave do índice Cluster não é única
  o SQL adiciona um ID sequencial chamado Uniquifier (4 bytes)
  na chave do cluster.
  
  sys.system_internals_partition_columns tem uma coluna is_unique
  sysindexes tem a keycnt
  
  Ex:
*/

-- Vamos apagar a Chave Primária da tabela de CustomersBig
-- ALTER TABLE OrdersBig DROP fk_OrdersBig_CustomersBig
ALTER TABLE CustomersBig DROP CONSTRAINT xpk_CustomersBig
GO

-- Agora vamos recriar o índice cluster mas não 
-- vamos definir como PK
CREATE CLUSTERED INDEX xpk_CustomersBig ON CustomersBig(CustomerID)
GO
/* 
  Agora conseguimos duplicar os valores da chave do cluster
  Vamos incluir outro cliente com ID 80000
  
  Pergunta, o CustomerID é um Identity
  
  Identity não é sempre único?
  
  
  
  
  
  R: Não.
*/
SET IDENTITY_INSERT CustomersBig ON
INSERT INTO CustomersBig (CustomerID, CompanyName, Col1, Col2)
VALUES (80000, 'Novo Alfreds', NEWID(), NEWID())
SET IDENTITY_INSERT CustomersBig OFF
GO

-- Vamos novamente identificar a página Root do índice xpk_CustomersBig
SELECT dbo.fn_HexaToDBCCPAGE(Root), * 
  FROM sys.sysindexes
 WHERE name = 'xpk_CustomersBig'

-- Usando a fn_HexaToDBCCPAGE para gerar o DBCC PAGE
SELECT dbo.fn_HexaToDBCCPAGE(0x804800000100)

-- Vamos navegar pelo índice a partir da página Raiz procurando pelo valor
-- CustomerID = 80000
DBCC TRACEON (3604)
DBCC PAGE (Northwind,1,2498,3)
DBCC PAGE (Northwind,1,2497,3)
-- Agora temos 2 registros com CustomerID = 80000, 
-- um com UNIQUIFIER = 0 e outro com UNIQUIFIER = 1
DBCC PAGE (Northwind,1,29587,3)

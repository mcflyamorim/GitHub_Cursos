/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
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



-- Analogia índice cluster --
/*
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

-- Modo correto, é sempre especificar o Order By
SELECT *
  FROM Products
 ORDER BY ProductID



/*
  Consulta para ler o CustomerID = 80000
  Temos um índice cluster definido como primary key
  na coluna CustomerID, portanto o SQL consegue
  utilizar este índice para retornar os dados da consulta
*/
SET STATISTICS IO ON
SELECT *
  FROM CustomersBig WITH(FORCESCAN) -- Hint para forçar o SCAN
 WHERE CustomerID = 80000
SET STATISTICS IO OFF

/*
  E utilizando o índice?
*/

SET STATISTICS IO ON
SELECT *
  FROM CustomersBig
 WHERE CustomerID = 80000
SET STATISTICS IO OFF
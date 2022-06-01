/*
  Sr.Nimbus - OnDemand
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
-- Insere dados na Heap
INSERT INTO HeapProducts WITH(TABLOCK)
SELECT ProductID, ProductName, NEWID() FROM ProductsBig
GO


-- Gera table scan na heap
SELECT * 
  FROM HeapProducts
 WHERE ProductName like 'Alice Mutton 000%'
GO

-- Criar índice para gerar seek
-- DROP INDEX ix1 ON HeapProducts
CREATE NONCLUSTERED INDEX ix1 ON HeapProducts(ProductName)

-- Gera Rid Lookup para ler os dados das colunas ProductID e Col1
-- Compute Scalar contém o ponteiro para a localização da linha na página (Arquivo/Página/Slot)
SELECT *
  FROM HeapProducts
 WHERE ProductName like 'Alice Mutton 000%'


-- Quantos IOs?
SET STATISTICS IO ON
SELECT *
  FROM HeapProducts
 WHERE ProductName = 'Alice Mutton 00021DC3'
SET STATISTICS IO OFF
-- 3 para navegar pelo índice não cluster e 1 para ler os dados na heap (lookup)

-- Vamos simular os IOs
-- DBCC IND para identificar o ID da página IAM
-- e a primeira página de dados
DBCC TRACEON (3604)
DBCC IND (NorthWind, HeapProducts, 1)
DBCC PAGE(NorthWind, 1, 442656, 3)
GO

-- Vamos identificar a página Root do índice ix1
SELECT dbo.fn_HexaToDBCCPAGE(Root)
  FROM sys.sysindexes
 WHERE name = 'ix1'
   AND id = OBJECT_ID('HeapProducts')

-- Vamos navegar pelo índice a partir da página Raiz procurando pelo valor ProductName = Alice Mutton 00021DC3
DBCC TRACEON (3604)
DBCC PAGE (Northwind,1,475506,3) -- 1 Leitura
DBCC PAGE (Northwind,1,475504,3) -- 2 Leitura
DBCC PAGE (Northwind,1,475440,3) -- 3 Leitura Encontramos ProductName = Alice Mutton 00021DC3
/* 
  Agora precisamos fazer o Lookup utilizando o RID na página HEAP, 
  antes precisamos converter o hexa que contem o RIP
  0x40C1060001000000
  0x40C1 0600 0100 0000
  0xC140 0006 0001 0000
  0x0006C140 0001 0000
  SELECT CONVERT(Int, 0x0001) -- Arquivo 1
  SELECT CONVERT(Int, 0x0000) -- Slot 0
  SELECT CONVERT(Int, 0x0006C140) -- Página 442688
*/
DBCC PAGE (Northwind,1,442688,3) -- 4 Leitura
/*
  Com a 4 leitura simulamos exatamente o que o SQL Server fez para ler o 
  registro na página.
*/

-- Script para localizar todoas heaps do banco de dados
SELECT so.Name, si.rowcnt
  FROM sys.sysindexes si
 INNER JOIN sys.objects so
    ON si.id = so.object_id
 WHERE indid = 0
   AND so.type = 'U'
 ORDER BY 2 DESC
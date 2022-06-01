/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE NorthWind
GO

/*
  Table scan e index scan
*/

-- Allocation order scan

IF OBJECT_ID('TabClientes') IS NOT NULL
  DROP TABLE TabClientes
GO
CREATE TABLE TabClientes (ID_Cliente Int, Nome VarChar(80) NOT NULL, Idade TinyInt, Col Char(3500) DEFAULT 'x')
GO
ALTER TABLE TabClientes ADD CONSTRAINT xpkTabClientes PRIMARY KEY(Nome)
GO
INSERT INTO TabClientes (ID_Cliente, Nome, Idade)
VALUES (1, 'Fabiano Amorim ', 28),
       (2, 'Luciano Caixeta', 38),
       (3, 'Gilberto Uchoa ', 42),
       (4, 'Ivan Lima      ', 19),
       (5, 'Fabricio Braz  ', 40)
GO
SELECT * FROM TabClientes
GO


-- Identificar IAM
SELECT dbo.fn_HexaToDBCCPAGE(FirstIAM)
  FROM sys.sysindexes
 WHERE id = OBJECT_ID('TabClientes')
GO

DBCC TRACEON(3604)
DBCC PAGE (Northwind,1,1697318,3) -- Consultar IAM
/*
  IAM: Single Page Allocations @0x000000000F97808E

  Slot 0 = (1:1553190) Slot 1 = (1:1697319) Slot 2 = (1:1697544)
  Slot 3 = (1:1697545) Slot 4 = (1:1697546) Slot 5 = (0:0)
  Slot 6 = (0:0)       Slot 7 = (0:0)       
*/

DBCC PAGE (Northwind,1,1697319,3) -- Ler dados de uma página qualquer


-- "Fingir" que a tabela tem mais que 64 páginas para gerar allocation order scan
/*
  Artigo do Itzik Ben-Gan:
  http://www.sqlmag.com/article/sql-server/quaere-verum-clustered-index-scans-part-iii
  Index order scans were used up to a table size of 64 pages;
  from this point and beyond allocation order scans were used
*/

--DBCC SHOW_STATISTICS (TabClientes) WITH STATS_STREAM
--UPDATE STATISTICS TabClientes WITH ROWCOUNT = 5, PAGECOUNT = 4

UPDATE STATISTICS TabClientes WITH ROWCOUNT = 5, PAGECOUNT = 64
GO

-- WITH(NoLock) faz a leitura via Allocation Order
-- Dados estão ordenados por [Physical RID], que é a ordem de alocação 
-- das páginas
SELECT *, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes WITH(NOLOCK)
GO

-- Comparando a diferença, sem nolock (index order scan)
-- Dados em ordem da PK (Nome)
SELECT *, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes
GO


SELECT ID_Cliente, Nome, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes WITH(NOLOCK)
GO
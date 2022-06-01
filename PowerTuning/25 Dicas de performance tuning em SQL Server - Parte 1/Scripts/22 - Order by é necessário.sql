USE NorthWind
GO

IF OBJECT_ID('TabClientes') IS NOT NULL
  DROP TABLE TabClientes
GO
CREATE TABLE TabClientes (ID_Cliente Int, Nome VarChar(80) NOT NULL, Idade TinyInt, Col Char(3500) DEFAULT 'x')
GO
ALTER TABLE TabClientes ADD CONSTRAINT xpkTabClientes PRIMARY KEY(Nome)
GO
INSERT INTO TabClientes (ID_Cliente, Nome, Idade)
VALUES (1, 'Fabiano', 28),
       (2, 'Bruno', 38),
       (3, 'Carlos', 42),
       (4, 'Dinho', 19),
       (5, 'Alberto', 40)
GO

-- Ler dados da tabela e ver localização física do registro
SELECT *, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes WITH(NOLOCK)
GO


-- "Fingir" que a tabela tem mais que 64 páginas para gerar allocation order scan
/*
  Artigo do Itzik Ben-Gan:
  http://www.sqlmag.com/article/sql-server/quaere-verum-clustered-index-scans-part-iii
  Index order scans were used up to a table size of 64 pages;
  from this point and beyond allocation order scans were used
*/


-- DBCC UPDATEUSAGE (Northwind,'TabClientes') WITH COUNT_ROWS;
UPDATE STATISTICS TabClientes WITH ROWCOUNT = 5, PAGECOUNT = 64
GO


-- Index order scan
SELECT ID_Cliente, Nome, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes
GO

-- Allocation order scan
SELECT ID_Cliente, Nome, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes WITH(NOLOCK)
GO

-- Allocation order scan
-- Se quiser na ordem... coloca o order by, obrigado.
SELECT ID_Cliente, Nome, 
       sys.fn_PhysLocFormatter (%%physloc%%) AS [Physical RID]
  FROM TabClientes WITH(NOLOCK)
ORDER BY Nome
GO
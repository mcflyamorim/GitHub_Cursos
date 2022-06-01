USE Northwind
GO

-- 10 segundos para rodar...
IF OBJECT_ID('dbo.TabelaVARMAX', 'U') IS NOT NULL
	 DROP TABLE dbo.TabelaVARMAX
GO

CREATE TABLE dbo.TabelaVARMAX (
	ID INT IDENTITY NOT NULL CONSTRAINT PK_TabelaVARMAX PRIMARY KEY
	, Nome VARCHAR(100) NOT NULL DEFAULT NEWID()
	, DataRegistro DATETIME2 NOT NULL DEFAULT(SYSDATETIME())
	, Texto VARCHAR(MAX) NOT NULL DEFAULT (REPLICATE('A', 4000)) -- Preencher tabela com 4000 caracteres...
)
GO
CREATE INDEX ixNome ON TabelaVARMAX(Nome) INCLUDE(Texto)
GO

BEGIN TRAN
GO
INSERT INTO dbo.TabelaVARMAX DEFAULT VALUES
GO 10000
COMMIT
GO


-- Quantas páginas lidas no range scan?
SET STATISTICS IO ON
SELECT ID, Nome 
  FROM TabelaVARMAX
 WHERE Nome LIKE 'F%'
SET STATISTICS IO OFF
GO
-- Scan count 1, logical reads 617



-- Ativa a opção de armazenamento de dados LOB fora das páginas de dados
EXEC sp_tableoption 'TabelaVARMAX', 'large value types out of row', 1
GO

UPDATE TabelaVARMAX SET Texto = Texto
GO

-- Recria o índice – reorganiza as páginas pra jogar dados LOB para fora da pag.
ALTER INDEX ixNome ON dbo.TabelaVARMAX REBUILD
GO


-- Quantas páginas lidas no range scan?
SET STATISTICS IO ON
SELECT ID, Nome 
  FROM TabelaVARMAX
 WHERE Nome LIKE 'F%'
SET STATISTICS IO OFF
GO

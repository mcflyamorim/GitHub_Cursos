USE Northwind
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 100000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2,
       'F' AS Status
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
UPDATE TOP (10) CustomersBig SET Status = 'A'
GO

ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO


-- Seleciona todos os clientes com Status Aberto ('A')
SELECT * FROM CustomersBig
WHERE Status = 'A'
GO


-- Criando índice Normal
CREATE INDEX ixStatusNormal ON CustomersBig (Status) INCLUDE(CompanyName, ContactName, Col1, Col2)
GO
-- Criando índice filtrado
CREATE INDEX ixStatusFiltrado ON CustomersBig (Status) INCLUDE(CompanyName, ContactName, Col1, Col2)
 WHERE Status = 'A'
GO


-- Índice ridiculamente pequeno...
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
 WHERE p.Object_Id = Object_Id('CustomersBig')


-- Seleciona todos os clientes com Status Aberto ('A')
SELECT * FROM CustomersBig
WHERE Status = 'A'
GO


/*
  Filtered Index em Procedures
*/

DROP PROC IF EXISTS st_TestFilteredIndex 
GO
CREATE PROC st_TestFilteredIndex @Var CHAR(1)
AS
BEGIN
  SELECT * FROM CustomersBig
  WHERE Status = @Var
END
GO

-- SQL não usa o índice porque o filtro é um parâmetro
EXEC st_TestFilteredIndex @Var = 'A'

-- Alternativa 1: Reescrever a proc com option recompile
DROP PROC IF EXISTS st_TestFilteredIndex 
GO
CREATE PROC st_TestFilteredIndex @Var CHAR(1)
AS
BEGIN
  SELECT * FROM CustomersBig
  WHERE Status = @Var
  OPTION (RECOMPILE)
END
GO

EXEC st_TestFilteredIndex @Var = 'A'
GO

-- Alternativa 2: Reescrever a proc com o filtro fixo
DROP PROC IF EXISTS st_TestFilteredIndex 
GO
CREATE PROC st_TestFilteredIndex @Var CHAR(1)
AS
BEGIN
  IF @Var = 'A'
  BEGIN
    SELECT * FROM CustomersBig
    WHERE Status = @Var
      AND Status = 'A'
  END
  ELSE
  BEGIN
    SELECT * FROM CustomersBig
    WHERE Status = @Var
  END
END
GO

-- Visualizar plano estimado (CTRL+L)
EXEC st_TestFilteredIndex @Var = 'A'

/*
  Plano que será incluído em cache contém o acesso a tabela 
  utilizando os dois índices
*/
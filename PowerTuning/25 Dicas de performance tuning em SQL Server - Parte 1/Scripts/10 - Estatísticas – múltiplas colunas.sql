USE Northwind
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 10000
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       CONVERT(CHAR(2000),SubString(CONVERT(VarChar(250),NEWID()),1,8)) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO
ALTER TABLE CustomersBig ADD Ativo Char(1)
ALTER TABLE CustomersBig ADD Estado_Civil VarChar(200)
GO
UPDATE CustomersBig SET Ativo = NULL, Estado_Civil = NULL
GO
UPDATE TOP (50) PERCENT CustomersBig SET Ativo = 'S', Estado_Civil = 'Casado'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
GO
UPDATE TOP (2500) CustomersBig SET Ativo = 'N', Estado_Civil = 'Casado'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
GO
UPDATE TOP (2500) CustomersBig SET Ativo = 'S', Estado_Civil = 'Solteiro'
 WHERE Ativo IS NULL 
   AND Estado_Civil IS NULL
GO
UPDATE STATISTICS CustomersBig WITH FULLSCAN
GO


-- Plano com estimativa incorreta por causa do filtro em 
-- Ativo e Estado_Civil
SELECT CustomersBig.CompanyName, COUNT_BIG(*) AS Qtde
  FROM CustomersBig
 WHERE CustomersBig.Ativo = 'N'
   AND CustomersBig.Estado_Civil = 'Casado'
 GROUP BY CustomersBig.CompanyName
 ORDER BY CustomersBig.CompanyName
OPTION (RECOMPILE)
GO


-- Criando estatística nas colunas para ajudar a estimativa
-- DROP STATISTICS CustomersBig.Stats1
CREATE STATISTICS Stats1 ON CustomersBig(Ativo, Estado_Civil) WITH FULLSCAN
GO

-- Plano com estimativa correta
SELECT CustomersBig.CompanyName, COUNT_BIG(*) AS Qtde
  FROM CustomersBig
 WHERE CustomersBig.Ativo = 'N'
   AND CustomersBig.Estado_Civil = 'Casado'
 GROUP BY CustomersBig.CompanyName
 ORDER BY CustomersBig.CompanyName
OPTION (RECOMPILE)
GO


-- Se o SQL errar na estimativa varios problemas podem ocorrer:

-- Falta de memoria (memory grant)
-- Algoritmos de join errado
-- Ordem de acesso as tabelas errado
-- ...
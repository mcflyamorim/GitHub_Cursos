USE Northwind
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
BEGIN
--  ALTER TABLE [dbo].[OrdersBig] DROP CONSTRAINT [fk_OrdersBig_CustomersBig]
  DROP TABLE CustomersBig
END
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       ISNULL((ABS(CHECKSUM(NEWID())) % (1-60)) + 1, 0) AS CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName,
       CONVERT(VARCHAR(200), LOWER(SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8)) + '@gmail.com') AS Email,
       CONVERT(VARCHAR(20), 'M') AS Gender,
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
INSERT INTO CustomersBig WITH(TABLOCK)
(
    CityID,
    CompanyName,
    ContactName,
    Email,
    Gender,
    Col1,
    Col2
)
SELECT TOP 1000000
       (ABS(CHECKSUM(NEWID())) % (1-60)) + 1 AS CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName,
       CONVERT(VARCHAR(200), LOWER(SUBSTRING(CONVERT(VarChar(250),NEWID()),1,8)) + '@gmail.com') AS Email,
       CONVERT(VARCHAR(20), 'F') AS Gender,
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
INSERT INTO CustomersBig WITH(TABLOCK)
(
    CityID,
    CompanyName,
    ContactName,
    Email,
    Gender,
    Col1,
    Col2
)
VALUES(8, 'Emp1', 'Fabiano', 'fabianonevesamorim@hotmail.com', 'M', '', '')
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
ALTER TABLE CustomersBig ADD CONSTRAINT fkCityID FOREIGN KEY (CityID) REFERENCES Cities(CityID)
GO

CREATE INDEX ixGender_Email ON CustomersBig(Gender, Email)
GO

-- Faz scan no índice ixGender_Email
SET STATISTICS IO ON
SELECT CustomerID, Gender, Email 
  FROM CustomersBig
 WHERE Email = 'fabianonevesamorim@hotmail.com'
SET STATISTICS IO OFF
GO
-- Table 'CustomersBig'. Scan count 21, logical reads 8891, physical reads 0


-- A ideia é aproveitar a ordem de uma b-tree e evitar ler linhas desnecessárias... 

-- No índice temos algo mais ou menos assim:
/*
  Gender   Email
  -------- -----------------------
  F        email1@gmail.com
  F        email2@gmail.com
  F        email3@gmail.com
  F        email4@gmail.com
  F        email5@gmail.com
  M        email6@gmail.com
  M        email7@gmail.com
  M        email8@gmail.com
*/

-- Se a densidade da coluna Gender for alta, ou seja, 
-- tem poucos valores distintos, o SQL poderia fazer várias queries
-- usando também os valores de Gender como filtro.
-- Teriamos algo parecido com o seguinte:

SET STATISTICS IO ON
SELECT CustomerID, Gender, Email FROM CustomersBig
WHERE Gender = 'F' AND Email = 'fabianonevesamorim@hotmail.com'
UNION ALL
SELECT CustomerID, Gender, Email FROM CustomersBig
WHERE Gender = 'M' AND Email = 'fabianonevesamorim@hotmail.com'
SET STATISTICS IO OFF
-- Table 'CustomersBig'. Scan count 2, logical reads 6

-- O Oracle faz isso...
-- Otimização chamada "Index Skips Scans" https://docs.oracle.com/database/121/TGSQL/tgsql_optop.htm#TGSQL95180


-- Vamos fazer na mão via cursor pra ver como fica.


-- Vamos começar pegando os valores distintos de Gender utilizando
-- o truque da Dica 153
DECLARE cCursor CURSOR FAST_FORWARD FOR 
WITH CTE_1 AS
(
    -- Anchor
    SELECT TOP 1
           Gender
      FROM CustomersBig
     ORDER BY Gender ASC
     UNION ALL
    -- Recursive
    SELECT tmp1.Gender
    FROM
    (
        SELECT 
            c1.Gender,
            rn = ROW_NUMBER() OVER (ORDER BY c1.Gender ASC)
         FROM CTE_1
        INNER JOIN CustomersBig AS c1
           ON c1.Gender > CTE_1.Gender
    ) AS tmp1
    WHERE tmp1.rn = 1
)
SELECT CTE_1.Gender
  FROM CTE_1
OPTION (MAXRECURSION 0);

-- Criando tabela pra receber os resultados das queries por Gender e Email
DECLARE @Tmp TABLE (CustomerID INT, Gender VARCHAR(20), Email VARCHAR(200))

-- Pra cada valor distinto de Gender, vamos fazer a query na CustomersBig
-- passando Gender como filtro
DECLARE @Gender VARCHAR(20)
   OPEN cCursor
  FETCH NEXT FROM cCursor INTO @Gender

WHILE @@FETCH_STATUS = 0
BEGIN
  INSERT INTO @Tmp (CustomerID, Gender, Email)
  SELECT CustomerID, Gender, Email FROM CustomersBig
   WHERE Gender = @Gender AND Email = 'fabianonevesamorim@hotmail.com'

  FETCH NEXT FROM cCursor INTO @Gender
END

CLOSE cCursor
DEALLOCATE cCursor

SELECT * FROM @Tmp
GO


-- Outra alternativa, é fazer um join... Por ex:
;WITH CTE_1 AS
(
    -- Anchor
    SELECT TOP 1
           Gender
      FROM CustomersBig
     ORDER BY Gender ASC
     UNION ALL
    -- Recursive
    SELECT tmp1.Gender
    FROM
    (
        SELECT 
            c1.Gender,
            rn = ROW_NUMBER() OVER (ORDER BY c1.Gender ASC)
         FROM CTE_1
        INNER JOIN CustomersBig AS c1
           ON c1.Gender > CTE_1.Gender
    ) AS tmp1
    WHERE tmp1.rn = 1
)
SELECT CustomersBig.CustomerID, CustomersBig.Gender, CustomersBig.Email
  FROM CTE_1
 INNER JOIN CustomersBig
    ON CTE_1.Gender = CustomersBig.Gender
 WHERE Email = 'fabianonevesamorim@hotmail.com'
OPTION (MAXRECURSION 0);
GO

-- Outro exemplo parecido...

-- Digamos que eu tenha um índice por CityID pra cobrir a foreign key
CREATE INDEX ixCityID ON CustomersBig(CityID)
GO

-- Considerando essa query que faz um Scan... 
-- Eu poderia ajustar o índice de CityID pra me ajudar... Certo? 
SELECT CustomerID, Email 
  FROM CustomersBig
 WHERE Email = 'fabianonevesamorim@hotmail.com'
GO

-- A solução simples, seria criar outro índice por Email, é claro... 
-- Mas digamos que por algum motivo (custo do índice?) isso não é possível

-- Mas e se eu ajustar o índice já existente pra incluir e-mail como chave? Ajuda?
DROP INDEX IF EXISTS ixCityID ON CustomersBig
CREATE INDEX ixCityID ON CustomersBig(CityID, Email)
GO

-- Ainda não ajudou...
SELECT CustomerID, Email 
  FROM CustomersBig
 WHERE Email = 'fabianonevesamorim@hotmail.com'
GO


-- Mas e se eu incluir o Join com a Cities pra "forçar" o uso do índice?
-- A ideia é ler as linhas de Cities, e pra cada linha, fazer um Seek em 
-- CustomersBig usando CityID + Email como Seek Predicate, sucesso...
SELECT CustomerID, Email 
  FROM CustomersBig
 INNER JOIN Cities
    ON Cities.CityID = CustomersBig.CityID
 WHERE Email = 'fabianonevesamorim@hotmail.com'
GO
-- Eita, foreign key elimination (dica 130) me atrapalhou...



-- Atrapalhando o join um pouco com o +0, porém sem alterar o resultado :-)
-- Qual query é mais rápida?
SET STATISTICS IO, TIME ON
SELECT CustomerID, Email 
  FROM CustomersBig
 INNER JOIN Cities
    ON Cities.CityID + 0 = CustomersBig.CityID
 WHERE Email = 'fabianonevesamorim@hotmail.com'
/*
  Table 'CustomersBig'. Scan count 69, logical reads 246, physical reads 0
  Table 'Cities'. Scan count 1, logical reads 3, physical reads 0

  SQL Server Execution Times:
     CPU time = 0 ms,  elapsed time = 0 ms.
*/

SELECT CustomerID, Email 
  FROM CustomersBig
 WHERE Email = 'fabianonevesamorim@hotmail.com'
/*
  Table 'CustomersBig'. Scan count 21, logical reads 8890, physical reads 0

  SQL Server Execution Times:
     CPU time = 80 ms,  elapsed time = 17 ms.
*/
SET STATISTICS IO, TIME OFF
GO


/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

IF OBJECT_ID('Consumer') IS NOT NULL
  DROP TABLE Consumer
GO

SELECT TOP 100000
       IDENTITY(INT, 1,1) AS Id, 
       CONVERT(VARCHAR(MAX), REPLICATE('ASD', 5)) AS Col1, 
       CONVERT(VARCHAR(MAX), REPLICATE('ASD', 5)) AS Col2,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS Dt
  INTO Consumer
  FROM dbo.Customers A
 CROSS JOIN dbo.Customers B
 CROSS JOIN dbo.Customers C
 CROSS JOIN dbo.Customers D
GO
ALTER TABLE Consumer ADD CONSTRAINT xpk_Consumer PRIMARY KEY(Id)
GO

IF OBJECT_ID('CreditProfile') IS NOT NULL
  DROP TABLE CreditProfile
GO

SELECT TOP 100000
       IDENTITY(INT, 1,1) AS Id, 
       ABS(CheckSUM(NEWID()) / 1000000) AS ConsumerId,
       CONVERT(VARCHAR(MAX), REPLICATE('ASD', 5)) AS Col1, 
       CONVERT(VARCHAR(MAX), REPLICATE('ASD', 5)) AS Col2
  INTO CreditProfile
  FROM (SELECT TOP 100000000 * FROM dbo.Consumer ORDER BY 1 ASC) A
GO
;WITH CTE_1
AS
(
  SELECT *, ROW_NUMBER() OVER(PARTITION BY ConsumerId ORDER BY Id) AS rn
  FROM CreditProfile
)
DELETE FROM CTE_1
WHERE rn > 1
GO
ALTER TABLE CreditProfile ADD CONSTRAINT xpk_CreditProfile  PRIMARY KEY NONCLUSTERED(Id)
GO
CREATE CLUSTERED INDEX ixConsumerId ON CreditProfile(ConsumerId)
GO

IF OBJECT_ID('CreditProfileState') IS NOT NULL
  DROP TABLE CreditProfileState
GO
SELECT TOP 1 
       IDENTITY(INT, 1, 1) AS Id, 
       CONVERT(INT, CreditProfile.Id) AS CreditProfileId, 
       CONVERT(VARCHAR(400), NEWID()) AS CreditStateType,
       CONVERT(VARCHAR(400), NEWID()) AS ReasonCode,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS DtCreditProfileState
  INTO CreditProfileState
  FROM CreditProfile
GO
INSERT INTO CreditProfileState WITH(TABLOCK)
SELECT CreditProfile.Id AS CreditProfileId, 
       CONVERT(VARCHAR(400), NEWID()) AS CreditStateType,
       CONVERT(VARCHAR(400), NEWID()) AS ReasonCode,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS DtCreditProfileState
  FROM CreditProfile
GO 500
ALTER TABLE CreditProfileState ADD CONSTRAINT xpk_CreditProfileState PRIMARY KEY(Id)
GO
DROP INDEX IF EXISTS ixCreditProfileId ON CreditProfileState
GO
CREATE INDEX ixCreditProfileId ON CreditProfileState (CreditProfileId, Id) INCLUDE(CreditStateType, ReasonCode, DtCreditProfileState)
GO

SET STATISTICS IO ON
GO

SELECT c.Id, cps.CreditProfileId, cps.CreditStateType, cps.ReasonCode, cps.DtCreditProfileState
  FROM Consumer c
 INNER JOIN CreditProfile cp
    ON cp.ConsumerId = c.Id
 INNER JOIN (SELECT CreditProfileId,
                    MAX(Id) as MaxId
               FROM CreditProfileState
              GROUP BY CreditProfileId) mcps
    ON mcps.CreditProfileId = cp.Id
 INNER JOIN CreditProfileState cps
    ON cps.Id=mcps.MaxId
 WHERE c.Dt >= '20200101'
ORDER BY c.Id ASC
GO

-- Vamos pegar um consumer de como exemplo
SELECT * FROM Consumer
WHERE Dt >= '20200101'
GO

-- Join com a tabela CreditProfile pra achar os 
-- valores para ConsumerId 20 (que estamos usando como amostra)
SELECT * FROM CreditProfile
WHERE ConsumerId = 20
GO

-- Join com CreditProfileState pra achar os
-- valores para Id 1188 que encontramos na CreditProfile
-- Um determinado CreditProfile pode ter N CreditProfileState
SELECT * FROM CreditProfileState
WHERE CreditProfileId = 1188
ORDER BY Id DESC
GO

-- Na SubQuery ficou assim:
SELECT * FROM (SELECT CreditProfileId,
                      MAX(Id) as MaxId
                FROM CreditProfileState
               GROUP BY CreditProfileId) AS Tab1
WHERE CreditProfileId = 1188
GO

-- Query precisa ler as colunas de CreditProfileState, 
-- porém apenas para o último (max de Id) registro 
SELECT * FROM CreditProfileState
WHERE id = 1072781
GO


-- E se a gente trocar o MAX+NovoJoin por um TOP1+order by ?
SELECT c.Id, cps.CreditProfileId, cps.CreditStateType, cps.ReasonCode, cps.DtCreditProfileState
  FROM Consumer c
 INNER JOIN CreditProfile cp
    ON cp.ConsumerId = c.Id
 CROSS APPLY (SELECT TOP 1 Id AS MaxId, CreditProfileId, CreditStateType, ReasonCode, DtCreditProfileState
                FROM CreditProfileState
               WHERE CreditProfileState.CreditProfileId = cp.Id
               ORDER BY Id DESC) AS cps
 WHERE c.Dt >= '20200101'
ORDER BY c.Id
GO

SET STATISTICS IO OFF
GO
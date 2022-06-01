USE Northwind
GO

/*
  Check Constraints
*/
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1(ID INTEGER, Sexo CHAR(1)) 
GO 
ALTER TABLE Tab1 ADD CONSTRAINT ck_Sexo_M_F CHECK(Sexo IN('M','F')) 
GO

-- Ué, porque não identificou que tem a Check Constraint???? ... 
SELECT * FROM Tab1
WHERE Sexo = 'J'
GO

-- E agora?
SELECT * FROM Tab1
WHERE Sexo = 'J'
AND 1=1
GO



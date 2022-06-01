USE Northwind
GO

CREATE TABLE #Teste (ID Int Identity(1,1) Primary Key, 
                     Numero VarChar(200)) 
GO

INSERT INTO #Teste VALUES('$55.69') 
INSERT INTO #Teste VALUES('1.4e35') 
INSERT INTO #Teste VALUES('2d4') 
INSERT INTO #Teste VALUES('3.7') 
INSERT INTO #Teste VALUES('412') 
INSERT INTO #Teste VALUES('0e2155') 
INSERT INTO #Teste VALUES(CHAR(9)) --Tab 
GO 

SELECT * FROM #Teste 

-- Cuidado ao usar IsNumeric com colunas VarChar 
SELECT ISNUMERIC(Numero) [Numeric ?], 
       ISNUMERIC(Numero + 'e0') AS [Numeric], Numero AS Valor 
FROM #Teste 
GO 

-- Criei uma função chamada IsNumber que valida o valor utilizando o 'e0' 
CREATE FUNCTION dbo.IsNumber(@Value VarChar(200)) 
RETURNS BIT 
AS 
BEGIN 
  RETURN (SELECT IsNumeric(@Value + 'e0')) 
END 
GO 
--Ex de uso da função 

SELECT dbo.IsNumber(Numero) AS [Numeric], Numero AS Valor 
FROM #Teste
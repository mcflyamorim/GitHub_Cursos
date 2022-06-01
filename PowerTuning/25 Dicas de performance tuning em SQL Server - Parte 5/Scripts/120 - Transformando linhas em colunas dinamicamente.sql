USE Northwind
GO

IF OBJECT_ID('TabDynamicPivot') IS NOT NULL
  DROP TABLE TabDynamicPivot
GO
CREATE TABLE TabDynamicPivot
(
	Prova VARCHAR(255),
	NomeAluno VARCHAR(255),
	Nota INT
)
GO

INSERT INTO TabDynamicPivot
	Values('Prova1', 'João', 7)
INSERT INTO TabDynamicPivot
	Values('Prova1', 'Fabiano Amorim', 8)
INSERT INTO TabDynamicPivot
	Values('Prova1', 'Felipe Amorim', 7)
INSERT INTO TabDynamicPivot
	Values('Prova2', 'João', 5)
INSERT INTO TabDynamicPivot
	Values('Prova2', 'Felipe Amorim', 6)
INSERT INTO TabDynamicPivot
	Values('Prova3', 'Fabiano Amorim', 4)
GO

SELECT * 
  FROM TabDynamicPivot

-- Static Pivot
;WITH PivotData AS
(
  SELECT Prova,
		       NomeAluno,
		       Nota
    FROM TabDynamicPivot
)
SELECT NomeAluno, 
	      Prova1, 
	      Prova2, 
	      Prova3
FROM TabDynamicPivot
PIVOT (	SUM(Nota)
	       FOR Prova IN (Prova1, Prova2, Prova3)
      ) AS PivotResult
ORDER BY NomeAluno
GO

-- Dynamic pivot
DECLARE @SQL as VARCHAR(MAX)
DECLARE @Columns AS VARCHAR(MAX)

SELECT @Columns = COALESCE(@Columns + ', ','') + QUOTENAME(Prova)
FROM
(
    SELECT DISTINCT Prova
     	FROM TabDynamicPivot
) AS B
ORDER BY B.Prova

SET @SQL = '
;WITH PivotData AS
(
  SELECT Prova,
		       NomeAluno,
		       Nota
    FROM TabDynamicPivot
)
SELECT NomeAluno, '
       + @Columns + ' 
FROM TabDynamicPivot
PIVOT (	SUM(Nota)
	       FOR Prova IN ('+ @Columns + ')
      ) AS PivotResult
ORDER BY NomeAluno'

EXEC (@SQL)
GO

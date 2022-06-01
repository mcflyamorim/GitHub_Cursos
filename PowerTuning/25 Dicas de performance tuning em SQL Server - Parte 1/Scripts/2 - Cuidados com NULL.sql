USE Northwind
GO

CREATE TABLE T1(col1 INT);
CREATE TABLE T2(col1 INT);
GO

INSERT INTO T1(col1) VALUES(1);
INSERT INTO T1(col1) VALUES(2);
INSERT INTO T1(col1) VALUES(NULL);
GO
INSERT INTO T2(col1) VALUES(2);
INSERT INTO T2(col1) VALUES(3);
GO

SET ANSI_NULLS OFF
-- Qual é o resultado ?
SELECT COUNT(*) FROM T1
WHERE Col1 = NULL
GO

SET ANSI_NULLS ON
-- Qual é o resultado ?
SELECT  COUNT(*) FROM T1
WHERE Col1 = NULL
GO

-- Qual é o resultado?
SELECT 2 + NULL
GO

-- Qual é o resultado?
SELECT COUNT(Col1)
  FROM T1
GO

-- Qual é o resultado?
SELECT *
  FROM T1
 WHERE Col1 <> 1
GO

-- Qual é o resultado?
SELECT TOP 1 *
  FROM T1
 ORDER BY Col1 ASC
GO

-- Qual é o resultado ? Col1 = 3 ?
SELECT col1
  FROM T2
 WHERE Col1 NOT IN(SELECT col1 FROM T1);





-- Maneira segura
SELECT col1
  FROM T2
 WHERE NOT EXISTS(SELECT 1 FROM T1 WHERE T1.col1 = T2.Col1);
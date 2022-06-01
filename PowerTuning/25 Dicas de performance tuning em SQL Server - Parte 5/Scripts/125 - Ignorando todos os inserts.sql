USE Northwind
GO

-- Cliente tem uma tabela de LOG que ele não usa mais... mas vai demorar 6 meses pra mudar a aplicação...

-- INSTEAD OF TRIGGER

IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID   INT NOT NULL PRIMARY KEY,
                 Col1 VarChar(10) NOT NULL,
                 Col3 INT IDENTITY(1,1))
GO

IF OBJECT_ID('tr_InsertT1') IS NOT NULL
	DROP TRIGGER tr_InsertT1
GO
CREATE TRIGGER tr_InsertT1 ON T1
INSTEAD OF INSERT
AS
BEGIN
	 PRINT 'Não insere nada...'
END
GO

-- O que vai acontecer??
INSERT INTO T1(ID, Col1) VALUES (100, 'a')
GO
SELECT * FROM T1
GO


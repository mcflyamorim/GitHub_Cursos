/*
  Treinamento de SQL Server - Isolations Levels
*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

BEGIN TRAN

UPDATE Teste SET Nome = 'Fabiano Amorim'
WHERE ID = 1

SELECT @@TranCount

INSERT INTO Teste Values('Eduardo')

SELECT * FROM Teste

DELETE FROM Teste
WHERE Nome = 'Eduardo'

UPDATE Teste SET Nome = 'Coragem Amorim'
WHERE ID = 2

SP_Lock @@SPID

SELECT Object_Name(352576890)

ROLLBACK TRAN

COMMIT TRAN
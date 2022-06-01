-- O Isolation Level padrão para novas transações do SQL Server é o READ COMMITTED

use Treinamento
GO
DBCC USEROPTIONS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

DROP TABLE Teste
CREATE TABLE Teste (ID Int Identity(1,1) Primary Key, 
                    Nome VarChar(80))

INSERT INTO Teste Values('Fabiano')
INSERT INTO Teste Values('Coragem') -- Nome cachorro
INSERT INTO Teste Values('Silvio')

SELECT * FROM Teste

-- 1 - Abir o arquivo READ COMMITTED 1 e efetuar um update na tabela Teste

-- 2 - Efetuar o select na tabela Teste, verificar que o SQL Gera um block pois a tabela está com lock
-- exclusivo pela transação que está efetuando o UPDATE
-- Abrir outra sessão e mostrar o uso do SP_Who2/sys.dm_exec_connections para ver por qual sessão estamos sendo bloqueados
-- mostrar o uso do DBCC InputBuffer/sys.dm_exec_sql_text para ver o ultimo comando SQL executado por uma determinada sessão.

SELECT * FROM Teste

-- Efetuar consulta para verificar outro registro que não está bloqueado pelo UPDATE(ID = 2)
SELECT * FROM Teste
WHERE ID = 2

-- Exemplo de como ler dados não comitados sem o uso de READ UNCOMMITTED
SELECT * FROM Teste WITH(NOLOCK)

-- 3 - Alterar o ISOLATION LEVEL para READ UNCOMMITTED

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
DBCC USEROPTIONS

-- 4 - Verificar os dados da tabela Teste
 
-- 5 - Efetuar um rollback no UPDATE para mostrar que o READ UNCOMMITTED pode exibir dados Sujos.
-- pois o UPDATE não foi comitado no banco de dados.

-- 6 - Alterar o ISOLATION LEVEL para READ COMMITTED para exibir um efeito de leitura não Repetida
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- 7 - Efetuar select na tabela teste e Verificar os registros para poder comparar com o outro select depois.
BEGIN TRAN

SELECT * FROM Teste
GO
WAITFOR DELAY '00:00:25'
-- 8 - Abrir outra sessão e Efetuar UPDATE e COMMIT na tabela Teste pela outra transação 
-- aberta e fazer select na tabela teste novamente
SELECT * FROM Teste

--SELECT @@TranCount
ROLLBACK TRAN

---------------------------------------------------------------------------

-- 9 - Alterar o ISOLATION LEVEL para REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

DBCC USEROPTIONS
BEGIN TRAN

SELECT @@TranCount

SELECT * FROM Teste
-- 10 - Verificar com SP_Lock que a tabela Teste está em lock Compartilhado(S), 
-- quando o registro está em lock compartilhado outras transações podem ler está informação
-- porem não podem alterar os dados enquanto a tabela estiver em lock
SP_Lock @@SPID

-- 11 - Abrir a outra sessão e tentar efetuar um UPDATE na tabela teste.
-- o Update não vai funcionar porque a tabela está em Lock compartilhado devido ao meu Isolation Level.
ROLLBACK TRAN

BEGIN TRAN

SELECT * FROM Teste
GO
WAITFOR DELAY '00:00:25'
-- 12 - Abrir outra sessão e incluir um registro na tabela teste.
-- Podemos verificar que utilizando o REPEATABLE READ evitamos o problema de leitura 
-- não repetida porem podem aparecer o que chamamos de dados Fantasmas, pois na
-- primeira leitura o registro não existia e agora já existe, para evitar este problema podemos utilizar 
-- o isolation level SERIALIZABLE
SELECT * FROM Teste
ROLLBACK TRAN

-- 13 - Voltar o isolation level para o nivel padrão SQL Server que é o READ COMMITTED
-- para poder exibir o uso do HINT XLock, TabLock
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- 14 - Iniciar uma transação e executar um select na tabela teste usando os Hints XLock, TabLock
BEGIN TRAN

SELECT * FROM Teste WITH(xLock, TabLock)
-- Falar sobre o PagLock, RowLock e ReadPast(Lê apenas os registros comitados pulandos os não comitados)

-- 15 - Verifique que o SQL gerou um Lock Exclusivo na tabela Teste, 
SP_Lock @@SPID
-- 16 - Ao abrir outra sessão e tentar efetuar um UPDATE, INSERT, DELETE e SELECT
-- veremos que não é possivel efetuar nenhuma destas operações pois a tabela está em LOCK Exclusivo(X)

ROLLBACK TRAN

-- 16 - Alterar o isolation level para o SERIALIZABLE
-- para poder vermos como evitar fantasmas, uso parecido com o xLock TabLock que acabamos de ver
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
DBCC USEROPTIONS

BEGIN TRAN

-- 17 - Efetuar um select na tabela teste.
SELECT * FROM Teste

-- 18 - Verificar que o SQL gerou um Lock de um range dos dados lidos para evitar
-- que alteraçõs na tabela afim de previnir dados Sujos, Leituras não Repetidas ou Fantasmas.
SP_Lock @@SPID

-- 19 - Ao abrir outra sessão e tentar efetuar um UPDATE, INSERT, DELETE e SELECT
ROLLBACK TRAN

-- 20 - Abrir outra transação efetuar um select na tabela teste limitando as colunas e 
-- verificar que o SQL gerou um lock apenas no range que foi lido.
BEGIN TRAN

SELECT * FROM Teste
WHERE ID BETWEEN 1 AND 2

SP_Lock @@SPID

-- 21 - Abrir outra sessão e efetuar um UPDATE na tabela teste onde o ID seja igual a 2
-- podemos observar que não foi gerado lock neste registro pois o UPDATE roda normalmente
-- porem ao tentar efetuar um UPDATE no registro 1 o SQL fica esperando o 
-- registro ser liberado do LOCK.

ROLLBACK TRAN


/* Tabela de Isolation Levels
 -------------------------------------------------------------------------
|                 |"Registros Sujos" |"Leitura não Repetida" | "Fantasmas"|
|READ UNCOMMITED  | Sim              | Sim                   |  Sim       |
|READ COMMITED    | Não              | Sim                   |  Sim       |
|REPEATABLE READ  | Não              | Não                   |  Sim       |
|SERIALIZABLE     | Não              | Não                   |  Não       |
 -------------------------------------------------------------------------
*/
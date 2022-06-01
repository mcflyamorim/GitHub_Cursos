/*
  Posso habilitar RCSI tranquilo né? ... 
*/

USE Northwind
GO

ALTER DATABASE Northwind SET ALLOW_SNAPSHOT_ISOLATION OFF
GO
ALTER DATABASE Northwind SET READ_COMMITTED_SNAPSHOT OFF WITH ROLLBACK IMMEDIATE
GO

IF OBJECT_ID('TabEstoque') IS NOT NULL
  DROP TABLE TabEstoque
CREATE TABLE TabEstoque (ProdutoID INT NOT NULL , 
                         Qtde INT) 
GO
ALTER TABLE TabEstoque ADD CONSTRAINT xpkTabEstoque PRIMARY KEY (ProdutoID) WITH(IGNORE_DUP_KEY=ON)
GO
INSERT INTO TabEstoque (ProdutoID, Qtde)
VALUES(rand() * 1000 + 1, rand() * 40 + 1)
GO 2000
DELETE FROM TabEstoque WHERE ProdutoID IN(1, 2, 3)
INSERT INTO TabEstoque (ProdutoID, Qtde)
VALUES(1, 10), (2, 25), (3, 44)
GO
IF OBJECT_ID('TabPedido') IS NOT NULL
  DROP TABLE TabPedido
CREATE TABLE TabPedido (PedidoID INT IDENTITY(1, 1) NOT NULL PRIMARY KEY, 
                        ClienteID INT,
                        Valor NUMERIC(18,2)) 
GO
IF OBJECT_ID('TabItemPedido') IS NOT NULL
  DROP TABLE TabItemPedido
CREATE TABLE TabItemPedido (PedidoID  INT NOT NULL , 
                            ProdutoID INT NOT NULL,
                            Qtde      INT) 
GO
ALTER TABLE TabItemPedido ADD CONSTRAINT xpkTabItemPedido PRIMARY KEY (PedidoID, ProdutoID) 
GO
-- Criando novo TYPE de itens de pedido
DROP PROC IF EXISTS st_InsereNovoPedido
DROP TYPE IF EXISTS Type_ItensPedido
GO

CREATE TYPE Type_ItensPedido AS TABLE (ProdutoID INT NOT NULL,
                                       Qtde      INT);
GO

-- Exemplo de como utilizar um TVP
DECLARE @TVP AS Type_ItensPedido;

INSERT INTO @TVP(ProdutoID, Qtde)
VALUES(1, 5),(2, 2),(3, 8);

SELECT * FROM @TVP;
GO

-- Proc pra inserir um pedido novo...
DROP PROC IF EXISTS st_InsereNovoPedido
GO
CREATE PROC st_InsereNovoPedido (@ClienteID Int, 
                                 @Valor NUMERIC(18, 2),
                                 @ItensPedido AS Type_ItensPedido READONLY)
AS
BEGIN
  DECLARE @PedidoID INT

  -- Começando a transação...
  BEGIN TRAN

  INSERT INTO TabPedido(ClienteID, Valor)
  VALUES(@ClienteID, @Valor)
  SET @PedidoID = SCOPE_IDENTITY()
  
  INSERT INTO TabItemPedido (PedidoID, ProdutoID, Qtde)
  SELECT @PedidoID, ProdutoID, Qtde FROM @ItensPedido

  -- Só faço o commit, depois que o insert em TabItemPedido acontecer
  COMMIT TRAN
END
GO

-- Testando a proc pra ver se consigo inserir um pedido com 3 itens
DECLARE @TVP AS Type_ItensPedido;

INSERT INTO @TVP(ProdutoID, Qtde)
VALUES(1, 5),(2, 2),(3, 8);

EXEC st_InsereNovoPedido @ClienteID = 1, @Valor = 20.00, @ItensPedido = @TVP
GO

-- Verificando se a proc funcionou...
SELECT * FROM TabPedido
SELECT * FROM TabItemPedido
GO
TRUNCATE TABLE TabPedido
TRUNCATE TABLE TabItemPedido
GO


-- Criando o controle de estoque via trigger...
DROP TRIGGER IF EXISTS tr_AtualizaEstoque
GO
-- E com nolock? 
CREATE TRIGGER tr_AtualizaEstoque ON TabItemPedido 
FOR INSERT AS
BEGIN
	 DECLARE @QtdeAtual INT, @QtdeVendida INT, @ProdutoID Int

  -- Cursorzinho maroto pra varrer os itens inseridos e validar item a item...
  DECLARE cCursor CURSOR FAST_FORWARD
      FOR SELECT ProdutoID, Qtde
            FROM Inserted

   OPEN cCursor
  FETCH NEXT FROM cCursor INTO @ProdutoID, @QtdeVendida

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- Pega quantidade atual de produtos no estoque
    SELECT @QtdeAtual = SUM(Qtde) 
      FROM TabEstoque 
     WHERE ProdutoID = @ProdutoID

    -- Se tem a quantidade suficiente em estoque, segue a vida....
    IF @QtdeAtual - @QtdeVendida >= 0
    BEGIN
      UPDATE TabEstoque 
         SET Qtde = Qtde - @QtdeVendida
       WHERE ProdutoID = @ProdutoID

      -- Espero um pouco pra simular outra coisa sendo executada...
      -- Só pra fazer o código ser um pouco mais lento...
      WAITFOR DELAY '00:00:01'

      PRINT 'Estoque atualizado com sucesso...'
    END
    ELSE
    BEGIN
      DECLARE @Str VARCHAR(MAX)
      SET @Str = 'Eita, foi mal champs, não tem tudo isso no estoque... só tem ' + CONVERT(VARCHAR, @QtdeAtual) + ' produtos disponíveis...'
      RAISERROR (@Str, 16,0); 
      ROLLBACK TRAN
      BREAK
    END
    FETCH NEXT FROM cCursor INTO @ProdutoID, @QtdeVendida
  END

  CLOSE cCursor
  DEALLOCATE cCursor
END
GO


-- Quanto tenho em estoque pro produtos 1, 2, e 3?
SELECT * 
  FROM TabEstoque
 WHERE ProdutoID IN (1, 2, 3)
/*
  ProdutoID   Qtde
  ----------- -----------
  1           10
  2           25
  3           44
*/

-- Testando a proc e a trigger
-- Primeiro com itens 
DECLARE @TVP AS Type_ItensPedido;

INSERT INTO @TVP(ProdutoID, Qtde)
VALUES(1, 5),(2, 2),(3, 8);

EXEC st_InsereNovoPedido @ClienteID = 1, @Valor = 20.00, @ItensPedido = @TVP
GO

-- Verificando se a proc funcionou...
SELECT * FROM TabPedido
SELECT * FROM TabItemPedido
GO
-- Looks good
SELECT * 
  FROM TabEstoque
 WHERE ProdutoID IN (1, 2, 3)
/*
  ProdutoID   Qtde
  ----------- -----------
  1           5
  2           23
  3           36
*/


-- Agora vamos tentar vender mais que o disponível em estoque...
-- Lembrando pro ProdutoID = 1, só tenho 5 itens em estoque...
DECLARE @TVP AS Type_ItensPedido;

INSERT INTO @TVP(ProdutoID, Qtde)
VALUES(1, 7),(2, 2),(3, 8);

EXEC st_InsereNovoPedido @ClienteID = 1, @Valor = 50.00, @ItensPedido = @TVP
GO


-- Verificando como ficaram as tabelas...
SELECT * FROM TabPedido
SELECT * FROM TabItemPedido
-- Looks good
SELECT * 
  FROM TabEstoque
 WHERE ProdutoID IN (1, 2, 3)
GO

-- Voltar a quantidade disponível para 10 pra testar denovo...
UPDATE TabEstoque SET Qtde = 10
 WHERE ProdutoID = 1
GO

-- Se eu rodar no SQLQueryStress pra simular vários usuários fazendo o insert 
-- como fica? 

-- Comando pra rodar no SQLQueryStress
-- Pedido de 99 reais...
BEGIN TRAN
DECLARE @TVP AS Type_ItensPedido;

INSERT INTO @TVP(ProdutoID, Qtde)
VALUES(rand() * 1000 + 1, rand() * 40 + 1),
      (rand() * 1000 + 1, rand() * 40 + 1),
      (rand() * 1000 + 1, rand() * 40 + 1);

EXEC st_InsereNovoPedido @ClienteID = 1, @Valor = 99.00, @ItensPedido = @TVP
COMMIT
GO
SELECT @@TranCount
GO

-- Verificando como ficaram as tabelas...
-- Nice, apenas 1 pedido foi inserido... So far so good...
SELECT * FROM TabPedido
SELECT * FROM TabItemPedido
-- Looks good
SELECT * 
  FROM TabEstoque
 WHERE Qtde < 0
GO

-- Voltar a quantidade disponível para 10 pra testar denovo...
UPDATE TabEstoque SET Qtde = 10
 WHERE ProdutoID = 1
GO


ALTER DATABASE Northwind SET ALLOW_SNAPSHOT_ISOLATION ON
GO
ALTER DATABASE Northwind SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE
GO

-- Rodar SQLQueryStress denovo...


-- Tudo certo?
SELECT * FROM TabEstoque
WHERE Qtde < 0
GO

-- Ajustando dados... 
UPDATE TabEstoque SET Qtde = rand() * 40 + 1
GO


-- Corrigindo a trigger...
DROP TRIGGER IF EXISTS tr_AtualizaEstoque
GO
CREATE TRIGGER tr_AtualizaEstoque ON TabItemPedido 
FOR INSERT AS
BEGIN
	 DECLARE @QtdeAtual INT, @QtdeVendida INT, @ProdutoID Int

  -- Cursorzinho maroto pra varrer os itens inseridos e validar item a item...
  DECLARE cCursor CURSOR FAST_FORWARD
      FOR SELECT ProdutoID, Qtde
            FROM Inserted

   OPEN cCursor
  FETCH NEXT FROM cCursor INTO @ProdutoID, @QtdeVendida

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -- Pega quantidade atual de produtos no estoque
    -- REPEATABLEREAD, irá segurar lock na linha e não deixa valor ser atualizado...
    -- não lê a última versão comitada... espera o lock ser liberado...
    SELECT @QtdeAtual = SUM(Qtde) 
      FROM TabEstoque WITH(REPEATABLEREAD) 
     WHERE ProdutoID = @ProdutoID

    -- Se tem a quantidade suficiente em estoque, segue a vida....
    IF @QtdeAtual - @QtdeVendida >= 0
    BEGIN
      UPDATE TabEstoque 
         SET Qtde = Qtde - @QtdeVendida
       WHERE ProdutoID = @ProdutoID

      -- Espero um pouco pra simular outra coisa sendo executada...
      -- Só pra fazer o código ser um pouco mais lento...
      WAITFOR DELAY '00:00:01'

      PRINT 'Estoque atualizado com sucesso...'
    END
    ELSE
    BEGIN
      DECLARE @Str VARCHAR(MAX)
      SET @Str = 'Eita, foi mal champs, não tem tudo isso no estoque... só tem ' + CONVERT(VARCHAR, @QtdeAtual) + ' produtos disponíveis...'
      RAISERROR (@Str, 16,0); 
      ROLLBACK TRAN
      BREAK
    END
    FETCH NEXT FROM cCursor INTO @ProdutoID, @QtdeVendida
  END

  CLOSE cCursor
  DEALLOCATE cCursor
END
GO

-- Rodar SQLQueryStress denovo...


-- Tudo certo?
SELECT * FROM TabEstoque
WHERE Qtde < 0
GO


-- Monitorando locks, blocks e deadlocks
-- Profiler
-- xEvent
-- Blocked process threshold
-- sp_whoisactive @get_locks = 1
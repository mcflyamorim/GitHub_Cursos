/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

-- Print demora pra escrever no painel de mensagens...
DECLARE @i Int, @MSG VarChar(20)
SET @I = 0
WHILE @i < 100000
BEGIN
  SET @I = @I + 1
  SET @MSG = 'Linha – ' + CONVERT(VarChar(10),@I)
  -- Ao inves de usar PRINT @Msg, usar o código abaixo
  PRINT @MSG
END
GO


-- RAISERROR tem a opção WITH NOWAIT
-- Prefira o RAISERROR... Ou então use o DEGUB do SQL... que é muito melhor...
DECLARE @i Int, @MSG VarChar(20)
SET @I = 0
WHILE @i < 100000
BEGIN
  SET @I = @I + 1
  SET @MSG = 'Linha – ' + CONVERT(VarChar(10),@I)
  -- Ao inves de usar PRINT @Msg, usar o código abaixo
  RAISERROR (@MSG, 0,1) WITH NOWAIT
END
GO


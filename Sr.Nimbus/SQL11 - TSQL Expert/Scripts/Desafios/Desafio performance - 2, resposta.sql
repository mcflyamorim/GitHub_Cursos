-- Respostas - Desafio de Performance 2


-- Otimizações
-- DROP INDEX ix1 ON Pedidos 
CREATE INDEX ix1 ON Pedidos (DT_Pedido) INCLUDE(Valor) WITH(DATA_COMPRESSION = PAGE)
GO
-- DROP INDEX ix1 ON Produtos
CREATE INDEX ix1 ON Produtos (ID_Produto) INCLUDE(Descricao) WITH(DATA_COMPRESSION = PAGE)
GO



-- Melhorou? ... E agora? O que fazer? 
CHECKPOINT
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON
DECLARE @DT_Inicio Date = '20130510',
        @DT_Fim Date = '20130520',
        @DescrProd VarChar(200) = '%cicle%'

SELECT Pedidos.NumeroPedido, 
       Pedidos.DT_Pedido,
       Pedidos.Valor,
       SUM(ItensPed.Qtde) AS TotalItens
  FROM Pedidos
 INNER JOIN ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 INNER JOIN Produtos
    ON ItensPed.ID_Produto = Produtos.ID_Produto
 WHERE Pedidos.DT_Pedido BETWEEN @DT_Inicio AND @DT_Fim
   AND Produtos.Descricao like @DescrProd
 GROUP BY Pedidos.NumeroPedido, 
          Pedidos.DT_Pedido,
          Pedidos.Valor
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF

-- DROP INDEX ix1 ON ItensPed
CREATE INDEX ix1 ON ItensPed (DT_Entrega, NumeroPedido) INCLUDE(Qtde) WITH(DATA_COMPRESSION = PAGE)
GO



-- Melhorando o acesso a ItensPed

-- Obter valores para filtro em DT_Entrega
IF OBJECT_ID('vw_Agg_Pedidos_VS_ItensPed') IS NOT NULL
  DROP VIEW vw_Agg_Pedidos_VS_ItensPed
GO
CREATE VIEW vw_Agg_Pedidos_VS_ItensPed
WITH SCHEMABINDING
AS
SELECT Pedidos.DT_Pedido,
       ItensPed.DT_Entrega,
       COUNT_BIG(*) AS Cnt
  FROM dbo.Pedidos
 INNER JOIN dbo.ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 GROUP BY Pedidos.DT_Pedido,
          ItensPed.DT_Entrega
GO
CREATE UNIQUE CLUSTERED INDEX ix_vw_Agg_Pedidos_VS_ItensPed ON vw_Agg_Pedidos_VS_ItensPed(DT_Pedido, DT_Entrega) WITH(DATA_COMPRESSION = PAGE)
GO


CHECKPOINT
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON
DECLARE @DT_Inicio Date = '20130510',
        @DT_Fim Date = '20130520',
        @DT_Entrega_Fim Date = NULL,
        @DescrProd VarChar(200) = '%cicle%'

SELECT @DT_Entrega_Fim = MAX(DT_Entrega)
  FROM vw_Agg_Pedidos_VS_ItensPed WITH(NOEXPAND)
 WHERE DT_Pedido <= @DT_Fim

SELECT Pedidos.NumeroPedido, 
       Pedidos.DT_Pedido,
       Pedidos.Valor,
       SUM(ItensPed.Qtde) AS TotalItens
  FROM Pedidos
 INNER JOIN ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 INNER JOIN Produtos
    ON ItensPed.ID_Produto = Produtos.ID_Produto
 WHERE Pedidos.DT_Pedido BETWEEN @DT_Inicio AND @DT_Fim
   AND ItensPed.DT_Entrega BETWEEN @DT_Inicio AND @DT_Entrega_Fim
   AND Produtos.Descricao like @DescrProd
 GROUP BY Pedidos.NumeroPedido,
          Pedidos.DT_Pedido,
          Pedidos.Valor
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF
GO


-- Melhorando o acesso a Produtos
IF OBJECT_ID('fnSequencial', 'IF') IS NOT NULL
  DROP FUNCTION dbo.fnSequencial
GO
CREATE FUNCTION dbo.fnSequencial (@i Int)
RETURNS TABLE
AS
RETURN 
(
 WITH L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
     L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
     L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
     L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
     L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
     L5   AS(SELECT 1 AS C FROM L4 AS A CROSS JOIN L4 AS B), -- 4,294,967,296 rows
     Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L5)

SELECT TOP (@i) N AS Num
  FROM Nums
)
GO
/*
  SELECT * FROM dbo.fnSequencial(10)
*/

-- Função fnGeraFragmentos
IF OBJECT_ID('fnGeraFragmentos') IS NOT NULL
  DROP FUNCTION fnGeraFragmentos
GO
CREATE FUNCTION dbo.fnGeraFragmentos(@Str VarChar(MAX)) RETURNS TABLE 
AS
RETURN
  (
    SELECT DISTINCT SUBSTRING(REPLACE(@Str, ' ', ''), Num, 5) AS Fragmento
      FROM dbo.fnSequencial(LEN(REPLACE(@Str, ' ', '')) -4)
  )
GO

-- Teste function 1
SELECT * FROM dbo.fnGeraFragmentos('Fabiano Amorim')
GO

-- Teste function 1
SELECT * FROM dbo.fnGeraFragmentos('Bicicleta')
GO



-- Tabela de fragmentos
-- Obs.: Excelente canditada a compressão
-- Cria view com dados de distribuição por Fragmento
IF OBJECT_ID('vwFragmentoStatistics') IS NOT NULL
  DROP VIEW vwFragmentoStatistics
GO
IF OBJECT_ID('TabFragmentos') IS NOT NULL
  DROP TABLE TabFragmentos
GO
CREATE TABLE TabFragmentos (ID_Produto Integer NOT NULL,
                            Fragmento  Char(5) NOT NULL,
                            CONSTRAINT pk_TabFragmentos PRIMARY KEY (Fragmento, ID_Produto) WITH(DATA_COMPRESSION = PAGE))
GO
CREATE INDEX ix_ID_Produto ON TabFragmentos(ID_Produto) WITH(DATA_COMPRESSION = PAGE)
GO

-- 7 minutos
INSERT INTO TabFragmentos WITH(TABLOCK)
SELECT Produtos.ID_Produto, fnGeraFragmentos.Fragmento
  FROM Produtos
 CROSS APPLY dbo.fnGeraFragmentos(Produtos.Descricao)
GO

-- Agora já consigo fazer o select com operador de igualdade
SELECT * 
  FROM TabFragmentos
 INNER JOIN dbo.fnGeraFragmentos('cicle')
    ON TabFragmentos.Fragmento = fnGeraFragmentos.Fragmento

-- Já sei que produto 1 e 3 tem o texto "cicle"

CHECKPOINT
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON

DECLARE @DT_Inicio Date = '20130510',
        @DT_Fim Date = '20130520',
        @DT_Entrega_Fim Date = NULL,
        @DescrProd VarChar(200) = '%cicle%',
        @Fragmento1 Char(5)

SELECT @DT_Entrega_Fim = MAX(DT_Entrega)
  FROM vw_Agg_Pedidos_VS_ItensPed WITH(NOEXPAND)
 WHERE DT_Pedido <= @DT_Fim

SELECT Pedidos.NumeroPedido, 
       Pedidos.DT_Pedido,
       Pedidos.Valor,
       SUM(ItensPed.Qtde) AS TotalItens
  FROM Pedidos
 INNER JOIN ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 INNER JOIN Produtos
    ON ItensPed.ID_Produto = Produtos.ID_Produto
 WHERE Pedidos.DT_Pedido BETWEEN @DT_Inicio AND @DT_Fim
   AND ItensPed.DT_Entrega BETWEEN @DT_Inicio AND @DT_Entrega_Fim
   AND Produtos.Descricao like @DescrProd
   AND EXISTS (SELECT TabFragmentos.*
                 FROM TabFragmentos
                INNER JOIN dbo.fnGeraFragmentos(REPLACE(@DescrProd, '%', ''))
                   ON fnGeraFragmentos.Fragmento = TabFragmentos.Fragmento
                WHERE TabFragmentos.ID_Produto = Produtos.ID_Produto)
 GROUP BY Pedidos.NumeroPedido,
          Pedidos.DT_Pedido,
          Pedidos.Valor
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF



-- Mas e se o usuário digitar um texto maior?

/* 
  Por exemplo... suponha que o usuário digite "Carroceria" e tenhamos 
  uma tabela com fragmentos de 4 caracteres

  Ao procurar na tabela de fragmentos pelo valor "Carro" 
  isso pode retornar varias linhas... porém o like por '%Carroceria%' futuramente irá eliminar 
  essas linhas... neste caso o Exists não seria tão eficiente, porque ele estaria retornando vários falsos
  positivos...

  Para evitar este problema podemos criar uma tabela com a quantidade de produtos por fragmento
  e utiliza-la para identificar qual o fragmento que retorna menos linhas...
  E futuramente usaremos este fragmento como filtro...

*/

CREATE VIEW vwFragmentoStatistics
WITH SCHEMABINDING
AS 
SELECT Fragmento, COUNT_BIG(*) AS Cnt
  FROM dbo.TabFragmentos
 GROUP BY Fragmento
GO
-- Materializar a view
CREATE UNIQUE CLUSTERED INDEX ix ON vwFragmentoStatistics(Fragmento)
GO
--SELECT * FROM vwFragmentoStatistics
--GO

CHECKPOINT
DBCC DROPCLEANBUFFERS
GO
SET STATISTICS IO ON

DECLARE @DT_Inicio Date = '20130510',
        @DT_Fim Date = '20130520',
        @DT_Entrega_Fim Date = NULL,
        @DescrProd VarChar(200) = '%cicle%',
        @Fragmento1 Char(5)

SELECT TOP 1 @Fragmento1 = Fragmento
  FROM vwFragmentoStatistics
 WHERE EXISTS(SELECT Fragmento 
                FROM dbo.fnGeraFragmentos(REPLACE(@DescrProd, '%', ''))
               WHERE fnGeraFragmentos.Fragmento = vwFragmentoStatistics.Fragmento)
 ORDER BY cnt ASC

SELECT @DT_Entrega_Fim = MAX(DT_Entrega)
  FROM vw_Agg_Pedidos_VS_ItensPed WITH(NOEXPAND)
 WHERE DT_Pedido <= @DT_Fim

SELECT Pedidos.NumeroPedido, 
       Pedidos.DT_Pedido,
       Pedidos.Valor,
       SUM(ItensPed.Qtde) AS TotalItens
  FROM Pedidos
 INNER JOIN ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 INNER JOIN Produtos
    ON ItensPed.ID_Produto = Produtos.ID_Produto
 WHERE Pedidos.DT_Pedido BETWEEN @DT_Inicio AND @DT_Fim
   AND ItensPed.DT_Entrega BETWEEN @DT_Inicio AND @DT_Entrega_Fim
   AND Produtos.Descricao like @DescrProd
   AND EXISTS (SELECT *
                 FROM TabFragmentos
                WHERE TabFragmentos.ID_Produto = Produtos.ID_Produto
                  AND TabFragmentos.Fragmento = @Fragmento1) --Fragmento com menos linhas
 GROUP BY Pedidos.NumeroPedido,
          Pedidos.DT_Pedido,
          Pedidos.Valor
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS IO OFF


-- Trigger para manter tabela de fragmentos atualizada
IF OBJECT_ID('tr_AtualizaFragmentos') IS NOT NULL
  DROP TRIGGER tr_AtualizaFragmentos
GO
CREATE TRIGGER tr_AtualizaFragmentos ON Produtos
FOR INSERT, UPDATE, DELETE 
AS
BEGIN
  SET XACT_ABORT ON
  SET NOCOUNT ON
  -- Sai da trigger caso nenhuma linha tenha sido inserida ou removida
  IF NOT EXISTS (SELECT * FROM inserted) AND
     NOT EXISTS (SELECT * FROM deleted)
    RETURN
  -- Sai da trigger caso não tenha alteração na coluna Descricao
  IF EXISTS (SELECT * FROM inserted) AND NOT UPDATE(Descricao)
    RETURN
  -- Apaga os fragmentos que sofreram alteração
  DELETE TabFragmentos
    FROM TabFragmentos
   INNER JOIN (SELECT ID_Produto FROM Inserted 
                UNION ALL 
               SELECT ID_Produto FROM Deleted) AS Tab
      ON TabFragmentos.ID_Produto = Tab.ID_Produto
  -- Insere os novos fragmentos
  INSERT TabFragmentos (Fragmento, ID_Produto)
  SELECT fnGeraFragmentos.Fragmento, Inserted.ID_Produto
    FROM Inserted
    CROSS APPLY dbo.fnGeraFragmentos(Inserted.Descricao)
END

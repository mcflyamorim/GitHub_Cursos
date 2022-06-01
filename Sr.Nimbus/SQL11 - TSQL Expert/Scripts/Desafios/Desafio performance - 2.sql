USE tempdb
GO

-- Preparar base, aprox. 3 mins para rodar
IF OBJECT_ID('Produtos') IS NOT NULL
  DROP TABLE Produtos
GO
CREATE TABLE Produtos (ID_Produto Int IDENTITY(1,1) PRIMARY KEY,
                       Descricao  VarChar(400),
                       Col1       VarChar(400) DEFAULT NEWID())
GO
 
INSERT INTO Produtos (Descricao)
VALUES ('Bicicleta'), ('Carro'), ('Motocicleta'), ('Trator')
GO
;WITH CTE_1
AS
(
  SELECT TOP 200000 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rn
    FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
)
INSERT INTO Produtos (Descricao)
SELECT REPLACE(NEWID(), '-', ' ')
  FROM CTE_1
GO
 
--SELECT * FROM Produtos
--GO
 
IF OBJECT_ID('ItensPed') IS NOT NULL
  DROP TABLE ItensPed
GO
IF OBJECT_ID('Pedidos') IS NOT NULL
  DROP TABLE Pedidos
GO
CREATE TABLE Pedidos (NumeroPedido VarChar(80) PRIMARY KEY,
                      DT_Pedido    Date,
                      ID_Cliente   Int,
                      Valor        Float)
GO
;WITH CTE_1
AS
(
  SELECT TOP 50000 ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS rn
    FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
)
INSERT INTO Pedidos(NumeroPedido, DT_Pedido, ID_Cliente, Valor)
SELECT 'Ped-' + CONVERT(VarChar, rn),  -- Composto por "Ped + NumeroSequencial"
       GetDate() - ABS(CheckSum(NEWID()) / 10000000),
       ABS(CHECKSUM(NEWID())) / 1000000 AS ID_Cliente,
       ABS(CHECKSUM(NEWID())) / 100000. AS Valor
  FROM CTE_1
GO
 
--SELECT * FROM Pedidos
--GO
 
IF OBJECT_ID('ItensPed') IS NOT NULL
  DROP TABLE ItensPed
GO
CREATE TABLE ItensPed (NumeroPedido VarChar(80) FOREIGN KEY REFERENCES Pedidos(NumeroPedido),
                       DT_Entrega   Date,
                       ID_Produto   Int,
                       Qtde         SmallInt,
                       PRIMARY KEY(NumeroPedido, ID_Produto) WITH(IGNORE_DUP_KEY=ON))
GO
BEGIN TRAN
GO
INSERT INTO ItensPed(NumeroPedido, DT_Entrega, ID_Produto, Qtde)
SELECT NumeroPedido,
       DATEADD(d, ABS(CheckSum(NEWID()) / 100000000), DT_Pedido),
       ABS(CHECKSUM(NEWID())) / 1000000 + 1 AS ID_Produto,
       ABS(CHECKSUM(NEWID())) / 1000000. AS Qtde
  FROM Pedidos
GO 100
COMMIT TRAN
GO
 
--SELECT * FROM ItensPed
--GO

/*
  Regras
  * Não pode mudar índice cluster
  * Não pode mudar schema das tabelas existentes (fks, datatype, nullable…)
  * Pode criar quantos índices forem necessários (exceto cluster)
  * Vale usar view indexadas
  * Vale criar novos objetos (procedures, views, triggers, functions…)
  * Vale reescrever a consulta
  * Pelo menos 5 caracteres obrigatoriamente são utilizados para fazer o filtro pela descrição do produto
  * Valores utilizados como filtro não são fixos… ou seja, tem que funcionar para qualquer valor que for solicitado
*/


-- Pega uma data válida para os testes
SELECT TOP 1 * 
  FROM Pedidos
 INNER JOIN ItensPed
    ON Pedidos.NumeroPedido = ItensPed.NumeroPedido
 INNER JOIN Produtos
    ON ItensPed.ID_Produto = Produtos.ID_Produto
 WHERE ItensPed.ID_Produto < 4
GO

-- Consulta que precisa ser melhorada:

CHECKPOINT;DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE
GO
SET STATISTICS IO ON
SET STATISTICS TIME ON
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
SET STATISTICS TIME OFF
GO

/*
Table 'ItensPed'. Scan count 0, logical reads 26770, physical reads 1, read-ahead reads 14552, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Pedidos'. Scan count 1, logical reads 230, physical reads 0, read-ahead reads 237, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Worktable'. Scan count 1, logical reads 5300, physical reads 0, read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.
Table 'Produtos'. Scan count 1, logical reads 2283, physical reads 3, read-ahead reads 2269, lob logical reads 0, lob physical reads 0, lob read-ahead reads 0.

SQL Server Execution Times:
  CPU time = 998 ms,  elapsed time = 23115 ms.

SQL Server Execution Times:
  CPU time = 0 ms,  elapsed time = 0 ms.
*/

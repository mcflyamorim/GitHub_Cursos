/*
  Sr.Nimbus - T-SQL Expert
         Módulo 06
  http://www.srnimbus.com.br
*/

USE Northwind
GO

----------------------------------------
------------- Triggers -----------------
----------------------------------------

-- Teste 1

-- Qual a diferença entre @@Identity e SCOPE_IDENTITY()?



IF OBJECT_ID('AuditoriaProduto') IS NOT NULL
  DROP TABLE AuditoriaProduto
GO
CREATE TABLE AuditoriaProduto(ID           Int IDENTITY(1,1) PRIMARY KEY, 
                              ProductID    Int, 
                              DataInclusao DateTime DEFAULT GETDATE())
GO
IF OBJECT_ID('Tr_Produtos') IS NOT NULL
  DROP TRIGGER Tr_Produtos
GO
CREATE TRIGGER Tr_Produtos 
   ON ProductsBig
AFTER INSERT AS
BEGIN
  SET NOCOUNT ON;
  
  INSERT INTO AuditoriaProduto(ProductID)
  SELECT ProductID
    FROM inserted
END;
GO

INSERT INTO ProductsBig (ProductName, Col1)
VALUES  ('Produto Novo Teste Trigger', '')
GO
SELECT @@Identity AS "@@Identity", SCOPE_IDENTITY()
GO

SELECT * FROM AuditoriaProduto
GO


-- Teste 2
-- INSTEAD OF TRIGGER

IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID   INT NOT NULL PRIMARY KEY CHECK (ID > 100),
                 Col1 VarChar(10) NOT NULL)
GO

IF OBJECT_ID('tr_InsertT1') IS NOT NULL
	DROP TRIGGER tr_InsertT1
GO
CREATE TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
	 PRINT 'Registro inserido'
END
GO

-- O que vai acontecer??
INSERT INTO T1 VALUES (1, 'a')
GO


IF OBJECT_ID('tr_InsteadOfT1') IS NOT NULL
	 DROP TRIGGER tr_InsteadOfT1
GO
CREATE TRIGGER tr_InsteadOfT1 ON T1
INSTEAD OF INSERT
AS
BEGIN
	 PRINT 'Registro vai ser inserido?'
END
GO

INSERT INTO T1 VALUES (1, 'a')
GO

-- Existe alguma coisa na tabela?
SELECT * FROM T1
GO

INSERT INTO T1 VALUES (200, 'a') -- 200 não viola a CheckConstraint
GO

-- Existe alguma coisa na tabela?
SELECT * FROM T1
GO

ALTER TRIGGER tr_InsteadOfT1 ON T1
INSTEAD OF INSERT
AS
BEGIN
	DECLARE @ValID INT
	SELECT @ValID = ID from inserted
	
	IF (@ValID <= 100)
		 INSERT INTO T1 VALUES (@ValID + 999, 'a')
	ELSE
		 INSERT INTO T1 VALUES (@ValID, 'a')
END
GO

INSERT INTO T1 VALUES (1, 'a')

-- De onde veio o registro inserido??
SELECT * FROM T1
GO

-- Teste 3
-- Performance INSERTED e DELETED

IF OBJECT_ID('tr_InsertProductsBig') IS NOT NULL
	DROP TRIGGER tr_InsertProductsBig
GO
CREATE TRIGGER tr_InsertProductsBig ON ProductsBig
AFTER UPDATE
AS
BEGIN
  DECLARE @ProductID Int, @ProductName VarChar(200)

  SELECT inserted.ProductID, inserted.ProductName
    INTO #TMP
    FROM inserted
  CREATE UNIQUE CLUSTERED INDEX ix ON #TMP(ProductID)


  DECLARE cCursor
  CURSOR FAST_FORWARD FOR
  SELECT ProductID, ProductName FROM #TMP
  OPEN cCursor

  FETCH NEXT FROM cCursor INTO @ProductID, @ProductName

  WHILE @@FETCH_STATUS = 0
  BEGIN
    PRINT 'Trabalhando com o ProductID: ' + CONVERT(VarChar(10), @ProductID) + ', ProductName: ' + @ProductName

    FETCH NEXT FROM cCursor INTO @ProductID, @ProductName
  END
  CLOSE cCursor
  DEALLOCATE cCursor
END
GO

-- Atualizando uma linha
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID = 1
GO

ENABLE TRIGGER tr_InsertProductsBig ON ProductsBig;
GO
-- Atualizando 10000 linhas
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID <= 10000
GO


-- Utilizando a inserted no join
IF OBJECT_ID('tr_InsertProductsBig') IS NOT NULL
	 DROP TRIGGER tr_InsertProductsBig
GO
CREATE TRIGGER tr_InsertProductsBig ON ProductsBig
AFTER UPDATE
AS
BEGIN
  -- Le os dados da inserted 5 vezes fazendo um filtro...
  SELECT * FROM inserted WHERE ProductID = 1
  SELECT * FROM inserted WHERE ProductID = 2
  SELECT * FROM inserted WHERE ProductID = 3
  SELECT * FROM inserted WHERE ProductID = 4
  SELECT * FROM inserted WHERE ProductID = 5
END
GO

-- Atualizando uma linha
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID = 1
GO

-- Atualizando 1000 linhas
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID <= 1000
GO

-- Utilizando uma temporária...
IF OBJECT_ID('tr_InsertProductsBig') IS NOT NULL
 	DROP TRIGGER tr_InsertProductsBig
GO
CREATE TRIGGER tr_InsertProductsBig ON ProductsBig
AFTER UPDATE
AS
BEGIN
  SELECT inserted.ProductID
    INTO #TMP
    FROM inserted
  CREATE UNIQUE CLUSTERED INDEX ix ON #TMP(ProductID)

  -- Le os dados da #TMP 5 vezes fazendo um filtro...
  SELECT * FROM #TMP WHERE ProductID = 1
  SELECT * FROM #TMP WHERE ProductID = 2
  SELECT * FROM #TMP WHERE ProductID = 3
  SELECT * FROM #TMP WHERE ProductID = 4
  SELECT * FROM #TMP WHERE ProductID = 5
END
GO

-- Atualizando uma linha
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID = 1
GO

-- Atualizando 1000 linhas
UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID <= 1000
GO

-- Limpa banco
DROP TRIGGER tr_InsertProductsBig


-- Teste 4
-- Performance Triggers...
-- OBS.: SQL Server 2012 mudou este comportamento...


IF OBJECT_ID('st_Upd_ProductsBig') IS NOT NULL
  DROP PROC st_Upd_ProductsBig
GO
-- Criando uma proc para atualizar a tabela
CREATE PROC dbo.st_Upd_ProductsBig (@ProductName VarChar(250) = NULL, 
                                    @Col1 VarChar(250) = NULL, 
                                    @ProductID Int = NULL)
AS
BEGIN
  UPDATE ProductsBig
     SET ProductName  = ISNULL(@ProductName, ProductName),
         Col1         = ISNULL(@Col1, Col1),
         ModifiedDate = GetDate()
   WHERE ProductID = @ProductID
END
GO

IF OBJECT_ID('trProducts') IS NOT NULL
 	DROP TRIGGER trProducts
GO
CREATE TRIGGER trProducts ON ProductsBig
AFTER UPDATE
AS
BEGIN
  UPDATE ProductsBig
     SET ModifiedDate = GetDate()
    FROM ProductsBig
    INNER JOIN INSERTED
       ON ProductsBig.ProductID = INSERTED.ProductID
END
GO

UPDATE ProductsBig SET Col1 = NEWID()
WHERE ProductID < 100000
GO

DISABLE TRIGGER trProducts ON ProductsBig;
GO

SET STATISTICS IO ON
DECLARE @newid VarChar(500)
SET @newid = NEWID()
EXEC dbo.st_Upd_ProductsBig @Col1 = @newid, @ProductID = 1
SET STATISTICS IO OFF
GO
SELECT ModifiedDate, *
  FROM ProductsBig
 WHERE ProductID = 1
GO


-- Melhor ainda... Configure a aplicação para enviar sempre o update na ModifiedDate


-- Teste 5
-- Performance
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (Col1 Int IDENTITY(1,1) PRIMARY KEY, 
                 Col2 int, 
                 Col3 Char(2000), 
                 Col4 Char(4000))
GO
-- Inserindo 10 mil linhas na tabela...
SET NOCOUNT ON
BEGIN TRAN
DECLARE @i INT = 0
WHILE @i < 10000
BEGIN
  INSERT INTO T1 (Col2) VALUES (@i / 100);
  SET @i += 1
END
COMMIT
GO

-- Exemplo dos dados da tabela
SELECT TOP 10 * FROM T1
GO

-- Tabela destino onde iremos criar triggers
IF OBJECT_ID('T2') IS NOT NULL
  DROP TABLE T2
GO
CREATE TABLE T2 (Col1 Int IDENTITY(1,1) PRIMARY KEY, 
                 Col2 int, 
                 Col3 Char(2000), 
                 Col4 Char(4000))

-- Tabela de auditoria
IF OBJECT_ID('T3') IS NOT NULL
  DROP TABLE T3
GO
CREATE TABLE T3(Col1 int, 
                Col2 Char(100))
GO

-- Inserindo 10000 linhas na tabela T2 sem trigger...
-- 7 segundos
-- 185358 reads
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
BEGIN TRANSACTION
  INSERT INTO T2
  SELECT Col2, Col3, Col4 
    FROM T1
ROLLBACK
GO

-- Vamos criar uma simples trigger que lê todas as linhas inseridas na tabela T2 
-- e copia os dados para tabela T3 (tabela de auditoria)
IF OBJECT_ID('tr_T2') IS NOT NULL 
  DROP TRIGGER tr_T2
GO
CREATE TRIGGER tr_T2 ON T2 
FOR INSERT 
AS
BEGIN
  INSERT INTO T3(Col1, Col2) 
  SELECT Col1, NULL
    FROM inserted
END
GO

-- Este insert irá executar a trigger que dispara o insert uma vez para as 10 mil linhas
-- 7 segundos
-- 259024 reads
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO
BEGIN TRANSACTION
  INSERT INTO T2
  SELECT Col2, Col3, Col4 
    FROM T1
ROLLBACK
GO

-- Aqui o problema começa a aparecer... 
-- Mesma consulta mas agora vamos inserir cada linha em um insert
-- Poderia ser pior ainda se eu não especificar o BEGIN TRAN, pois isso iria gerar
-- uma escrita de begin/commit no transaction log para cada linha inserida

-- 16 segundos
DBCC DROPCLEANBUFFERS
GO
BEGIN TRAN
DECLARE @i INT = 0
WHILE @i < 10000
BEGIN
  INSERT INTO T2
  SELECT Col2, Col3, Col4 
    FROM T1 
   WHERE Col1 = @i
  SET @i += 1
END
ROLLBACK
GO

-- Vamos simular uma trigger que insere 100 linhas na tabela de auditoría(T3) para cada vez que ela é chamada
-- isso irá gerar um scan na T1 para cada execução da trigger pois não tenho índice por Col2...
-- A ideia é mostrar quão ruim as coisas podem ficar... :-)
IF OBJECT_ID('tr_T2') IS NOT NULL 
  DROP TRIGGER tr_T2
GO
CREATE TRIGGER tr_T2 ON T2 
FOR INSERT 
AS
BEGIN
  INSERT INTO T3(Col1, Col2)
  SELECT Col1, NULL 
    FROM T1
   WHERE Col2 = 5;
END
GO

-- E é claro, vamos inserir 10 mil linhas na T2 para forçar um exec na trigger
-- de 10 mil vezes... Isso vai ficar rodando para sempre...
-- 4  mins e 17 segundos
DBCC DROPCLEANBUFFERS
GO
BEGIN TRAN
DECLARE @i INT = 0
WHILE @i < 10000
BEGIN
  INSERT INTO T2
  SELECT Col2, Col3, Col4 
    FROM T1 
   WHERE Col1 = @i
  SET @i += 1
END
ROLLBACK
GO


-- Teste 6
-- Utilizando trigger tables (inserted, deleted) com SQL dinâmico

-- Exemplo código dinâmico
DECLARE @Tab VarChar(50), @SQL VarChar(250)

SET @Tab = 'Products'
SET @SQL = 'SELECT * FROM ' + @Tab
EXEC(@SQL)

-- ex Trigger
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID   INT NOT NULL PRIMARY KEY,
                 Col1 VarChar(10) NOT NULL)
GO

IF OBJECT_ID('tr_InsertT1') IS NOT NULL
	DROP TRIGGER tr_InsertT1
GO
CREATE TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  DECLARE @Tab VarChar(50), @SQL VarChar(250)

  SET @Tab = 'inserted'
  SET @SQL = 'SELECT * FROM ' + @Tab
  EXEC(@SQL)
END
GO

-- Roda? 
INSERT INTO T1 (ID, Col1) 
VALUES  (1,'')
GO

ALTER TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  DECLARE @Tab VarChar(50), @SQL VarChar(250)
  SELECT * INTO #TMP
    FROM inserted

  SET @Tab = '#TMP'
  SET @SQL = 'SELECT * FROM ' + @Tab
  EXEC(@SQL)
END
GO

-- Roda?
INSERT INTO T1 (ID, Col1) 
VALUES  (1,'')
GO

-- Teste 7
-- Identificando o número de linhas afetadas

-- ex Trigger
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID   INT NOT NULL,
                 Col1 VarChar(50) NOT NULL)
GO

IF OBJECT_ID('tr_InsertT1') IS NOT NULL
	DROP TRIGGER tr_InsertT1
GO
CREATE TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  -- Retorna o número de linhas afetadas
  SELECT @@RowCount "Linhas afetadas"
END
GO

-- Retorna 1
INSERT INTO T1 (ID, Col1)
VALUES  (1,'')
GO

-- Retorna 2
INSERT INTO T1 (ID, Col1)
VALUES  (2,''), (3, '')
GO

SELECT * FROM T1

BEGIN TRAN
DECLARE @VarT1 TABLE (ID Int, Col1 VarChar(50))
INSERT INTO @VarT1 VALUES(1, 'Valor Alterado'), (2, 'Valor Alterado'), (4, 'Valor Novo')

-- Qual será o resultado do @@RowCount na trigger de INSERT na T1?
-- Apenas 1 linha esta sendo incluida (4, 'Valor Novo')
MERGE INTO T1
USING @VarT1 AS a
   ON T1.ID = a.ID
 WHEN MATCHED AND T1.Col1 <> a.Col1 THEN
      UPDATE SET T1.Col1 = a.Col1
 WHEN NOT MATCHED THEN
      INSERT (ID, Col1)
      VALUES (a.ID, a.Col1);

SELECT * FROM T1
ROLLBACK
GO

-- Corrigindo a trigger
ALTER TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  -- Retorna o número de linhas afetadas
  SELECT COUNT(*) "Linhas afetadas" FROM inserted 
END
GO

-- Teste 8
-- Não disparando trigger apenas para um determinado comando

-- ex Trigger
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID   INT NOT NULL,
                 Col1 VarChar(50) NOT NULL)
GO

IF OBJECT_ID('tr_InsertT1') IS NOT NULL
	DROP TRIGGER tr_InsertT1
GO
CREATE TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  SELECT 'Triger foi disparada'
END
GO

-- Como fazer para inserir sem disparar a trigger?
INSERT INTO T1 (ID, Col1) 
VALUES  (1,'')
GO

-- Desabilitar/Habilitar a trigger não é uma opção, pois vale para todos as sessões...

-- Alternativa
-- Criar um 
ALTER TRIGGER tr_InsertT1 ON T1
AFTER INSERT
AS
BEGIN
  IF OBJECT_ID('tempdb.dbo.#Nao_Rodar_O_Codigo_Da_Trigger') IS NOT NULL
    RETURN

  SELECT 'Triger foi disparada'
END

CREATE TABLE #Nao_Rodar_O_Codigo_Da_Trigger (ID Int)
INSERT INTO T1 (ID, Col1) 
VALUES  (1,'')
DROP TABLE #Nao_Rodar_O_Codigo_Da_Trigger
GO

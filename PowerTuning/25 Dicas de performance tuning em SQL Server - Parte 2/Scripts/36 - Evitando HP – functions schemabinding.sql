/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

-- Preparando o ambiente
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('fn_Primeiro_Dia_Mes', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_Primeiro_Dia_Mes
GO
CREATE FUNCTION dbo.fn_Primeiro_Dia_Mes(@Data DateTime)
RETURNS DATETIME
AS
BEGIN
  RETURN DATEADD(d, (- DATEPART(d, @Data) + 1) , @Data);
END
GO
IF OBJECT_ID('fn_Ultimo_Dia_Mes', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_Ultimo_Dia_Mes
GO
CREATE FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO


/*
  Analisar os seguintes contadores no PERFMON
  Transactions:PageSplits/Sec
  Processor:Processor Time
*/

IF OBJECT_ID('#TMP') IS NOT NULL -- Funciona?

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Inserindo em uma tabela temporária sem usar as scalar functions
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       DATEADD(d, (- DATEPART(d, OrderDate) + 1) , OrderDate) AS fn_Primeiro_Dia_Mes,
       DATEADD(d , -DATEPART(d, DATEADD( mm, 1, OrderDate)) ,DATEADD( mm, 1, OrderDate)) AS fn_Ultimo_Dia_Mes -- SQL2012 EOMONTH
  FROM OrdersBig
GO

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Inserindo em uma tabela temporária usando as scalar functions
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       dbo.fn_Primeiro_Dia_Mes(OrderDate) AS fn_Primeiro_Dia_Mes,
       dbo.fn_Ultimo_Dia_Mes(OrderDate) AS fn_Ultimo_Dia_Mes
  FROM OrdersBig
GO
/*
  Um novo operador de Spool é utilizado para ler os dados que serão inseridos na tabela
  temporária, este operador é utilizado para evitar erros relacionados ao halloween problem.
  Como a function não foi definida com SCHEMABINDING o SQL Server não sabe se a function
  irá ler ou atualizar dados de alguma tabela... Então ele usa o SPOOL para evitar possíveis erros.
  http://blogs.msdn.com/b/ianjo/archive/2006/01/31/521078.aspx
  http://blogs.msdn.com/b/mikecha/archive/2009/05/19/sql-high-cpu-and-tempdb-growth-by-scalar-udf.aspx
*/

-- Vamos recriar as functions e definir como SCHEMABINDING
ALTER FUNCTION dbo.fn_Primeiro_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  RETURN DATEADD(d, (- DATEPART(d, @Data) + 1) , @Data);
END
GO
ALTER FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (ID Int IDENTITY(1,1) PRIMARY KEY,
                   fn_Primeiro_Dia_Mes DateTime, 
                   fn_Ultimo_Dia_Mes DateTime)
GO
-- Testando novamente com as functions definidas como schemabinding
-- Analisar o plano...
INSERT INTO #TMP (fn_Primeiro_Dia_Mes, fn_Ultimo_Dia_Mes)
SELECT TOP 500000
       dbo.fn_Primeiro_Dia_Mes(OrderDate) AS fn_Primeiro_Dia_Mes,
       dbo.fn_Ultimo_Dia_Mes(OrderDate) AS fn_Ultimo_Dia_Mes
  FROM OrdersBig
GO
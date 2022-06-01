/*
  Sr.Nimbus - T-SQL Expert
         Módulo 02
  http://www.srnimbus.com.br
*/

use Northwind
GO

----------------------------------
-------- User functions ----------
----------------------------------

-- Entendendo como Scalar functions são executadas


/* 
  Qual será o resultado de CONVERT(Time, GetDate())? 
  A - Um valor para cada linha.
  B - O mesmo valor para todas as linhas.
*/
SELECT TOP 200000
       ContactName, CONVERT(Time, GetDate())
  FROM CustomersBig
GO

IF OBJECT_ID('fn_RetornaHora', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_RetornaHora
GO
CREATE FUNCTION dbo.fn_RetornaHora()
RETURNS Time
AS
BEGIN
  RETURN CONVERT(Time, GetDate())
END
GO
SELECT dbo.fn_RetornaHora()

-- E agora? Qual será o resultado da scalar function?
SELECT TOP 200000
       ContactName, dbo.fn_RetornaHora()
  FROM CustomersBig
GO




-- Exercício Split...
-- "Módulo 02 - Exercício, (Split).SQL"





-- Testes Performance --

-- Preparando o ambiente
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


-- Teste 1
-- Comparar uso de CPU no Profiler
SELECT TOP 5
       dbo.fn_Primeiro_Dia_Mes(OrderDate) AS fn_Primeiro_Dia_Mes,
       dbo.fn_Ultimo_Dia_Mes(OrderDate) AS fn_Ultimo_Dia_Mes,
       *
  FROM OrdersBig
GO
SELECT TOP 10000
       DATEADD(d, (- DATEPART(d, OrderDate) + 1) , OrderDate) AS fn_Primeiro_Dia_Mes,
       DATEADD(d , -DATEPART(d, DATEADD( mm, 1, OrderDate)) ,DATEADD( mm, 1, OrderDate)) AS fn_Ultimo_Dia_Mes, -- SQL2012 EOMONTH
       *
  FROM OrdersBig
GO

-- Teste 2
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



-- Teste 3
-- Formatação de dados
IF OBJECT_ID('fn_FormataCNPJ', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_FormataCNPJ
GO
CREATE FUNCTION dbo.fn_FormataCNPJ(@CNPJ char(14))
RETURNS char(18)
AS
BEGIN
  DECLARE @Var varchar(18)
  SET @Var = SUBSTRING(@CNPJ,1,2) + '.' + SUBSTRING(@CNPJ,3,3) + '.' + SUBSTRING(@CNPJ,6,3) + '/' + SUBSTRING(@CNPJ,9,4) + '-' + SUBSTRING(@CNPJ,13,2)
  RETURN @Var
END
GO

-- Comparar uso de CPU no Profiler
SELECT dbo.fn_FormataCNPJ(CNPJ),
       *      
  FROM CustomersBig
GO
SELECT SUBSTRING(CNPJ,1,2) + '.' + SUBSTRING(CNPJ,3,3) + '.' + SUBSTRING(CNPJ,6,3) + '/' + SUBSTRING(CNPJ,9,4) + '-' + SUBSTRING(CNPJ,13,2),
       *
  FROM CustomersBig
GO

-- Teste 4
-- Scalar Functions com SubQueries
DROP INDEX ixCustomerID ON OrdersBig
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(OrderDate)
GO
IF OBJECT_ID('fn_DataUltimaVenda', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_DataUltimaVenda
GO
CREATE FUNCTION dbo.fn_DataUltimaVenda(@CustomerID Int)
RETURNS DateTime
AS
BEGIN
  DECLARE @DtUltimaVenda DateTime
  SELECT @DtUltimaVenda = MAX(OrderDate)
    FROM OrdersBig
   WHERE CustomerID = @CustomerID

  RETURN @DtUltimaVenda
END
GO

SELECT TOP 500000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SELECT TOP 500000
       (SELECT MAX(OrderDate)
          FROM OrdersBig
         WHERE CustomerID = CustomersBig.CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO

-- Vamos ver os planos?
SELECT TOP 500000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SELECT TOP 500000
       (SELECT MAX(OrderDate)
          FROM OrdersBig
         WHERE CustomerID = CustomersBig.CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO

-- E o STATISTICS IO?
SET STATISTICS IO ON
GO
SELECT TOP 500000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SELECT TOP 500000
       (SELECT MAX(OrderDate)
          FROM OrdersBig
         WHERE CustomerID = CustomersBig.CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SET STATISTICS IO OFF

-- Alternativa, Usar inline table function
IF OBJECT_ID('fn_DataUltimaVendaV1', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_DataUltimaVendaV1
GO
CREATE FUNCTION dbo.fn_DataUltimaVendaV1(@CustomerID Int)
RETURNS TABLE
RETURN
(
  SELECT DtUltimaVenda = MAX(OrderDate)
    FROM OrdersBig
   WHERE CustomerID = @CustomerID
)
GO
SELECT TOP 500000
       dbo.fn_DataUltimaVenda(CustomerID) AS fn_DataUltimaVenda,
       *
  FROM CustomersBig
GO
SELECT TOP 500000
       fn_DataUltimaVendaV1.DtUltimaVenda,
       *
  FROM CustomersBig
 CROSS APPLY dbo.fn_DataUltimaVendaV1(CustomersBig.CustomerID) AS fn_DataUltimaVendaV1
GO


-- Teste 5
-- Paralelismo, visualizar os planos, e comparar o tempo

-- Function para retornar zeros a esquerda
IF OBJECT_ID('PadLeft', 'FN') IS NOT NULL
  DROP FUNCTION dbo.PadLeft
GO
CREATE FUNCTION dbo.PadLeft(@Val VarChar(100), @Len Int, @Char Char(1))
RETURNS VarChar(100)
AS
BEGIN
  RETURN RIGHT(REPLICATE(@Char, @Len) + @Val, @Len)
END
GO
IF OBJECT_ID('TabTesteParalelismo') IS NOT NULL
  DROP TABLE TabTesteParalelismo
GO
CREATE TABLE TabTesteParalelismo (Col1 Int , Col2 Int)
GO
INSERT INTO TabTesteParalelismo(Col1, Col2)
SELECT TOP 300000 OrderID, CustomerID
  FROM OrdersBig
GO
-- Visualizar os planos (mostrar diferença usando o SQLQueryStress)
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
DECLARE @i VarChar(200)
SELECT @i = RIGHT('0000000000' + CONVERT(VarChar, Tab1.col1 + Tab2.Col2), 10)
  FROM TabTesteParalelismo AS Tab1
 INNER JOIN TabTesteParalelismo AS Tab2
    ON Tab1.Col1 = Tab2.Col1
 ORDER BY RIGHT('0000000000' + CONVERT(VarChar, Tab1.col1 + Tab2.Col2), 10)
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
DECLARE @i VarChar(200)
SELECT @i = dbo.PadLeft(Tab1.col1 + Tab2.Col2, 10, '0')
  FROM TabTesteParalelismo AS Tab1
 INNER JOIN TabTesteParalelismo AS Tab2
    ON Tab1.Col1 = Tab2.Col1
 ORDER BY dbo.PadLeft(Tab1.col1 + Tab2.Col2, 10, '0')
GO

-- Com CLR conseguimos isolar a " zona em paralelo" 
CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;
DECLARE @i VarChar(200)
SELECT @i = CONVERT(VarChar(100), dbo.fn_PADL(Tab1.col1 + Tab2.Col2, 10, '0'))
  FROM TabTesteParalelismo AS Tab1
 INNER JOIN TabTesteParalelismo AS Tab2
    ON Tab1.Col1 = Tab2.Col1
 ORDER BY CONVERT(VarChar(100), dbo.fn_PADL(Tab1.col1 + Tab2.Col2, 10, '0'))
GO



-- Teste 6
-- Criando uma Multi Statment Function
IF OBJECT_ID('fn_RetornaClientesQueJaCompraram', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_RetornaClientesQueJaCompraram
GO
CREATE FUNCTION dbo.fn_RetornaClientesQueJaCompraram(@ContactName VarChar(200))
RETURNS @TabResult TABLE (CustomerID Int,
                          ContactName VarChar(200),
                          CompanyName VarChar(200))
AS
BEGIN
  INSERT INTO @TabResult
  SELECT CustomersBig.CustomerID, 
         CustomersBig.ContactName, 
         CustomersBig.CompanyName
    FROM CustomersBig
   WHERE CustomersBig.ContactName LIKE @ContactName
     AND EXISTS(SELECT 1 FROM OrdersBig
                 WHERE CustomersBig.CustomerID = OrdersBig.CustomerID)

  RETURN
END
GO

-- Retornando apenas um cliente
SET STATISTICS IO ON
SELECT * 
  FROM dbo.fn_RetornaClientesQueJaCompraram('%%')
 WHERE CustomerID = 10
-- 186 reads, CORRETO?
SET STATISTICS IO OFF
GO

-- Comparar planos, e uso de recursos no profiler

-- Retornar os 10 produtos que com maior valor de venda usando a function
SELECT TOP 10 ProductsBig.*, OrdersBig.*
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 INNER JOIN dbo.fn_RetornaClientesQueJaCompraram('%%')
    ON fn_RetornaClientesQueJaCompraram.CustomerID = OrdersBig.CustomerID
 ORDER BY OrdersBig.Value DESC
GO
-- Sem usar a function
SELECT TOP 10 ProductsBig.*, OrdersBig.*
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 INNER JOIN dbo.CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 ORDER BY OrdersBig.Value DESC
GO


-- Definindo uma PK para a tabela de resultado
ALTER FUNCTION dbo.fn_RetornaClientesQueJaCompraram(@ContactName VarChar(200))
RETURNS @TabResult TABLE (CustomerID Int PRIMARY KEY,
                          ContactName VarChar(200),
                          CompanyName VarChar(200))
AS
BEGIN
  INSERT INTO @TabResult
  SELECT CustomersBig.CustomerID, 
         CustomersBig.ContactName, 
         CustomersBig.CompanyName
    FROM CustomersBig
   WHERE CustomersBig.ContactName LIKE @ContactName
     AND EXISTS(SELECT 1 FROM OrdersBig
                 WHERE CustomersBig.CustomerID = OrdersBig.CustomerID)

  RETURN
END
GO

-- Retornando apenas um cliente (OBS.: Melhorou mas continua ruim...)
SET STATISTICS IO ON
SELECT * 
  FROM dbo.fn_RetornaClientesQueJaCompraram('%%')
 WHERE CustomerID = 10
SET STATISTICS IO OFF
GO

-- Criando tabela para testes
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP (CustomerID Int PRIMARY KEY,
                   ContactName VarChar(200),
                   CompanyName VarChar(200))
INSERT INTO #TMP
SELECT CustomerID,
       ContactName,
       CompanyName
  FROM dbo.fn_RetornaClientesQueJaCompraram('%%')

-- Select usando a tabela temporária
SELECT TOP 10 ProductsBig.*, OrdersBig.*
  FROM ProductsBig
 INNER JOIN Order_DetailsBig
    ON ProductsBig.ProductID = Order_DetailsBig.ProductID
 INNER JOIN OrdersBig
    ON Order_DetailsBig.OrderID = OrdersBig.OrderID
 INNER JOIN dbo.#TMP
    ON #TMP.CustomerID = OrdersBig.CustomerID
 ORDER BY OrdersBig.Value DESC
GO
-- Outras alternativas... Inline Function, View...




-- Teste 7
-- Estatísticas/Índices em colunas calculadas com UDFs deterministicas
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

-- Estimou errado por causa da function...
-- estimou 1.8MB de memória
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO


-- ALTER TABLE OrdersBig DROP COLUMN ComputedColumn1
ALTER TABLE OrdersBig ADD ComputedColumn1 AS dbo.fn_Ultimo_Dia_Mes(OrderDate)
GO

-- Não gera auto create statistics... continua estimando errado
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO


ALTER TABLE OrdersBig DROP COLUMN ComputedColumn1
GO
-- Recriando a function como SCHEMABINDING
IF OBJECT_ID('fn_Ultimo_Dia_Mes', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_Ultimo_Dia_Mes
GO
CREATE FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO
ALTER TABLE OrdersBig ADD ComputedColumn1 AS dbo.fn_Ultimo_Dia_Mes(OrderDate)
GO

-- Gera auto create statistics e estima corretamente
-- repare que demora pra mostrar o plano pela primeira vez
-- devido ao auto create statistics...
-- Estima 1.6MB de memória
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO
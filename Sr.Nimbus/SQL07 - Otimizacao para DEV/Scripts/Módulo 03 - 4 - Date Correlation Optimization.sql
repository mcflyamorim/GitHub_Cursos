/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE NorthWind
GO

/*
  Date Correlation Optimization
*/

-- Preparando o ambiente
SET NOCOUNT ON;
GO
ALTER DATABASE NorthWind SET DATE_CORRELATION_OPTIMIZATION OFF;
GO
IF OBJECT_ID('Order_Details_DateCorrelation') IS NOT NULL
  DROP TABLE Order_Details_DateCorrelation
GO
IF OBJECT_ID('Orders_DateCorrelation') IS NOT NULL
  DROP TABLE Orders_DateCorrelation
GO
CREATE TABLE Orders_DateCorrelation(OrderID   Integer Identity(1,1),
                                     OrderDate DateTime NOT NULL, -- AS COLUNAS DE DATA NÃO PODEM ACEITAR NULL
                                     Value       Numeric(18,2),
                                     CONSTRAINT  xpk_Orders_DateCorrelation PRIMARY KEY NONCLUSTERED(OrderID))
GO
CREATE TABLE Order_Details_DateCorrelation(OrderID    Integer,
                                   ProductID   Integer,
                                   Data_Entrega DateTime NOT NULL, -- AS COLUNAS DE DATA NÃO PODEM ACEITAR NULL
                                   Quantidade   Integer,
                                   CONSTRAINT xpk_Order_Details_DateCorrelation PRIMARY KEY (OrderID, ProductID))
GO

-- Pelo menos uma das colunas de data, tem que pertencerem a um indice cluster
CREATE CLUSTERED INDEX ix_OrderDate ON Orders_DateCorrelation(OrderDate)
GO
CREATE NONCLUSTERED INDEX ix_Data_Entrega ON Order_Details_DateCorrelation(Data_Entrega)
GO
-- É Obrigatório existir uma foreign key entre as tabelas que contém as datas correlatas
ALTER TABLE Order_Details_DateCorrelation ADD CONSTRAINT fk_Order_Details_DateCorrelation_Orders_DateCorrelation FOREIGN KEY(OrderID) REFERENCES Orders_DateCorrelation(OrderID)
GO

DECLARE @i Integer 
SET @i = 0 
WHILE @i < 10000
BEGIN 
  INSERT INTO Orders_DateCorrelation(OrderDate,Value) 
  VALUES(CONVERT(VarChar(10),GetDate() - ABS(CheckSum(NEWID()) / 10000000),112), ABS(CheckSum(NEWID()) / 1000000)) 
  SET @i = @i + 1 
END 
GO
 
INSERT INTO Order_Details_DateCorrelation(OrderID, ProductID, Data_Entrega, Quantidade) 
SELECT OrderID, ABS(CheckSum(NEWID()) / 10000000), CONVERT(VarChar(10),OrderDate + ABS(CheckSum(NEWID()) / 100000000),112), ABS(CheckSum(NEWID()) / 10000000) 
FROM Orders_DateCorrelation 
GO
INSERT INTO Order_Details_DateCorrelation(OrderID, ProductID, Data_Entrega, Quantidade) 
SELECT OrderID, ABS(CheckSum(NEWID()) / 10000), CONVERT(VarChar(10),OrderDate + ABS(CheckSum(NEWID()) / 100000000),112), ABS(CheckSum(NEWID()) / 10000000) 
FROM Orders_DateCorrelation 
GO
INSERT INTO Order_Details_DateCorrelation(OrderID, ProductID, Data_Entrega, Quantidade) 
SELECT OrderID, ABS(CheckSum(NEWID()) / 100), CONVERT(VarChar(10),OrderDate + ABS(CheckSum(NEWID()) / 100000000),112), ABS(CheckSum(NEWID()) / 10000000) 
FROM Orders_DateCorrelation 
GO
INSERT INTO Order_Details_DateCorrelation(OrderID, ProductID, Data_Entrega, Quantidade) 
SELECT OrderID, ABS(CheckSum(NEWID()) / 10), CONVERT(VarChar(10),OrderDate + ABS(CheckSum(NEWID()) / 100000000),112), ABS(CheckSum(NEWID()) / 10000000) 
FROM Orders_DateCorrelation 
GO

-- Visualizando os dados da tabela
SELECT * 
  FROM Orders_DateCorrelation
 WHERE OrderID = 1
SELECT * 
  FROM Order_Details_DateCorrelation
 WHERE OrderID = 1

/*
  Utilizar a data do pedido visualizado na consulta acima 
  Consulta de teste, verificar o plano de excução
*/
SET STATISTICS IO ON
SELECT Orders_DateCorrelation.OrderID, 
       Orders_DateCorrelation.OrderDate, 
       Order_Details_DateCorrelation.Data_Entrega, 
       Orders_DateCorrelation.Value
  FROM Orders_DateCorrelation
 INNER JOIN Order_Details_DateCorrelation
    ON Orders_DateCorrelation.OrderID = Order_Details_DateCorrelation.OrderID
 WHERE Orders_DateCorrelation.OrderDate BETWEEN '20101211' AND '20101215'
OPTION (RECOMPILE)
SET STATISTICS IO OFF
GO

-- Vamos habilitar o DATE_CORRELATION_OPTIMIZATION
ALTER DATABASE NorthWind SET DATE_CORRELATION_OPTIMIZATION ON;
GO

-- Rodar a consulta novamente, verificar que foi aplicado um filtro na tabela Order_Details_DateCorrelation
SET STATISTICS IO ON
SELECT Orders_DateCorrelation.OrderID, 
       Orders_DateCorrelation.OrderDate, 
       Order_Details_DateCorrelation.Data_Entrega, 
       Orders_DateCorrelation.Value
  FROM Orders_DateCorrelation
 INNER JOIN Order_Details_DateCorrelation
    ON Orders_DateCorrelation.OrderID = Order_Details_DateCorrelation.OrderID
 WHERE Orders_DateCorrelation.OrderDate BETWEEN '20101211' AND '20101212'
OPTION (RECOMPILE)
SET STATISTICS IO OFF
GO

/*
  Pergunta: Devo continuar explicando o internals/magica?
*/








-- Entendendo a mágica
-- Internamente o SQL Server cria uma view indexada com informações sobre as colunas

-- Vamos verificar o ContactName da view
SELECT * FROM sys.views
-- WHERE is_date_correlation_view = 1
GO

-- Tentar ver os dados da view...
SELECT * FROM [_MPStats_Sys_4316F928_{A48B42C1-56CA-4826-B560-326219E41F64}_fk_Order_Details_DateCorrelation_Orders_DateCorrelation]
GO

-- Vamos criar outra view para poder efetuar o select nela...
-- Exibe o código
sp_helptext [_MPStats_Sys_4316F928_{A48B42C1-56CA-4826-B560-326219E41F64}_fk_Order_Details_DateCorrelation_Orders_DateCorrelation]

-- Vamos criar outra view com o mesmo código para poder efetuar o select nela
IF OBJECT_ID('vw_Test', 'V') IS NOT NULL
  DROP VIEW [dbo].vw_Test
GO
CREATE VIEW [dbo].vw_Test
WITH SCHEMABINDING 
AS 
SELECT DATEDIFF(day, convert(datetime2, '1900-01-01', 121), LEFT_T.[OrderDate])/30 as ParentPID, 
       DATEDIFF(day, convert(datetime2, '1900-01-01', 121), RIGHT_T.[Data_Entrega])/30 as ChildPID, 
       COUNT_BIG(*) AS C   
  FROM [dbo].[Orders_DateCorrelation] AS LEFT_T 
  JOIN [dbo].[Order_Details_DateCorrelation] AS RIGHT_T
    ON LEFT_T.[OrderID] = RIGHT_T.[OrderID] 
 GROUP BY DATEDIFF(day, convert(datetime2, '1900-01-01', 121), LEFT_T.[OrderDate])/30, 
          DATEDIFF(day, convert(datetime2, '1900-01-01', 121), RIGHT_T.[Data_Entrega])/30

/*
  Código no SQL Server 2005:
  
CREATE VIEW [dbo].vw_test
AS 
SELECT CONVERT(int, LEFT_T.[OrderDate] , 121) / 30 as ParentPID, 
       CONVERT(int, RIGHT_T.[Data_Entrega], 121) / 30 as ChildPID, 
       COUNT_BIG(*)  AS C 
  FROM [dbo].[Orders_DateCorrelation] AS LEFT_T 
 INNER JOIN [dbo].[Order_Details_DateCorrelation]  AS RIGHT_T 
    ON LEFT_T.[OrderID] = RIGHT_T.[OrderID]
 GROUP BY CONVERT(int, LEFT_T.[OrderDate] , 121) / 30, 
          CONVERT(int, RIGHT_T.[Data_Entrega] , 121) / 30
GO
*/
-- Visualizando os dados da view
SELECT * FROM vw_test
GO

-- Suponha a seguinte consulta
SELECT * 
  FROM Orders_DateCorrelation 
 INNER JOIN Order_Details_DateCorrelation
    ON Orders_DateCorrelation.OrderID = Order_Details_DateCorrelation.OrderID 
 WHERE Orders_DateCorrelation.OrderDate = '20100711'
/* 
  O filtro da clausula where foi aplicado na coluna OrderDate, 
  O SQL precisa identificar quais os Valuees ele deve informar como 
  predicate na tabela Order_Details_DateCorrelation.Data_Entrega. 
  Vamos passo a passo: 
*/

-- Vamos na view para ver qual é o maior e menor Value para fazer o calculo reverso
-- O Profiler gera este código quando executamos a consulta
SELECT DISTINCT [ChildPID], [ChildPID] 
  FROM [NorthWind].[dbo].vw_Test AS [Tbl1009]
 WHERE [Tbl1009].[ParentPID] = datediff(day,CONVERT(datetime,'1900-01-01 00:00:00.000',121),
                                            CONVERT(datetime,'2010-07-11 00:00:00.000',121)) / (30)
GO

-- Com os Valuees de 1345 e 1346 em mãos o SQL aplica a regra inversa 
-- para poder obter os Valuees do filtro por Data_Entrega.
SELECT CONVERT(DateTime, '19000101') + (1345 * 30)
SELECT CONVERT(DateTime, '19000101') + ((1346  + 1) * 30)

-- Traduzindo, a partir de 1900-01-01 some (1345 * 30), 
-- neste caso teremos o Value de 2010-06-23 como Value mínimo

-- Feito, com estes dados ele pode incluir o filtro na coluna data_entrega.

SELECT * 
  FROM Orders_DateCorrelation 
 INNER JOIN Order_Details_DateCorrelation
    ON Orders_DateCorrelation.OrderID = Order_Details_DateCorrelation.OrderID 
 WHERE Orders_DateCorrelation.OrderDate = '20100711'
/*
  Sr.Nimbus - T-SQL Expert
         Módulo 09
  http://www.srnimbus.com.br
*/


-------------------------------
----------- Mitos -------------
-------------------------------

--COUNT(1) versus COUNT(*)
--O que é melhor? 
SELECT COUNT(1)
  FROM Products
GO
SELECT COUNT(*)
  FROM Products
GO
SELECT COUNT(ProductID) -- PK
  FROM Products
GO

--JOIN versus SubQuery
--O que é melhor? 
SELECT TOP 10 CustomersBig.ContactName, OrdersBig.OrderID
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
GO
SELECT TOP 10 CustomersBig.ContactName, Tab.OrderID
  FROM CustomersBig
 INNER JOIN (SELECT OrderID, CustomerID FROM OrdersBig) AS Tab
    ON CustomersBig.CustomerID = Tab.CustomerID
GO

--DISTINCT versus GROUP BY
--O que é melhor? 
SELECT Col1
  FROM ProductsBig
 GROUP BY Col1
GO
SELECT DISTINCT Col1
  FROM ProductsBig
 GROUP BY Col1
GO

--SET versus SELECT
--O que é melhor?
DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
  SET @V1 = ''
  SET @V2 = ''
  SET @V3 = ''
  SET @V4 = ''
  SET @V5 = ''
  SET @V6 = ''
  SET @V7 = ''
  SET @V8 = ''
  SET @V9 = ''
  SET @V10 = ''
 	SET @i = @i + 1                   
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

GO

DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
SELECT @V1 = '',
       @V2 = '',
       @V3 = '',
       @V4 = '',
       @V5 = '',
       @V6 = '',
       @V7 = '',
       @V8 = '',
       @V9 = '',
       @V10 = '',
       @i = @i + 1;
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

--TOP 1 ORDER BY DESC versus MAX
--Qual é melhor?
CREATE INDEX ixCustomerID ON OrdersBig(CustomerID) INCLUDE(OrderDate)
GO
SELECT MAX(OrdersBig.OrderDate)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.CustomerID = 10
GO
SELECT TOP 1 OrdersBig.OrderDate
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE CustomersBig.CustomerID = 10
 ORDER BY OrdersBig.OrderDate DESC
GO

--UNION versus UNION ALL
--O que é melhor? 

SELECT * FROM Orders
UNION ALL
SELECT * FROM Orders
GO

SELECT * FROM Orders
UNION
SELECT * FROM Orders
GO

--NOT IN versus NOT EXISTS

DBCC DROPCLEANBUFFERS
SELECT TOP 1000 * FROM CustomersBig
WHERE CustomerID NOT IN (SELECT CustomerID FROM OrdersBig)
GO
DBCC DROPCLEANBUFFERS
SELECT TOP 1000 * FROM CustomersBig
WHERE NOT EXISTS(SELECT * FROM OrdersBig WHERE OrdersBig.CustomerID = CustomersBig.CustomerID)

------------------------------
----------- Tuning -----------
------------------------------

------------------------------------------------
-- Variáveis do mesmo tipo da coluna da tabela --
-------------------------------------------------

USE Northwind
GO
DROP INDEX ix_ProductName ON ProductsBig
CREATE INDEX ix_ProductName ON ProductsBig(ProductName)
GO

DECLARE @Nome NVarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO

DECLARE @Nome VarChar(200)
SET @Nome = 'Longlife Tofu 397AE2D2'

-- Faz seek ou scan?
SELECT * FROM ProductsBig
 WHERE ProductName = @Nome
GO


----------------------------------
-- Cuidado com case + subquries --
----------------------------------
SELECT TOP 10000
       ContactName,
       CASE (SELECT SUM(Value) FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID)
         WHEN 1 THEN 'Cliente Grande'
         WHEN 2 THEN 'Cliente Médio'
         WHEN 3 THEN 'Cliente Pequeno'
         ELSE 'Nennum'
       END AS Status_Cliente
  FROM CustomersBig
GO

SELECT TOP 10000
       ContactName,
       (SELECT CASE SUM(Value) 
                 WHEN 1 THEN 'Cliente Grande'
                 WHEN 2 THEN 'Cliente Médio'
                 WHEN 3 THEN 'Cliente Pequeno'
                 ELSE 'Nennum'
               END AS Status_Cliente       
          FROM OrdersBig WHERE CustomersBig.CustomerID = OrdersBig.CustomerID) AS Status_Cliente
  FROM CustomersBig
GO


-------------------------------
------------ XML --------------
-------------------------------
SELECT *, 
      (SELECT ProductName + ';' AS "text()" 
         FROM Products
        INNER JOIN Order_Details
           ON Products.ProductID = Order_Details.ProductID
        WHERE Order_Details.OrderID = Orders.OrderID
        FOR XML PATH('')) AS Itens_Vendidos
  FROM Orders
GO

DECLARE @Tab TABLE (ID Int, Value Varchar(80))
INSERT INTO @Tab (ID, Value) VALUES  (1, '14,48,60,68'),(2, '48,60')
 
SELECT * FROM @Tab

SELECT ID,
       Tab1.ColXML.value('@Ind', 'VarChar(80)') AS Value
  FROM (SELECT *,
               CONVERT(XML, '<Test Ind="' + Replace(Value, ',','"/><Test Ind="') + '"/>') AS ColXML
          FROM @Tab) AS Tab
CROSS APPLY Tab.ColXML.nodes('/Test') As Tab1 (ColXML)


-- IMPORTANTE: Cuidado com performance... Ver exemplo sobre split, CLR é melhor


------------------------------
--------- LIKE '%%' ----------
------------------------------
USE Northwind
GO

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO
SELECT * 
  FROM CustomersBig
 WHERE ContactName like '%42A6AB%'
GO




-- Testa geração dos fragmentos
-- Cria function para geração dos fragmentos
SELECT SUBSTRING('Testes Fragmentos', Num, 3)
  FROM dbo.fnSequencial(LEN('Testes Fragmentos'))

SELECT SUBSTRING('Testes Fragmentos', Num, 3)
  FROM dbo.fnSequencial(LEN('Testes Fragmentos') -2)

SELECT DISTINCT SUBSTRING('Testes Fragmentos', Num, 3)
  FROM dbo.fnSequencial(LEN('Testes Fragmentos') -2)
  
SELECT DISTINCT SUBSTRING(REPLACE('Testes Fragmentos', ' ', ''), Num, 3)
  FROM dbo.fnSequencial(LEN(REPLACE('Testes Fragmentos', ' ', '')) -2)
  

-- Função fnGeraFragmentos
IF OBJECT_ID('fnGeraFragmentos') IS NOT NULL
  DROP FUNCTION fnGeraFragmentos
GO
CREATE FUNCTION dbo.fnGeraFragmentos(@Str VarChar(MAX)) RETURNS TABLE 
AS
RETURN
  (
    SELECT DISTINCT SUBSTRING(REPLACE(@Str, ' ', ''), Num, 3) AS Fragmento
      FROM dbo.fnSequencial(LEN(REPLACE(@Str, ' ', '')) -2)
  )
GO

-- Teste function 1
SELECT * FROM dbo.fnGeraFragmentos('Fabiano Amorim')
GO

-- Teste function 2
SELECT Customers.CustomerID, fnGeraFragmentos.Fragmento
  FROM Customers
 CROSS APPLY dbo.fnGeraFragmentos(Customers.ContactName)
GO

-- Tabela de fragmentos
-- Obs.: Excelente canditada a compressão
IF OBJECT_ID('TabFragmentos') IS NOT NULL
  DROP TABLE TabFragmentos
GO
CREATE TABLE TabFragmentos (CustomerID Integer NOT NULL,
                            Fragmento  char(3) NOT NULL,
                            CONSTRAINT pk_TabFragmentos PRIMARY KEY (Fragmento, CustomerID))
GO
CREATE INDEX ix_CustomerID ON TabFragmentos(CustomerID)
GO

-- 7 minutos
INSERT INTO TabFragmentos WITH(TABLOCK)
SELECT CustomersBig.CustomerID, fnGeraFragmentos.Fragmento
  FROM CustomersBig
 CROSS APPLY dbo.fnGeraFragmentos(CustomersBig.ContactName)
GO

-- Cria view com dados de distribuição por Fragmento
IF OBJECT_ID('vwFragmentoStatistics') IS NOT NULL
  DROP VIEW vwFragmentoStatistics
GO
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
SELECT * FROM vwFragmentoStatistics

DBCC FREEPROCCACHE
DBCC DROPCLEANBUFFERS
GO

DECLARE @Nome VarChar(200)
SET @Nome = '42A6AB'

DECLARE @Fragmento1 char(3),
        @Fragmento2 char(3);

WITH CTE_1
AS 
(
  SELECT Fragmento,
         cnt,
         rn = ROW_NUMBER() OVER (ORDER BY cnt)
    FROM vwFragmentoStatistics
   WHERE EXISTS(SELECT Fragmento 
                  FROM dbo.fnGeraFragmentos(@Nome)
                 WHERE fnGeraFragmentos.Fragmento = vwFragmentoStatistics.Fragmento)
)

SELECT @Fragmento1 = MIN(Fragmento),
       @Fragmento2 = MAX(Fragmento)
  FROM CTE_1
 WHERE rn <= 2

SELECT *
  FROM CustomersBig
 WHERE ContactName LIKE '%' + @Nome + '%'
   AND EXISTS (SELECT *
                 FROM TabFragmentos
                WHERE TabFragmentos.CustomerID = CustomersBig.CustomerID
                  AND TabFragmentos.Fragmento = @Fragmento1) -- Primeiro fragmento com menos linhas
   AND EXISTS (SELECT *
                 FROM TabFragmentos
                WHERE TabFragmentos.CustomerID = CustomersBig.CustomerID
                  AND TabFragmentos.Fragmento = @Fragmento2) -- Segundo fragmento com menos linhas


-- Trigger para manter tabela de fragmentos
IF OBJECT_ID('tr_AtualizaFragmentos') IS NOT NULL
  DROP TRIGGER tr_AtualizaFragmentos
GO
CREATE TRIGGER tr_AtualizaFragmentos ON CustomersBig
FOR INSERT, UPDATE, DELETE 
AS
BEGIN
  SET XACT_ABORT ON
  SET NOCOUNT ON
  -- Sai da trigger caso nenhuma linha tenha sido inserida ou removida
  IF NOT EXISTS (SELECT * FROM inserted) AND
     NOT EXISTS (SELECT * FROM deleted)
    RETURN
  -- Sai da trigger caso não tenha alteração na coluna ContactName
  IF EXISTS (SELECT * FROM inserted) AND NOT UPDATE(ContactName)
    RETURN
  -- Apaga os fragmentos que sofreram alteração
  DELETE TabFragmentos
    FROM TabFragmentos
   INNER JOIN (SELECT CustomerID FROM Inserted 
                UNION ALL 
               SELECT CustomerID FROM Deleted) AS Tab
      ON TabFragmentos.CustomerID = Tab.CustomerID
  -- Insere os novos fragmentos
  INSERT TabFragmentos (Fragmento, CustomerID)
  SELECT fnGeraFragmentos.Fragmento, Inserted.CustomerID
    FROM Inserted
    CROSS APPLY dbo.fnGeraFragmentos(Inserted.ContactName)
END


-- Testes trigger
UPDATE CustomersBig SET ContactName = 'Amorim'
WHERE CustomerID = 18199
GO
DELETE CustomersBig
WHERE CustomerID = 18199
GO

SET IDENTITY_INSERT CustomersBig ON
INSERT INTO CustomersBig
        (CustomerID,
         CityID,
         CompanyName,
         ContactName,
         Col1,
         Col2)
VALUES  (18199,
         1, -- CityID - int
         'Nome CompanyName', -- CompanyName - varchar(209)
         'Fabiano Amorim', -- ContactName - varchar(209)
         '', -- Col1 - varchar(250)
         '')  -- Col2 - varchar(250)
SET IDENTITY_INSERT CustomersBig OFF
GO

SELECT * FROM CustomersBig
WHERE CustomerID = 18199

SELECT * FROM TabFragmentos
WHERE CustomerID = 18199

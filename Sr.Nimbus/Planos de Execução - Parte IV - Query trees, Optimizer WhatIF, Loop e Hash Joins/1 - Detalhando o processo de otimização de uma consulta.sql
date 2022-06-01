USE Northwind
GO

-- Preparando schema para testes

-- Criar view
IF OBJECT_ID('vw_Retorna_CustomersComVendas') IS NOT NULL 
  DROP VIEW vw_Retorna_CustomersComVendas
GO
CREATE VIEW vw_Retorna_CustomersComVendas
WITH SCHEMABINDING
AS
SELECT c.CustomerID, c.ContactName, c.City, R.RegionDescription
  FROM dbo.Customers AS C
  LEFT OUTER JOIN dbo.Region AS R 
    ON R.RegionDescription = c.Region
 WHERE EXISTS(SELECT O.OrderID 
                FROM dbo.Orders AS O 
               WHERE O.CustomerID = C.CustomerID)
GO

-- Criando índice único em Shippers para fazer que o left join com a tabela
-- shiipers + filtro em CompanyName garanta para o QO que apenas 1 linha será retornada
-- Para gerar "project remove"
-- DROP INDEX ixCompanyName ON Shippers 
CREATE UNIQUE INDEX ixCompanyName ON Shippers (CompanyName)
GO

-- Criando check constraint em OrderDate para tornar o filtro reduntante
-- Para gerar "simplify"
-- ALTER TABLE Orders DROP CONSTRAINT ck_ValidaOrderDate 
ALTER TABLE Orders ALTER COLUMN OrderDate DateTime NOT NULL
ALTER TABLE Orders WITH CHECK ADD CONSTRAINT ck_ValidaOrderDate CHECK (OrderDate > '19000101')
GO

-- Criando trusted FK e definindo a coluna como NOT NULL para garantir
-- que tudo que existe em Orders.ShipVia obrigatoriamente existe na tabela Shippers 
-- Para gerar "join collapse"
-- ALTER TABLE Orders DROP CONSTRAINT FK_Orders_Shippers
ALTER TABLE Orders ALTER COLUMN ShipVia Int NOT NULL
GO
ALTER TABLE Orders ADD CONSTRAINT FK_Orders_Shippers
 FOREIGN KEY (ShipVia) REFERENCES  Shippers(ShipperID)
GO


-- Query Original
-- Ver resultado dos traceflags
SELECT v2.ContactName,
       Col1 = (SELECT FirstName FROM Employees AS E 
                WHERE E.EmployeeID = O.EmployeeID),
       Col2 = Convert(VarChar(10), O.OrderDate, 112),
       o.Freight
  FROM (SELECT DISTINCT v1.CustomerID, v1.ContactName, V1.City
          FROM vw_Retorna_CustomersComVendas v1) as v2
 INNER JOIN Orders AS O
    ON O.CustomerID = v2.CustomerID
 INNER JOIN Order_Details AS od
    ON od.OrderID = O.OrderID
 INNER JOIN Shippers s
    ON s.ShipperID = O.ShipVia
 OUTER APPLY (SELECT ShipperID FROM Shippers AS S 
               WHERE S.CompanyName = 'Federal Shipping') AS Outer1
 WHERE v2.City = REPLACE('xxrlin', 'xx', 'Be')
   AND o.Freight > 94 + 5
   AND (NOT(od.Quantity IN(99,99)) OR NOT(od.Quantity IN(99)))
   AND o.OrderDate > '19000101'
   AND O.EmployeeID = 222
   AND od.Quantity = 35
option(
recompile
,querytraceon 3604 -- redirect output to console
,querytraceon 2318 -- opt phases (heuristic join reorder)
,querytraceon 2372 -- memory before/after optimization step
,querytraceon 8612 -- add arguements to the trees
,querytraceon 8605 -- converted tree
,querytraceon 8606 -- simplification trees
,querytraceon 8675 -- optimization step end times and other
)





-- Analisando quais rules foram utilizadas
IF OBJECT_ID('tempdb.dbo.#Snapshot') IS NOT NULL
  DROP TABLE #Snapshot
GO
SELECT *
  INTO #Snapshot
  FROM sys.dm_exec_query_transformation_stats
GO

/* COMANDO SQL */
SELECT v2.ContactName,
       Col1 = (SELECT FirstName FROM Employees AS E 
                WHERE E.EmployeeID = O.EmployeeID),
       Col2 = Convert(VarChar(10), O.OrderDate, 112),
       o.Freight
  FROM (SELECT DISTINCT v1.CustomerID, v1.ContactName, V1.City
          FROM vw_Retorna_CustomersComVendas v1) as v2
 INNER JOIN Orders AS O
    ON O.CustomerID = v2.CustomerID
 INNER JOIN Order_Details AS od
    ON od.OrderID = O.OrderID
 INNER JOIN Shippers s
    ON s.ShipperID = O.ShipVia
 OUTER APPLY (SELECT ShipperID FROM Shippers AS S 
               WHERE S.CompanyName = 'Federal Shipping') AS Outer1
 WHERE v2.City = REPLACE('xxrlin', 'xx', 'Be')
   AND o.Freight > 94 + 5
   AND (NOT(od.Quantity IN(99,99)) OR NOT(od.Quantity IN(99)))
   AND o.OrderDate > '19000101'
   AND O.EmployeeID = 222
   AND od.Quantity = 35
OPTION (RECOMPILE)
GO

SELECT QTS.name,
       QTS.promised - S.promised AS promised,
       CASE 
         WHEN QTS.promised = S.promised THEN 0
         ELSE (QTS.promise_total - S.promise_total)/(QTS.promised - S.promised)
       END promise_value_avg,
       QTS.built_substitute - S.built_substitute AS built_substitute,
       QTS.succeeded - S.succeeded AS succeeded
  FROM #Snapshot S
 INNER JOIN sys.dm_exec_query_transformation_stats QTS
    ON QTS.name = S.name
 WHERE QTS.succeeded <> S.succeeded
 ORDER BY promise_value_avg DESC
OPTION  (KEEPFIXED PLAN);
GO



-- Desabilitando rules com QueryRuleOff

-- Simplification rules
-- TOP = 0, ou seja, não precisa gerar plano... 
-- SQL Server parse and compile time: CPU time = 0 ms, elapsed time = 3 ms.
CHECKPOINT;DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
DECLARE @Var Int = 0
SELECT TOP (@Var)
       v2.ContactName,
       Col1 = (SELECT FirstName FROM Employees AS E 
                WHERE E.EmployeeID = O.EmployeeID),
       Col2 = Convert(VarChar(10), O.OrderDate, 112),
       o.Freight
  FROM (SELECT DISTINCT v1.CustomerID, v1.ContactName, V1.City
          FROM vw_Retorna_CustomersComVendas v1) as v2
 INNER JOIN Orders AS O
    ON O.CustomerID = v2.CustomerID
 INNER JOIN Order_Details AS od
    ON od.OrderID = O.OrderID
 INNER JOIN Shippers s
    ON s.ShipperID = O.ShipVia
 OUTER APPLY (SELECT ShipperID FROM Shippers AS S 
               WHERE S.CompanyName = 'Federal Shipping') AS Outer1
 WHERE v2.City = REPLACE('xxrlin', 'xx', 'Be')
   AND o.Freight > 94 + 5
   AND (NOT(od.Quantity IN(99,99)) OR NOT(od.Quantity IN(99)))
   AND o.OrderDate > '19000101'
   AND O.EmployeeID = 222
   AND od.Quantity = 35
OPTION (RECOMPILE)
SET STATISTICS TIME OFF

-- E se eu desabilitar as simplifications rules?
-- TopOnEmpty e PrjOnEmpty
-- SQL Server parse and compile time: CPU time = 74 ms, elapsed time = 74 ms.
-- Ou seja, pagando custo da compilação de alegre!
CHECKPOINT;DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
DECLARE @Var Int = 0
SELECT TOP (0)
       v2.ContactName,
       Col1 = (SELECT FirstName FROM Employees AS E 
                WHERE E.EmployeeID = O.EmployeeID),
       Col2 = Convert(VarChar(10), O.OrderDate, 112),
       o.Freight
  FROM (SELECT DISTINCT v1.CustomerID, v1.ContactName, V1.City
          FROM vw_Retorna_CustomersComVendas v1) as v2
 INNER JOIN Orders AS O
    ON O.CustomerID = v2.CustomerID
 INNER JOIN Order_Details AS od
    ON od.OrderID = O.OrderID
 INNER JOIN Shippers s
    ON s.ShipperID = O.ShipVia
 OUTER APPLY (SELECT ShipperID FROM Shippers AS S 
               WHERE S.CompanyName = 'Federal Shipping') AS Outer1
 WHERE v2.City = REPLACE('xxrlin', 'xx', 'Be')
   AND o.Freight > 94 + 5
   AND (NOT(od.Quantity IN(99,99)) OR NOT(od.Quantity IN(99)))
   AND o.OrderDate > '19000101'
   AND O.EmployeeID = 222
   AND od.Quantity = 35
OPTION (RECOMPILE, QueryRuleOff TopOnEmpty, QueryRuleOff PrjOnEmpty)
SET STATISTICS TIME OFF



-- Exploration rules
-- Plano legalzinho que acessa primeiro OrdersBig e 
-- depois faz alguns seeks em CustomersBig (nice and clean)
SELECT * 
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 1
OPTION (RECOMPILE, MAXDOP 1)
GO


-- E se eu não deixar ele avaliar a melhor ordem de acesso 
-- as tabelas? 
-- Hint-Force Order... Nãaaaoooo... QueryRuleOff JoinCommute :-)

SELECT * 
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 1
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff JoinCommute)
GO


-- Graças a Deus ele optou pelo Merge Join... Mas pode ficar ruim?
-- Merge Join começando de tras pra frente vai acabar com sua vida
-- por causa da massa inserida... (ver CustomerID em OrdersBig)
SELECT *
  FROM CustomersBig
 INNER JOIN OrdersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 1
 ORDER BY OrdersBig.CustomerID DESC
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff JoinCommute)
GO



-- Implementation rules


-- Hash Match Aggregate tem custo de 63%...
-- Muito alto, vou desabilitar! (QO seu burro!)
-- Tempo médio: SQL Server Execution Times: CPU time = 484 ms,  elapsed time = 554 ms.
CHECKPOINT;DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SELECT CustomersBig.ContactName, 
       SUM(Value)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Fab%'
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1)
SET STATISTICS TIME OFF
GO


-- Desabilitar uso da GbAggToHS ("Group By Aggregate to Stream" ou apenas "Hash Aggregate")
-- Só resta a opção de utilizar o GbAggToStrm( sort +  stream aggregate)
-- Tempo médio: SQL Server Execution Times: CPU time = 1046 ms,  elapsed time = 1176 ms.
CHECKPOINT;DBCC DROPCLEANBUFFERS
GO
SET STATISTICS TIME ON
SELECT CustomersBig.ContactName, 
       SUM(Value)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Fab%'
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff GbAggToHS)
SET STATISTICS TIME OFF
GO

-- E porque o plano está fazendo duas agregações?
-- Porque ele tentou reduzir o custo do join
-- já que poucas linhas serão retornadas após a agregação! (estimativa 4 linhas)
-- E se eu tentar desabilitar a regra LocalAggBelowJoin? (não gosto de 2 operadores de stream!)
SELECT CustomersBig.ContactName, 
       SUM(Value)
  FROM OrdersBig 
 INNER JOIN CustomersBig 
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE CustomersBig.ContactName like 'Fab%'
 GROUP BY CustomersBig.ContactName
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff GbAggToHS, QueryRuleOff LocalAggBelowJoin)

-- Chega de estragar os planos... :-)
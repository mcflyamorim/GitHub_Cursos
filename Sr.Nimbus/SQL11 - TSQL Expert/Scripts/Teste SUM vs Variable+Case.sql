USE AdventureWorks2008R2
GO
DECLARE @VarProds1a10 Money, 
        @VarProds11a20 Money,
        @VarProds21a30 Money, 
        @VarProds31a40 Money, 
        @VarProds41a50 Money

SELECT @VarProds1a10 = SUM(UnitPrice)
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (701,702,703,704,705,706,707,708,709,710) -- Sei que se trocar por BETWEEN 1 and 10 é melhor... mas não posso garantir a sequencia...
SELECT @VarProds11a20 = SUM(UnitPrice)
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (711,712,713,714,715,716,717,718,719,720)
SELECT @VarProds21a30 = SUM(UnitPrice)
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (721,722,723,724,725,726,727,728,729,730)
SELECT @VarProds31a40 = SUM(UnitPrice)
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (731,732,733,734,735,736,737,738,739,740)
SELECT @VarProds41a50 = SUM(UnitPrice)
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (741,742,743,744,745,746,747,748,749,750)

SELECT @VarProds1a10, @VarProds11a20, @VarProds21a30, @VarProds31a40, @VarProds41a50
GO

DECLARE @VarProds1a10  Money = 0, 
        @VarProds11a20 Money = 0,
        @VarProds21a30 Money = 0, 
        @VarProds31a40 Money = 0, 
        @VarProds41a50 Money = 0

SELECT @VarProds1a10 = @VarProds1a10 + CASE
                                         WHEN ProductID IN (701,702,703,704,705,706,707,708,709,710) THEN UnitPrice
                                         ELSE 0
                                       END,
       @VarProds11a20 = @VarProds11a20 + CASE
                                           WHEN ProductID IN (711,712,713,714,715,716,717,718,719,720) THEN UnitPrice
                                           ELSE 0
                                         END,
       @VarProds21a30 = @VarProds21a30 + CASE
                                           WHEN ProductID IN (721,722,723,724,725,726,727,728,729,730) THEN UnitPrice
                                           ELSE 0
                                         END,
       @VarProds31a40 = @VarProds31a40 + CASE
                                           WHEN ProductID IN (731,732,733,734,735,736,737,738,739,740) THEN UnitPrice
                                           ELSE 0
                                         END,
       @VarProds41a50 = @VarProds41a50 + CASE
                                           WHEN ProductID IN (741,742,743,744,745,746,747,748,749,750) THEN UnitPrice
                                           ELSE 0
                                         END
  FROM Sales.SalesOrderDetail
 WHERE SalesOrderID = 43668
   AND ProductID IN (701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720, 721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750)

SELECT @VarProds1a10, @VarProds11a20, @VarProds21a30, @VarProds31a40, @VarProds41a50
GO

-- Testes Performance...
-- 10 segundos
DECLARE @VarProds1a10  Money = 0, 
        @VarProds11a20 Money = 0,
        @VarProds21a30 Money = 0, 
        @VarProds31a40 Money = 0, 
        @VarProds41a50 Money = 0

DECLARE @i Int = 0
WHILE @i < 200000
BEGIN
  SELECT @VarProds1a10 = SUM(UnitPrice)
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (701,702,703,704,705,706,707,708,709,710) -- Sei que se trocar por BETWEEN 1 and 10 é melhor... mas não posso garantir a sequencia...
  SELECT @VarProds11a20 = SUM(UnitPrice)
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (711,712,713,714,715,716,717,718,719,720)
  SELECT @VarProds21a30 = SUM(UnitPrice)
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (721,722,723,724,725,726,727,728,729,730)
  SELECT @VarProds31a40 = SUM(UnitPrice)
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (731,732,733,734,735,736,737,738,739,740)
  SELECT @VarProds41a50 = SUM(UnitPrice)
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (741,742,743,744,745,746,747,748,749,750)
  
  SET @i = @i + 1
END
SELECT @VarProds1a10, @VarProds11a20, @VarProds21a30, @VarProds31a40, @VarProds41a50
GO

-- 2 segundos
DECLARE @VarProds1a10  Money = 0, 
        @VarProds11a20 Money = 0,
        @VarProds21a30 Money = 0, 
        @VarProds31a40 Money = 0, 
        @VarProds41a50 Money = 0

DECLARE @i Int = 0
WHILE @i < 200000
BEGIN
  SELECT @VarProds1a10  = 0,
         @VarProds11a20 = 0,
         @VarProds21a30 = 0,
         @VarProds31a40 = 0,
         @VarProds41a50 = 0

  SELECT @VarProds1a10 = @VarProds1a10 + CASE
                                           WHEN ProductID IN (701,702,703,704,705,706,707,708,709,710) THEN UnitPrice
                                           ELSE 0
                                         END,
         @VarProds11a20 = @VarProds11a20 + CASE
                                             WHEN ProductID IN (711,712,713,714,715,716,717,718,719,720) THEN UnitPrice
                                             ELSE 0
                                           END,
         @VarProds21a30 = @VarProds21a30 + CASE
                                             WHEN ProductID IN (721,722,723,724,725,726,727,728,729,730) THEN UnitPrice
                                             ELSE 0
                                           END,
         @VarProds31a40 = @VarProds31a40 + CASE
                                             WHEN ProductID IN (731,732,733,734,735,736,737,738,739,740) THEN UnitPrice
                                             ELSE 0
                                           END,
         @VarProds41a50 = @VarProds41a50 + CASE
                                             WHEN ProductID IN (741,742,743,744,745,746,747,748,749,750) THEN UnitPrice
                                             ELSE 0
                                           END
    FROM Sales.SalesOrderDetail
   WHERE SalesOrderID = @i
     AND ProductID IN (701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720, 721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750)
  SET @i = @i + 1;
END
SELECT @VarProds1a10, @VarProds11a20, @VarProds21a30, @VarProds31a40, @VarProds41a50
GO
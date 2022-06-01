/*
  Sr.Nimbus - T-SQL Expert
        Query Tuning 
         Soluções
  http://www.srnimbus.com.br
*/

----------------------------------------
--------- Identificando Gaps -----------
----------------------------------------
/*
  Escreva uma consulta que retorne o período inicial e final
  de cada GAP nas vendas.
*/
WITH TempCTE
AS
(
  SELECT ID_Pedido,
         Data_Pedido AS Data_Pedido,
         ROW_NUMBER() OVER(ORDER BY Data_Pedido) Rn
    FROM #TMPPedidos
)
SELECT DISTINCT 
       DateAdd(d, 1, LinhaAtual.Data_Pedido) AS "PeriodoInicial",
       DateAdd(d, -1, ProximaLinha.Data_Pedido) AS "PeriodoFinal"
  FROM TempCTE AS LinhaAtual
 INNER JOIN TempCTE AS ProximaLinha
    ON LinhaAtual.rn + 1 = ProximaLinha.rn 
 WHERE DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido) > 1
GO

USE TempDB
GO
IF OBJECT_ID('tempdb.dbo.#TMPPedidos') IS NOT NULL
  DROP TABLE #TMPPedidos
GO
CREATE TABLE #TMPPedidos (ID_Pedido Integer, Data_Pedido Date)
GO
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10370','19961202')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10371','19961203')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10372','19961204')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10373','19961205')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10374','19961206')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10375','19961209')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10376','19961210')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10377','19961211')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10378','19961212')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10379','19961213')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10380','19961216')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10381','19961217')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10382','19961218')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10383','19961219')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10384','19961220')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10385','19961223')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10386','19961224')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10387','19961225')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10388','19961226')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10389','19961227')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10390','19961230')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10391','19961231')
GO

-- Se ID_Pedido fosse SEMPRE sequêncial...
SELECT LinhaAtual.ID_Pedido,
       LinhaAtual.Data_Pedido AS "Linha Atual",
       ProximaLinha.Data_Pedido AS "Próxima Linha"
  FROM #TMPPedidos AS LinhaAtual
 INNER JOIN #TMPPedidos AS ProximaLinha
    ON LinhaAtual.ID_Pedido + 1 = ProximaLinha.ID_Pedido


SELECT LinhaAtual.ID_Pedido,
       LinhaAtual.Data_Pedido AS "Linha Atual",
       ProximaLinha.Data_Pedido AS "Próxima Linha",
       DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido) -- Diferença de dias
  FROM #TMPPedidos AS LinhaAtual
 INNER JOIN #TMPPedidos AS ProximaLinha
    ON LinhaAtual.ID_Pedido + 1 = ProximaLinha.ID_Pedido


-- Incluindo o filtro de diferença de dias no where
SELECT LinhaAtual.ID_Pedido,
       LinhaAtual.Data_Pedido AS "Linha Atual",
       ProximaLinha.Data_Pedido AS "Próxima Linha"
  FROM #TMPPedidos AS LinhaAtual
 INNER JOIN #TMPPedidos AS ProximaLinha
    ON LinhaAtual.ID_Pedido + 1 = ProximaLinha.ID_Pedido
 WHERE DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido) > 1


-- Retornando os periodos iniciais(+1) e finais (-1)...
SELECT DateAdd(d, 1, LinhaAtual.Data_Pedido) AS "PeriodoInicial",
       DateAdd(d, -1, ProximaLinha.Data_Pedido) AS "PeriodoFinal",
       DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido)
  FROM #TMPPedidos AS LinhaAtual
 INNER JOIN #TMPPedidos AS ProximaLinha
    ON LinhaAtual.ID_Pedido + 1 = ProximaLinha.ID_Pedido
 WHERE DateDiff(d, LinhaAtual.Data_Pedido, ProximaLinha.Data_Pedido) > 1


----------------------------------------
----------- Valores faltando -----------
----------------------------------------
/*
  Escreva uma consulta que retorne todos os dias sem vendas dentro
  de todo o período de vendas existente.
  Sendo data inicial primeira venda, e data final a última venda.
  Em outras palavras, os valores faltantes.
*/

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

WITH CTE_1
AS
(
  SELECT MIN(Data_Pedido) AS Menor_Data, 
         DATEDIFF(day, MIN(Data_Pedido), MAX(Data_Pedido)) AS Col1
    FROM #TMPPedidos
),
CTE_2
AS
(
SELECT *, DATEADD(day, fnSequencial.Num, Menor_Data) AS TodasDatas
  FROM CTE_1
 CROSS APPLY dbo.fnSequencial(CTE_1.Col1)
)
SELECT TodasDatas AS DataSemVenda
  FROM CTE_2
 WHERE NOT EXISTS(SELECT *
                    FROM #TMPPedidos
                   WHERE #TMPPedidos.Data_Pedido = CTE_2.TodasDatas)


----------------------------------------
--------- Identificando Ilhas ----------
----------------------------------------
/*
  Escreva uma consulta que retorne um período existente
*/

SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b)
  FROM Tab1 a
GO

SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1),
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1 + 1) ProxLinha -- Exemplo como retornar próxima linha
  FROM Tab1 a
GO

SELECT * FROM Tab1 b
 WHERE NOT EXISTS(SELECT 1 
                    FROM Tab1 c 
                   WHERE c.Col1 = b.Col1 + 1)
GO

SELECT a.Col1, 
       (SELECT MIN(b.Col1)
          FROM Tab1 b
         WHERE b.Col1 >= a.Col1
           AND NOT EXISTS(SELECT 1 
                            FROM Tab1 c 
                           WHERE c.Col1 = b.Col1 + 1))
  FROM Tab1 a
GO

SELECT MIN(Col1) AS InicioRange, 
       MAX(Col1) AS FimRange
  FROM (SELECT a.Col1, 
               (SELECT MIN(b.Col1)
                  FROM Tab1 b 
                 WHERE b.Col1 >= a.Col1
                   AND NOT EXISTS(SELECT 1 
                                    FROM Tab1 c 
                                   WHERE c.Col1 = b.Col1 +1)) as Grp
          FROM Tab1 a) AS Tab
 GROUP BY Grp
GO

-- Usando ROW_NUMBER

SELECT Col1, 
       ROW_NUMBER() OVER(ORDER BY Col1) AS rn
  FROM dbo.Tab1
GO

SELECT Col1, 
       Col1 - ROW_NUMBER() OVER(ORDER BY Col1) AS Grp
  FROM dbo.Tab1
GO

SELECT MIN(Col1) AS InicioRange, 
       MAX(Col1) AS FimRange
  FROM (SELECT Col1, 
               Col1 - ROW_NUMBER() OVER(ORDER BY Col1) AS Grp
          FROM dbo.Tab1) AS D
 GROUP BY Grp
GO


----------------------------------------
------- Excluir linhas duplicadas ------
----------------------------------------
/*
  Escreva um comando para apagar os tres primeiros pedidos por cliente
*/
WITH CTE_1
AS
(
  SELECT ROW_NUMBER() OVER(PARTITION BY CustomerID ORDER BY OrderDate) AS rn
    FROM #TMP
)
DELETE FROM CTE_1
WHERE rn <= 3
GO



----------------------------------------
---------- Diferença de vendas ---------
----------------------------------------
/*
  Escreva uma consulta que retorne os dados da
  diferença de vendas comparado ao valor de vendas 
  do ano anterior ao atual
  Escreva outra consulta para retornar a mesma informação
  para o valor de vendas baseado no mesmo mês do ano anterior

  Banco: NorthWind
  Tabela: Orders

  Obs.: Pode ser utilizado recursos do SQL Server 2012
  Bonus: Escrever consulta que rode no SQL2005
*/

-- Resultado esperado por ano
/*
  Year        SalesCurrYear  SalesOnPrevYear  %Diff
  ----------- -------------- -----------------------------
  1996        9410.20        0.00             100.000000
  1997        27615.08       9410.20          65.923700
  1998        19475.63       27615.08         -41.792900
*/

-- Resultado esperado por ano
/*
  Year   Month  SalesCurrMonth  SalesOnPrevMonth  %Diff
  ------ ------ --------------- ----------------- ------
  1997   1      2081.30         0.00              0.00
  1998   1      4886.99         2081.30           57.41
  1997   2      1507.70         0.00              0.00
  1998   2      3369.26         1507.70           55.25
  1997   3      1670.10         0.00              0.00
  1998   3      4985.50         1670.10           66.50
  1997   4      2260.13         0.00              0.00
  1998   4      5004.84         2260.13           54.84
  ...
*/

SELECT YEAR(OrderDate) AS Year,
       SUM(Value) AS SalesCurrYear,
       LAG(SUM(Value), 1, 0) OVER(ORDER BY YEAR(OrderDate)) AS SalesOnPrevYear,
       100 - (LAG(SUM(Value), 1, 0) OVER(ORDER BY YEAR(OrderDate)) / SUM(Value)) * 100 AS "%Diff"
  FROM Orders
 GROUP BY YEAR(OrderDate)
GO

WITH CTE_1
AS
(
SELECT YEAR(OrderDate) AS Year,
       MONTH(OrderDate) AS Month,
       SUM(Value) AS SalesCurrMonth,
       LAG(SUM(Value), 1, 0) OVER(PARTITION BY MONTH(OrderDate) ORDER BY MONTH(OrderDate), YEAR(OrderDate)) AS SalesOnPrevMonth,
       CONVERT(Numeric(18,2), 100 - (LAG(SUM(Value), 1, 0) OVER(PARTITION BY MONTH(OrderDate) ORDER BY MONTH(OrderDate), YEAR(OrderDate)) / SUM(Value)) * 100) AS "%Diff"
  FROM Orders
 GROUP BY MONTH(OrderDate), YEAR(OrderDate)
)
SELECT Year, Month, SalesCurrMonth, SalesOnPrevMonth,
       CASE "%Diff"
         WHEN 100.00 THEN 0
         ELSE "%Diff"
       END "%Diff"
  FROM CTE_1


----------------------------------------
--------- % vendas sob total -----------
----------------------------------------
/*
  Escreva uma consulta que retorne todos os pedidos
  e o percentual de vendas que o pedido representa sob o total geral
  
  Escreva outra consulta que retorne todos os pedidos
  e o percentual de vendas que o pedido representa sob o total por 
  cliente

  Banco: NorthWind
  Tabela: Orders

  Obs.: Escrever consulta que rode no SQL2005
*/

-- Resultado esperado:
/*
  OrderID     Value      % based on the total of sales
  ----------- ---------- -------------------------------
  11077       574.35     1.02
  10360       368.10     0.65
  10817       362.43     0.64
  10964       362.00     0.64
  10828       344.50     0.61
  ...
*/

SELECT OrderID,
       Value,
       --SUM(Value) OVER() AS "Sales Total", -- Optional column
       CONVERT(Numeric(18,2) ,Value / (SUM(Value) OVER()) * 100) "% based on the total of sales"
  FROM Orders
ORDER BY Value DESC


-- Resultado esperado por cliente:
/*
  CustomerID  Total per Customer   % based on the customer total
  ----------- -------------------- ---------------------------------------
  63          2739.95              4.85
  71          2679.66              4.74
  20          2666.67              4.72
  65          2182.90              3.86
  37          1719.86              3.04
  5           1425.65              2.52
*/
SELECT DISTINCT 
       CustomerID,
       --SUM(Value) OVER() AS "Sales total", -- Optional column
       SUM(Value) OVER(PARTITION BY CustomerID) AS "Total per Customer",
       CONVERT(Numeric(18,2) , (SUM(Value) OVER(PARTITION BY CustomerID)) / (SUM(Value) OVER()) * 100) "% based on the customer total"
  FROM Orders
ORDER BY "% based on the customer total" DESC

----------------------------------------
--------- Qtde de dias sem vendas ------
----------------------------------------

/*
  Escreva uma consulta que retorne todos os pedidos
  e quantos dias se passaram desde a última venda efetuada
  por cliente

  Banco: NorthWind
  Tabela: Orders

  Obs.: Pode ser utilizado recursos do SQL Server 2012
  Bonus: Escrever consulta que rode no SQL2005
*/
SELECT O.CustomerID,
       O.orderdate,
       O.orderid,
       DATEDIFF(day, (SELECT TOP (1)
                             I.orderdate
                        FROM Orders AS I
                       WHERE I.CustomerID = O.CustomerID
                         AND I.orderdate < O.orderdate
                       ORDER BY orderdate DESC,
                                orderid DESC), O.orderdate) AS "Days since last order"
  FROM Orders AS O
 ORDER BY O.CustomerID, O.OrderDate
GO
-- SQL2012
SELECT CustomerID, 
       orderdate, 
       orderid,
       DATEDIFF(day, LAG(orderdate) -- How to returns 0 instead of null?
                     OVER(PARTITION BY CustomerID 
                          ORDER BY orderdate, orderid), orderdate) AS "Days since last order"
  FROM Orders
 ORDER BY CustomerID, OrderDate
GO



----------------------------------------
----------- Ranking de vendas ----------
----------------------------------------

/*
  Escreva uma consulta que retorne a quantidade de 
  pedidos por cliente. Somente clientes tem mais de 
  10 pedidos deverão serem considerados.

  A consulta deverá retornar os 10 clientes que 
  mais compraram.

  Banco: NorthWind
  Tabela: Orders, Customers
*/

SELECT TOP 10 Customers.ContactName, 
       COUNT(Orders.OrderID) AS Cnt
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
 HAVING COUNT(Orders.OrderID) > 10
 ORDER BY Cnt DESC

-- Resultado esperado:
/*
  ContactName                    Cnt
  ------------------------------ -----------
  Jose Pavarotti                 31
  Roland Mendel                  30
  Horst Kloss                    28
  Maria Larsson                  19
  Patricia McKenna               19
  Paula Wilson                   18
  Carlos Hernández               18
  Christina Berglund             18
  Laurence Lebihan               17
  Peter Franken                  15
*/

----------------------------------------
--------- Ranking de vendas  2 ---------
----------------------------------------

/*
  Escreva uma consulta que retorne a quantidade de 
  pedidos por cliente. Somente clientes tem mais de 
  10 pedidos deverão serem considerados.

  A consulta deverá retornar os 10 clientes que 
  mais compraram.
  Caso exista mais de um cliente que contenha
  a mesma quantidade de pedidos do último cliente do rank
  estes clientes também deverão serem retornados.

  Banco: NorthWind
  Tabela: Orders, Customers
*/

SELECT TOP 10 WITH TIES Customers.ContactName, 
       COUNT(Orders.OrderID) AS Cnt
  FROM Orders
 INNER JOIN Customers
    ON Orders.CustomerID = Customers.CustomerID
 GROUP BY Customers.ContactName
 HAVING COUNT(Orders.OrderID) > 10
 ORDER BY Cnt DESC

-- Resultado esperado:
/*
  ContactName                    Cnt
  ------------------------------ -----------
  Jose Pavarotti                 31
  Roland Mendel                  30
  Horst Kloss                    28
  Maria Larsson                  19
  Patricia McKenna               19
  Paula Wilson                   18
  Carlos Hernández               18
  Christina Berglund             18
  Laurence Lebihan               17
  Peter Franken                  15
  Pirkko Koskitalo               15
  Renate Messner                 15
*/



----------------------------------------
--- Vendas baseado na média mensal -----
----------------------------------------


/*
  Escreva uma consulta que retorne os pedidos mais recentes
  baseado na média mensal de número de pedidos. Ou seja,
  calculando a média de pedidos por mês, quero uma consulta que 
  retorne quais são os úlimos x pedidos baseado nesta média.
  Ex: Se a média de pedidos por mês é de 60 pedidos, quero as 60 últimas vendas...
  Caso eu tenha mais de um pedido por dia, quero que os resultados sejam
  ordenados por OrderID, sendo que os últimos OrderIDs devem aparecer primeiro.

  Banco: NorthWind
  Tabela: Orders
*/

SELECT TOP (SELECT COUNT(*) / (DATEDIFF(month, MIN(OrderDate), MAX(OrderDate)) + 1)
              FROM Orders)
       OrderID,
       OrderDate,
       CustomerID,
       EmployeeID
  FROM Orders
 ORDER BY OrderDate DESC, OrderID DESC;

-- Ou
-- Identifíca os meses com vendas
SELECT DISTINCT SUBSTRING(CONVERT(VarChar(30), OrderDate, 112), 1, 6)
  FROM Orders

-- Quantidade de meses com vendas
SELECT COUNT(DISTINCT SUBSTRING(CONVERT(VarChar(30), OrderDate, 112), 1, 6))
  FROM Orders

-- Média de pedidos baseado na quantidade de meses existentes
SELECT COUNT(*) / COUNT(DISTINCT SUBSTRING(CONVERT(VarChar(30), OrderDate, 112), 1, 6))
  FROM Orders

-- Utilizando valor no TOP + SubQuery
SELECT TOP (SELECT COUNT(*) / COUNT(DISTINCT SUBSTRING(CONVERT(VarChar(30), OrderDate, 112), 1, 6))
              FROM Orders)
       OrderID,
       OrderDate,
       CustomerID
  FROM OrdersBig
 ORDER BY OrderDate DESC, OrderID DESC;
GO

-- Resultado esperado:
/*
  OrderID     OrderDate               CustomerID  EmployeeID
  ----------- ----------------------- ----------- -----------
  11077       1998-05-06 00:00:00.000 65          1
  11076       1998-05-06 00:00:00.000 9           4
  11075       1998-05-06 00:00:00.000 68          8
  11074       1998-05-06 00:00:00.000 73          7
  11073       1998-05-05 00:00:00.000 58          2
  11072       1998-05-05 00:00:00.000 20          4
  11071       1998-05-05 00:00:00.000 46          1
  ...
*/



----------------------------------------
---- Ultimas 3 vendas por Empregado ----
----------------------------------------


/*
  Escreva uma consulta que retorne as últimas 3 
  vendas por empregado. O resultado deverá ser ordenado por 
  FistName

  Banco: NorthWind
  Tabela: Employees, Orders
*/

SELECT Employees.FirstName, Tab.OrderID, Tab.OrderDate 
  FROM Employees
 CROSS APPLY(SELECT TOP 3 OrderID, OrderDate
               FROM Orders 
              WHERE Orders.EmployeeID = Employees.EmployeeID



----------------------------------------
------ Remover caracteres iniciais -----
----------------------------------------
/*
  Escreva uma consulta que trabalhe com uma string.
  A consulta deverá remover os caracteres iniciais de uma coluna.
  Por exemplo, uma string “tsql” deverá virar “sql”, “11234” deverá virar “234”,
  “aaabc” deverá virar “bc”. 
  Ou seja, se o primeiro caracter duplicar, ele deverá ser removido, 
  e a string deverá iniciar a partir do segundo caracter.
  Porem tem uma condição especial para caracteres que são todos iguais 
  por exemplo "0000000" deverá virar "0".

-- Base para testes
use tempdb
GO
IF OBJECT_ID('TC46','U') IS NOT NULL
  DROP TABLE TC46
GO
CREATE TABLE TC46 (String VARCHAR(MAX))
GO
 INSERT INTO TC46(String)
SELECT 'X8JXab' UNION ALL
SELECT '999744499XYZ' UNION ALL
SELECT 'BBBBBBBBBBBBBBBA' UNION ALL
SELECT 'AAAAAAAAAAAAAAAA';

*/

-- Resultado esperado:
/*
  String            Result
  ----------------- --------------------
  999744499XYZ      744499XYZ
  X8JXab            8JXab
  BBBBBBBBBBBBBBBA  A
  AAAAAAAAAAAAAAAA  A
*/

---------------------------------------
---------- FizzBuzz Problem -----------
---------------------------------------

/*
  Escreva um código onde você irá retornar números de 1 a 100, 
  quando o número for múltiplo de 3 você irá escrever ”Fizz”, 
  quando o número for múltiplo de 5 você irá escrever “Buzz” e 
  quando o número for múltiplo de 3 e 5 escreva “FizzBuzz”.
*/
SELECT Num,
	      CASE	
         WHEN Num % (3 * 5) = 0 THEN 'FizzBuzz' 
			      WHEN Num % 5=0 THEN 'Buzz' 
			      WHEN Num % 3=0 THEN 'Fizz' 
	        ELSE	CONVERT(VarChar(10), Num)
	      END AS fizbuzz
FROM northwind.dbo.fnSequencial(100)


---------------------------------------
-- Qual a maior pontuação por Aluno? --
---------------------------------------


DECLARE @TabPontuacao AS TABLE
(
   Nome varchar(15) PRIMARY KEY,
   Pontuacao1 tinyint,
   Pontuacao2 tinyint,
   Pontuacao3 tinyint
);

INSERT @TabPontuacao (Nome, Pontuacao1, Pontuacao2, Pontuacao3)
VALUES ('Fabiano', 3, 9, 10),
       ('Pedro', 16, 9, 8),
       ('Paulo', 8, 9, 8);

-- Resultado esperado:
/*
  Nome            Maior_Pontuacao
  --------------- ---------------
  Fabiano                      10
  Paulo                         9
  Pedro                        16
*/


SELECT Tab1.Nome,
       MAX(Tab2.Pontuacao) AS Maior_Pontuacao
  FROM @TabPontuacao AS Tab1
 CROSS APPLY (VALUES (Tab1.Pontuacao1),
                     (Tab1.Pontuacao2),
                     (Tab1.Pontuacao3)) AS Tab2 (Pontuacao)
GROUP BY Tab1.Nome
ORDER BY Tab1.Nome;
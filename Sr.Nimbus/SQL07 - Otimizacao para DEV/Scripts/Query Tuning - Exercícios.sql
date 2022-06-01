/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/

----------------------------------------
--------- Identificando Gaps -----------
----------------------------------------
/*
  Escreva uma consulta que retorne o período inicial e final
  de cada GAP nas vendas.
*/

USE TempDB
GO
IF OBJECT_ID('tempdb.dbo.#TMPPedidos') IS NOT NULL
  DROP TABLE #TMPPedidos
GO
CREATE TABLE #TMPPedidos (ID_Pedido Integer, Data_Pedido Date)
GO
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10369','19961202')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10371','19961203')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10372','19961204')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10374','19961205')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10375','19961206')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10377','19961209')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10378','19961210')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10379','19961211')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10381','19961212')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10382','19961213')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10384','19961216')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10385','19961217')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10387','19961218')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10388','19961219')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10389','19961220')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10391','19961223')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10392','19961224')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10394','19961225')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10395','19961226')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10397','19961227')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10398','19961230')
INSERT INTO #TMPPedidos (ID_Pedido, Data_Pedido) VALUES('10399','19961231')
GO

SELECT * FROM #TMPPedidos
GO

-- Resultado desejado
/*
  PeriodoInicial PeriodoFinal
  -------------- ------------
  1996-12-07     1996-12-08
  1996-12-14     1996-12-15
  1996-12-21     1996-12-22
  1996-12-28     1996-12-29
*/
----------------------------------------
----------- Valores faltando -----------
----------------------------------------
/*
  Escreva uma consulta que retorne todos os dias sem vendas dentro
  de todo o período de vendas existente.
  Sendo data inicial primeira venda, e data final a última venda.
  Em outras palavras, os valores faltantes.
*/


-- Resultado desejado
/*
  DataSemVenda
  ------------
  1996-12-07
  1996-12-08
  1996-12-14
  1996-12-15
  1996-12-21
  1996-12-22
  1996-12-28
  1996-12-29
*/


----------------------------------------
--------- Identificando Ilhas ----------
----------------------------------------
/*
  Escreva uma consulta que retorne o período existente
*/

USE tempdb;
GO
IF OBJECT_ID('dbo.Tab1') IS NOT NULL
  DROP TABLE dbo.Tab1;
GO
CREATE TABLE dbo.Tab1 (Col1 INT NOT NULL CONSTRAINT PK_Tab1 PRIMARY KEY);
INSERT INTO dbo.Tab1(Col1) VALUES(1);
INSERT INTO dbo.Tab1(Col1) VALUES(2);
INSERT INTO dbo.Tab1(Col1) VALUES(5);
INSERT INTO dbo.Tab1(Col1) VALUES(6);
INSERT INTO dbo.Tab1(Col1) VALUES(7);
INSERT INTO dbo.Tab1(Col1) VALUES(15);
INSERT INTO dbo.Tab1(Col1) VALUES(16);
GO
SELECT * FROM Tab1

-- Resultado esperado Ilhas
/*
  InicioRange FimRange
  ----------- -----------
  1           2
  5           7
  15          16
*/


----------------------------------------
--------- Pedidos por Cliente ----------
----------------------------------------
/*
  Escreva uma consulta que retorne a soma de pedidos por
  cliente.
  Banco: NorthWind
  Tabelas: OrdersBig e CustomersBig
  
  Obs.:
  A consulta deve ser executada no menor tempo possível 
  e fazer a menor quantidade de leituras de páginas possíveis.
  Antes de executar cada consulta um 
  DBCC DROPCLEANBUFFERS e DBCC FREEPROCCACHE
  deve ser executado
*/

-- Exemplo do resultado esperado
/*
  CustomerID  Val
  ----------- ----------
  0           49549.54
  1           61804.19
  2           59250.02
  3           52889.04
  ...
*/

----------------------------------------
--------- Qtde Produtos Vendidos -------
----------------------------------------
/*
  Escreva uma consulta que retorne a soma de
  produtos vendidos, caso um produto não tenha
  nenhuma venda, o valor 0(zero) deverá ser exibido

  Banco: NorthWind
  Tabelas: ProductsBig e Order_DetailsBig
  Retornar as informações de ProductID e ProductName

  Obs.:
  A consulta deve ser executada no menor tempo possível 
  e fazer a menor quantidade de leituras de páginas possíveis.
  Antes de executar cada consulta um 
  DBCC DROPCLEANBUFFERS e DBCC FREEPROCCACHE
  deve ser executado
*/

-- Exemplo do resultado esperado
/*
   ProductID   ProductName                        Val
   ----------- ---------------------------------- -----------
   1000001     Teste Produto                      0
   1000008     Teste Produto                      0
   6581        Nord-Ost Matjeshering 6C8ACD9E     21415
   6374        Mascarpone Fabioli E1B954C8        22076
   14515       Lakkalikööri FDA51D1F              22218
   ...
*/



------------------------------------------
-- Pedidos e Itens de um Range de dada  --
------------------------------------------
/*
  Escreva uma consulta que retorne os dados de
  pedidos e itens baseado em um filtro de datas.
  Exemplo do Filtro a ser utilizado
  WHERE OrdersBig.OrderDate BETWEEN '20110101' AND '20110131'

  Os valores utilizados no filtro são variáveis...

  Banco: NorthWind
  Tabelas: OrdersBig e Order_DetailsBig
  Retornar as informações de OrderID, OrderDate, Shipped_Date e Quantity

  Obs.:
  A consulta deve ser executada no menor tempo possível 
  e fazer a menor quantidade de leituras de páginas possíveis.
  Antes de executar cada consulta um 
  DBCC DROPCLEANBUFFERS e DBCC FREEPROCCACHE
  deve ser executado
*/

-- Exemplo do resultado esperado
/*
  OrderID     OrderDate  Shipped_Date            Quantity
  ----------- ---------- ----------------------- -----------
  50          2011-01-09 2011-01-21 00:00:00.000 1563
  50          2011-01-09 2011-01-13 00:00:00.000 1234
  50          2011-01-09 2011-01-24 00:00:00.000 1577
  50          2011-01-09 2011-01-12 00:00:00.000 1194
  50          2011-01-09 2011-01-12 00:00:00.000 2080
  50          2011-01-09 2011-01-24 00:00:00.000 433
   ...
*/

----------------------------------------
------- Excluir linhas duplicadas ------
----------------------------------------
/*
  Escreva um comando para apagar os tres primeiros pedidos por cliente
*/
USE TempDB
GO
IF OBJECT_ID('tempdb.dbo.#TMP') IS NOT NULL
  DROP TABLE #TMP
GO
CREATE TABLE #TMP(OrderID Int, CustomerID Int, OrderDate DATE)
GO
INSERT INTO #TMP
SELECT OrderID, CustomerID, OrderDate FROM northwind.dbo.Orders
GO
SELECT * FROM #TMP



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

-- Resultado esperado:
/*
  CustomerID  orderdate               orderid     Days since last order
  ----------- ----------------------- ----------- ---------------------
  1           1997-08-25 00:00:00.000 10643       NULL
  1           1997-10-03 00:00:00.000 10692       39
  1           1997-10-13 00:00:00.000 10702       10
  1           1998-01-15 00:00:00.000 10835       94
*/

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
---- Vendas baseado na média mensal ----
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

-- Resultado esperado:
/*
  FirstName  OrderID     OrderDate
  ---------- ----------- -----------------------
  Andrew     11073       1998-05-05 00:00:00.000
  Andrew     11070       1998-05-05 00:00:00.000
  Andrew     11060       1998-04-30 00:00:00.000
  Anne       11058       1998-04-29 00:00:00.000
  Anne       11022       1998-04-14 00:00:00.000
  Anne       11017       1998-04-13 00:00:00.000
  Janet      11063       1998-04-30 00:00:00.000
  Janet      11057       1998-04-29 00:00:00.000
  Janet      11052       1998-04-27 00:00:00.000
  Laura      11075       1998-05-06 00:00:00.000
  ...
*/

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

;WITH CTE1
AS
(
SELECT SubString(String, 1,1) AS FirstLetter,
       CASE 
         WHEN SubString(REPLACE(String, SubString(String, 1,1),''),1,1) = '' THEN SubString(String, 1,1)
         ELSE SubString(REPLACE(String, SubString(String, 1,1),''),1,1)
       END AS SecondLetter,
       Len(String) Len,
       String
  FROM TC46
),
CTE2
AS
(
SELECT FirstLetter,
       SecondLetter,
       CASE 
         WHEN CharIndex(SecondLetter, String) = 1 THEN Len
         ELSE CharIndex(SecondLetter, String) 
       END AS PosSecondCaracther,
       Len,
       String
  FROM CTE1
)
SELECT String,
       SubString(String, PosSecondCaracther, Len) AS Result
  FROM CTE2
 ORDER BY Result

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
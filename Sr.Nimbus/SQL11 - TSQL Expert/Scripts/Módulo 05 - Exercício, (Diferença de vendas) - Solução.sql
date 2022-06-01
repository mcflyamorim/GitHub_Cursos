/*
  Sr.Nimbus - T-SQL Expert
        Query Tuning 
         Exercícios
  http://www.srnimbus.com.br
*/

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
  Ano         VendasNoAnoAtual  VendasNoAnoAnterior  %Diff
  ----------- --------------    -------------------  --------
  1996        9410.20           0.00                 100.000000
  1997        27615.08          9410.20              65.923700
  1998        19475.63          27615.08             -41.792900
*/

-- Resultado esperado por ano/mês
/*
  Ano   Mês     VendasMesAtual  VendasMesAnterior %Diff
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


-- Resposta
SELECT YEAR(OrderDate) AS Ano,
       SUM(Value) AS VendasNoAnoAtual,
       LAG(SUM(Value), 1, 0) OVER(ORDER BY YEAR(OrderDate)) AS VendasNoAnoAnterior,
       IIF(100 - (LAG(SUM(Value), 1, 0) OVER(ORDER BY YEAR(OrderDate)) / SUM(Value)) * 100 = 100, 
           0,
           100 - (LAG(SUM(Value), 1, 0) OVER(ORDER BY YEAR(OrderDate)) / SUM(Value)) * 100) AS "%Diff"
  FROM Orders
 GROUP BY YEAR(OrderDate)
GO

WITH CTE_1
AS
(
SELECT YEAR(OrderDate) AS Ano,
       MONTH(OrderDate) AS Mes,
       SUM(Value) AS VendasMesAtual,
       LAG(SUM(Value), 1, 0) OVER(PARTITION BY MONTH(OrderDate) ORDER BY MONTH(OrderDate), YEAR(OrderDate)) AS VendasMesAnterior,
       CONVERT(Numeric(18,2), 100 - (LAG(SUM(Value), 1, 0) OVER(PARTITION BY MONTH(OrderDate) ORDER BY MONTH(OrderDate), YEAR(OrderDate)) / SUM(Value)) * 100) AS "%Diff"
  FROM Orders
 GROUP BY MONTH(OrderDate), YEAR(OrderDate)
)
SELECT Ano, Mes, VendasMesAtual, VendasMesAnterior,
       CASE "%Diff"
         WHEN 100.00 THEN 0
         ELSE "%Diff"
       END "%Diff"
  FROM CTE_1
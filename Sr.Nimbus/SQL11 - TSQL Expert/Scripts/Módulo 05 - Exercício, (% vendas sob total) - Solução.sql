/*
  Sr.Nimbus - T-SQL Expert
        Query Tuning 
         Exercícios
  http://www.srnimbus.com.br
*/
----------------------------------------
--------- % vendas sob total -----------
----------------------------------------
/*
  Escreva uma consulta que retorne todos os pedidos
  e o percentual de vendas que o pedido representa sob o total geral
  
  Escreva outra consulta que retorne todos os pedidos
  e o percentual de vendas que o pedido representa sob o total do 
  cliente

  Banco: NorthWind
  Tabela: Orders

  Obs.: Escrever consulta que rode no SQL2005
*/

-- Resultado esperado:
/*
  OrderID     Value      % baseado no total de vendas
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
  CustomerID  Total por cliente    % baseado no total geral
  ----------- -------------------- ---------------------------------------
  63          2739.95              4.85
  71          2679.66              4.74
  20          2666.67              4.72
  65          2182.90              3.86
  37          1719.86              3.04
  5           1425.65              2.52
*/


-- Resposta

SELECT OrderID,
       Value,
       --SUM(Value) OVER() AS "Sales Total", -- Optional column
       CONVERT(Numeric(18,2) ,Value / (SUM(Value) OVER()) * 100) "% baseado no total de vendas"
  FROM Orders
ORDER BY Value DESC
GO


SELECT DISTINCT 
       CustomerID,
       --SUM(Value) OVER() AS "Sales total", -- Optional column
       SUM(Value) OVER(PARTITION BY CustomerID) AS "Total por Cliente",
       CONVERT(Numeric(18,2) , (SUM(Value) OVER(PARTITION BY CustomerID)) / (SUM(Value) OVER()) * 100) "% baseado no total geral"
  FROM Orders
ORDER BY "% baseado no total geral" DESC
/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE NorthWind
GO

/*
  Segment
*/

-- DROP INDEX [ix_ProductID INCLUDE(OrderID, Quantidade, Data_Entrega)] ON Order_Details
CREATE INDEX [ix_ProductID INCLUDE(OrderID, Quantidade, Data_Entrega)] ON Order_Details(ProductID) INCLUDE(OrderID, Quantidade, Data_Entrega)
GO

/*
  Consulta para retornar o último pedido por produto  
*/
SELECT Products.ProductName, 
       MAX(Order_Details.OrderID) AS Ultimo_Pedido
  FROM Order_Details
 INNER JOIN Products
    ON Order_Details.ProductID = Products.ProductID
 GROUP BY Products.ProductName
GO

/*
  Se eu quiser ver o Value das colunas Data_Entrega e Quantidade
  relacionado ao último pedido. Basta incluir as colunas no select?
*/
SELECT Products.ProductName, 
       MAX(Order_Details.OrderID) AS Ultimo_Pedido,
       Order_Details.Data_Entrega,
       Order_Details.Quantidade
  FROM Order_Details
 INNER JOIN Products
    ON Order_Details.ProductID = Products.ProductID
 GROUP BY Products.ProductName
GO

/*
  Para fazer a consulta acima funcionar eu preciso incluir as 
  colunas Data_Entrega e Quantidade no GroupBy.
  Mas ao fazer isso temos como resultado dados incorretos.
*/
SELECT Products.ProductName,
       MAX(Order_Details.OrderID) AS Ultimo_Pedido,
       Order_Details.Data_Entrega,
       Order_Details.Quantidade
  FROM Order_Details
 INNER JOIN Products
    ON Order_Details.ProductID = Products.ProductID
 GROUP BY Products.ProductName,
          Order_Details.Data_Entrega,
          Order_Details.Quantidade
GO

/*
  Para retornar os dados conforme desejado, precisamos criar uma SubQuery
  com os dados Agrupados por ProductID e depois fazer um join com esta SubQuery
  Porém, isso faz com que leiamos a tabela Order_Details duas vezes. Certo?
  Veja no plano de execução se ele leu a tabela duas vezes.
  
  Podemos ver que o QO utilizou um plano bem simples para resolver a consulta.
  Este plano utiliza o operador Segment:
  
  Entendendo Operador Segment:
  
  Para entender o operador vamos entender melhor nossa consulta.
  O que estamos solicitando na consulta é o seguinte:
  
  1 - Agrupar os Order_Details vendidos por Produto
  2 - Retornar o Maior Value da coluna OrderID para cada grupo (segmento) de Produto
  3 - Retornar a Data_Entrega e a Quantidade para este último Pedido  
  
  Entendendo isso, o QO gera um plano com operador Segment mais operador de TOP.
  O Segment tem uma propriedade GROUP BY que diz qual coluna os dados são agrupados.
  Como os dados são lidos na ordem do índice, o segment le os dados do índice cluster
  e passa para o TOP que retorna apenas o maior(MAX) Value de cada grupo.
  O segment passa uma coluna de controle para o TOP, normalmente chamada [Segment1003].
  Esta coluna controla quando o Value mudou.
  Pergunta. E se eu tiver um empate, por ex: Tenho dois Orders com o mesmo OrderID
  e os dois são os maiores. Neste caso o TOP não pode simplesmente pegar o TOP 1 DESC.
  Para resolver este problema ele roda o TOP como WITH TIES, ou seja, se os 
  Valuees duplicarem todos serão retornados. Podemos ver isso ao clicar com o botão
  direito do mouse no operador TOP, propriedade WITH TIES = TRUE.
  
  Nota: No SQL Serve 2005 o SQL Não usou o segment :-(  
*/ 
SELECT Products.ProductName,
       Tab.Max_Pedido,
       Order_Details.Data_Entrega,
       Order_Details.Quantidade
  FROM Order_Details
 INNER JOIN (SELECT ProductID,
                    MAX(OrderID) AS Max_Pedido
               FROM Order_Details
              GROUP BY ProductID) AS Tab
    ON Order_Details.ProductID = Tab.ProductID
   AND Order_Details.OrderID = Tab.Max_Pedido
  INNER JOIN Products
    ON Order_Details.ProductID = Products.ProductID
GO

/*
  Para visualizarmos o comportamento sem o operador Segment
  podemos desabilitar a otimização que gera o Segment.
  "Generate Group By Apply Simple"
  Desabilitando a regra vemos que o SQL lê a tabela Order_Details duas vezes
*/
DBCC TRACEON (3604);
DBCC RULEOFF('GenGbApplySimple');
GO
SELECT Products.ProductName,
       Tab.Max_Pedido,
       Order_Details.Data_Entrega,
       Order_Details.Quantidade
  FROM Order_Details
 INNER JOIN (SELECT ProductID,
                    MAX(OrderID) AS Max_Pedido
               FROM Order_Details
              GROUP BY ProductID) AS Tab
    ON Order_Details.ProductID = Tab.ProductID
   AND Order_Details.OrderID = Tab.Max_Pedido
  INNER JOIN Products
    ON Order_Details.ProductID = Products.ProductID
OPTION (RECOMPILE)
GO
DBCC RULEON('GenGbApplySimple');
GO

/*
  Outra forma de escrever esta consulta seria utilizando
  a windows function DENSE_RANK() particionando os dados por ID_Grupo.
  Porque não a RANK_NUMER()?
  Porque precisamos controlar o TIES lembra? Se os Valuees repetirem
  precisamos retornar os dados mais de uma vez.
*/

SELECT Products.ProductName,
       OrderID AS Max_Pedido,
       Data_Entrega,
       Quantidade
  FROM (SELECT ProductID,
               OrderID,
               Data_Entrega,
               Quantidade,
               DENSE_RANK() OVER(PARTITION BY ProductID ORDER BY OrderID DESC) AS rn
          FROM Order_Details) AS Tab
 INNER JOIN Products
    ON Tab.ProductID = Products.ProductID
 WHERE Tab.rn = 1
GO
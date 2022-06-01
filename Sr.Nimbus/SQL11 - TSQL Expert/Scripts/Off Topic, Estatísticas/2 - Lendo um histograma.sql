/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

/*
  Visualizando Estatísticas
*/

IF EXISTS(SELECT * FROM sys.stats WHERE Name = 'Stats_Quantity' AND object_id = OBJECT_ID('Order_DetailsBig'))
BEGIN
  DROP STATISTICS Order_DetailsBig.Stats_Quantity
END
GO
CREATE STATISTICS Stats_Quantity ON Order_DetailsBig(Quantity) WITH FULLSCAN
GO

DBCC SHOW_STATISTICS (Order_DetailsBig, Stats_Quantity) WITH HISTOGRAM
GO
/*  
  RANGE_HI_KEY RANGE_ROWS    EQ_ROWS       DISTINCT_RANGE_ROWS  AVG_RANGE_ROWS
  ------------ ------------- ------------- -------------------- --------------
  0	           0	            465	          0	                   1
  9	           3759	         499	          8	                   469,875
  16	          2790	         478	          6	                   465
  39	          10188	        443	          22	                  463,0909
  47	          3209	         516	          7	                   458,4286
  70	          10146	        434	          22	                  461,1818
  77	          2721	         483	          6	                   453,5
  88	          4594	         493	          10	                  459,4
  106	         7861	         444	          17	                  462,4118
*/
/*
  Consultando o valor 50 no histograma da estatística Stats_Quantity
  Nota: OPTION(RECOMPILE) para evitar parametrização
*/
SELECT * FROM Order_DetailsBig
WHERE Quantity = 50
OPTION(RECOMPILE)
/*
  Estimated number of Rows 461,182
  O Valor 50 não existe no histograma, ele esta entre as chaves
  47 e 70.
  Para o sinal de igualdade, o SQL Utiliza a média de linhas entre
  o range (coluna AVG_RANGE_ROWS) ou seja, 461,1818
*/


/*
  Consultando os Order_DetailsBig com Quantity menor que 39
*/
SELECT * FROM Order_DetailsBig
WHERE Quantity < 39
OPTION(RECOMPILE)
/*
  Estimated number of Rows 18179
  Somar os valores das colunas RANGE_ROWS	e EQ_ROWS
  até chegar na amostra com o valor 39.
  Para a amostra do 39 não podemos somar a coluna EQ_ROWS
  pois estamos consultando valores MENOR QUE 39, ou seja, < 39
  Por isso não podemos ler a EQ_ROWS, pois ela contem a Quantity 
  de linhas para o valor 39.
  Portanto somamos, 0 + 465 + 3759 + 499 + 2790 + 478 + 10188 = 18179
*/

/*
  Consultando os Order_DetailsBig com Quantity menor ou igual a 39
*/
SELECT * FROM Order_DetailsBig
WHERE Quantity <= 39
OPTION(RECOMPILE)
/*
  Estimated number of Rows 18622
  Somar os valores das colunas RANGE_ROWS	e EQ_ROWS
  até chegar na amostra com o valor 107.
  Portanto somamos,  0 + 465 + 3759 + 499 + 2790 + 478 + 10188 + 443 = 18622
*/
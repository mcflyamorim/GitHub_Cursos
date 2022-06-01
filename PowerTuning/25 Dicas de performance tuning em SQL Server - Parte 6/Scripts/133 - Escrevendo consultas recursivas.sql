USE Northwind
GO

-- Recursividade
WITH Hierarquia AS
(
  -- 1º SELECT: âncora – início da recursão
  SELECT	EmployeeID, 
         CONVERT(VarChar(MAX), FirstName + ' ' + LastName) AS Nome, 
         NivelHierarquico = 1
	   FROM Employees
	  WHERE ReportsTo IS NULL	
   UNION ALL	
  -- 2º SELECT: recursivo – gera linhas a partir da linha âncora, e 
  -- depois gera linhas para cada linha gerada na execução anterior
  SELECT E.EmployeeID, 
         CONVERT(VarChar(MAX), REPLICATE('----', NivelHierarquico + 1) + FirstName + ' ' + LastName) AS Nome,
         NivelHierarquico + 1
    FROM Hierarquia H 
   INNER JOIN Employees E
      ON H.EmployeeID = E.ReportsTo
)
SELECT * FROM Hierarquia



-- Criando uma tabela de sequencial usando recursividade
WITH Sequencial AS
(
  SELECT 1 as ID
   UNION ALL
  SELECT ID + 1
    FROM Sequencial
   WHERE ID < 100
)
SELECT * 
  FROM Sequencial
--OPTION (MAXRECURSION 32767)




-- BONUS, Query que escrevi pro meu irmão semana passada... :-( 
-- CTE não era uma opção...
-------------------------

SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, REPLICATE('  ', 0) + p1.cod_unid_lotac_filho, Nivel = 0
  FROM pub.estrut_plano_lotac AS p1
 WHERE cod_unid_lotac_pai = '' 
   AND cdn_plano_lotac = 40

 UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) + p2.cod_unid_lotac_filho, Nivel
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 1
               FROM pub.estrut_plano_lotac AS p1
              WHERE cod_unid_lotac_pai = '' 
                AND cdn_plano_lotac = 40) AS Nivel1
    ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho

 UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) +  p2.cod_unid_lotac_filho, Nivel
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel1.Nivel
               FROM pub.estrut_plano_lotac AS p2
              INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 2
                            FROM pub.estrut_plano_lotac AS p1
                           WHERE cod_unid_lotac_pai = '' 
                             AND cdn_plano_lotac = 40) AS Nivel1
                 ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho) AS Nivel2
    ON p2.cod_unid_lotac_pai  = Nivel2.cod_unid_lotac_filho

UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) + p2.cod_unid_lotac_filho, Nivel 
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel2.Nivel
               FROM pub.estrut_plano_lotac AS p2
              INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel1.Nivel
                            FROM pub.estrut_plano_lotac AS p2
                           INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 3
                                         FROM pub.estrut_plano_lotac AS p1
                                        WHERE cod_unid_lotac_pai = '' 
                                          AND cdn_plano_lotac = 40) AS Nivel1
                              ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho) AS Nivel2
                 ON p2.cod_unid_lotac_pai  = Nivel2.cod_unid_lotac_filho) AS Nivel3
    ON p2.cod_unid_lotac_pai  = Nivel3.cod_unid_lotac_filho

UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) + p2.cod_unid_lotac_filho, Nivel 
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
               FROM pub.estrut_plano_lotac AS p2
              INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel2.Nivel
                            FROM pub.estrut_plano_lotac AS p2
                           INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel1.Nivel
                                         FROM pub.estrut_plano_lotac AS p2
                                        INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 4
                                                      FROM pub.estrut_plano_lotac AS p1
                                                     WHERE cod_unid_lotac_pai = '' 
                                                       AND cdn_plano_lotac = 40) AS Nivel1
                                           ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho) AS Nivel2
                              ON p2.cod_unid_lotac_pai  = Nivel2.cod_unid_lotac_filho) AS Nivel3
                 ON p2.cod_unid_lotac_pai  = Nivel3.cod_unid_lotac_filho) AS Nivel4
    ON p2.cod_unid_lotac_pai  = Nivel4.cod_unid_lotac_filho

UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) + p2.cod_unid_lotac_filho, Nivel 
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
               FROM pub.estrut_plano_lotac AS p2
              INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
                            FROM pub.estrut_plano_lotac AS p2
                           INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel2.Nivel
                                         FROM pub.estrut_plano_lotac AS p2
                                        INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel1.Nivel
                                                      FROM pub.estrut_plano_lotac AS p2
                                                     INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 5
                                                                   FROM pub.estrut_plano_lotac AS p1
                                                                  WHERE cod_unid_lotac_pai = '' 
                                                                    AND cdn_plano_lotac = 40) AS Nivel1
                                                        ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho) AS Nivel2
                                           ON p2.cod_unid_lotac_pai  = Nivel2.cod_unid_lotac_filho) AS Nivel3
                              ON p2.cod_unid_lotac_pai  = Nivel3.cod_unid_lotac_filho) AS Nivel4
                 ON p2.cod_unid_lotac_pai  = Nivel4.cod_unid_lotac_filho) AS Nivel5
    ON p2.cod_unid_lotac_pai  = Nivel5.cod_unid_lotac_filho

UNION ALL

SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, REPLICATE('  ', Nivel) + p2.cod_unid_lotac_filho, Nivel 
  FROM pub.estrut_plano_lotac AS p2
 INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
               FROM pub.estrut_plano_lotac AS p2
              INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
                            FROM pub.estrut_plano_lotac AS p2
                           INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel 
                                         FROM pub.estrut_plano_lotac AS p2
                                        INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel2.Nivel
                                                      FROM pub.estrut_plano_lotac AS p2
                                                     INNER JOIN (SELECT p2.cdn_plano_lotac, p2.cod_unid_lotac_pai, p2.num_seq_estrut_plano_lotac, p2.cod_unid_lotac_filho, Nivel = Nivel1.Nivel
                                                                   FROM pub.estrut_plano_lotac AS p2
                                                                  INNER JOIN (SELECT p1.cdn_plano_lotac, p1.cod_unid_lotac_pai, p1.num_seq_estrut_plano_lotac, p1.cod_unid_lotac_filho, Nivel = 6
                                                                                FROM pub.estrut_plano_lotac AS p1
                                                                               WHERE cod_unid_lotac_pai = '' 
                                                                                 AND cdn_plano_lotac = 40) AS Nivel1
                                                                     ON p2.cod_unid_lotac_pai  = Nivel1.cod_unid_lotac_filho) AS Nivel2
                                                        ON p2.cod_unid_lotac_pai  = Nivel2.cod_unid_lotac_filho) AS Nivel3
                                           ON p2.cod_unid_lotac_pai  = Nivel3.cod_unid_lotac_filho) AS Nivel4
                              ON p2.cod_unid_lotac_pai  = Nivel4.cod_unid_lotac_filho) AS Nivel5
                 ON p2.cod_unid_lotac_pai  = Nivel5.cod_unid_lotac_filho) AS Nivel6
    ON p2.cod_unid_lotac_pai  = Nivel6.cod_unid_lotac_filho

ORDER BY 2, 4


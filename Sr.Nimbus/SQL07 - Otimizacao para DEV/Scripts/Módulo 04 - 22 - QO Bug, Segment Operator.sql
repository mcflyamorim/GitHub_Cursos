/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


USE tempdb
GO
IF OBJECT_ID('tempdb.dbo.#Tab1') IS NOT NULL
  DROP TABLE #Tab1
GO
CREATE TABLE #Tab1(Col1 INT NOT NULL,
                   Col2 INT NOT NULL,
                   Col3 INT NOT NULL,
                   PRIMARY KEY (Col1, Col2, Col3))
GO

/*
  Incluir alguns registros para testes.
  As colunas Col1 e Col2 tem os mesmo Valuees.
*/
INSERT #Tab1 (Col1, Col2, Col3)
VALUES(1, 1, 1),
      (1, 1, 2),
      (2, 2, 1),
      (2, 2, 2),
      (3, 3, 1),
      (3, 3, 2),
      (4, 4, 1),
      (4, 4, 2);
GO

-- Dados da tabela
SELECT * FROM #Tab1
GO

/*
  Retornar apenas os registros com o maior Value da Col3 para um 
  mesmo grupo (Col1 + Col2) de linhas.
  Com o operador Segment + TOP o SQL retorna os dados de Col1, Col2 e Col3
  apenas do MAX de Col3.
  Com esta otimizaçõa ele evita acessar a tabela duas vezes.
*/
SELECT a.*
  FROM #Tab1 a
 WHERE a.Col3 = (SELECT MAX(b.Col3)
                   FROM #Tab1 b
                  WHERE b.Col1 = a.Col1
                    AND b.Col2 = a.Col2)
GO

/*
  Pergunta. A ordem das colunas no JOIN/WHERE muda alguma coisa?
  No caso da otimização do Segment Sim. :-(
*/
SELECT a.*
  FROM #Tab1 a
 WHERE a.Col3 = (SELECT MAX(b.Col3)
                   FROM #Tab1 b
                  WHERE b.Col2 = a.Col2
                    AND b.Col1 = a.Col1)
GO

-- Connect Item: https://connect.microsoft.com/SQLServer/feedback/details/432488/query-optimizer-may-not-choose-plan-involving-segment-iterator-depending-on-predicate-order#details
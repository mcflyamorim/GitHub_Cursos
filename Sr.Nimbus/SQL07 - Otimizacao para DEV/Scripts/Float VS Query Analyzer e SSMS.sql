/*
  Sr.Nimbus - SQL07 - Otimizacao para DEV
  http://www.srnimbus.com.br
*/


SELECT CONVERT(Float, 2.55), CONVERT(Float, 2.54)

DECLARE  @Sample TABLE
         (
             a DECIMAL(38, 19),
             b FLOAT
         )

INSERT   @Sample
         (
             a,
             b
         )
VALUES   (1E / 7E, 1E / 7E)

SELECT   *
FROM     @Sample

-- Executar os mesmos comandos no Query Analyzer
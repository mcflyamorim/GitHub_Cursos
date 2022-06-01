/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-- German tank problem

USE tempdb
GO
IF OBJECT_ID('tempdb.dbo.#Tanques_Fabricados') IS NOT NULL
  DROP TABLE #Tanques_Fabricados
GO
CREATE TABLE #Tanques_Fabricados (ID Int IDENTITY(1,1))
GO
DECLARE @i Int = 0
WHILE @i < 50
BEGIN
  INSERT INTO #Tanques_Fabricados DEFAULT VALUES
  SET @i += 1;
END

--SELECT * FROM #Tanques_Fabricados
GO

/*
  Fórmula:
  (@Qtde_Amostras - 1) * (@Maior_Valor +1) / @Maior_Valor
*/

IF OBJECT_ID('tempdb.dbo.#Tanques_Capturados') IS NOT NULL
  DROP TABLE #Tanques_Capturados
GO
CREATE TABLE #Tanques_Capturados (ID Int)
GO

DECLARE @Qtde_Amostras Int,
        @Maior_Valor Int,
        @i Int = 0

-- Pegar N amostras
SELECT TOP 1 @Qtde_Amostras = ID
  FROM #Tanques_Fabricados
 ORDER BY NEWID()

WHILE @i < 5
BEGIN
  INSERT INTO #Tanques_Capturados (ID)
  SELECT TOP 1 ID FROM #Tanques_Fabricados ORDER BY NEWID()
  SET @i += 1;
END
SELECT * FROM #Tanques_Capturados
SELECT @Maior_Valor = MAX(ID)
  FROM #Tanques_Capturados

SELECT @Qtde_Amostras AS Qtde_Amostras, 
       @Maior_Valor AS MaiorValor,
       ((@Maior_Valor - 1) * (@Qtde_Amostras + 1)) / @Qtde_Amostras AS Resultado

-- Testes em massa
IF OBJECT_ID('tempdb.dbo.#Testes') IS NOT NULL
  DROP TABLE #Testes
GO
CREATE TABLE #Testes (Qtde_Amostras Int, Maior_Valor Int, Resultado_Estimado Int)
GO

DECLARE @Qtde_Amostras Int = 0,
        @Maior_Valor Int = 0,
        @i Int = 0

TRUNCATE TABLE #Tanques_Capturados

-- Pegar N amostras
SELECT TOP 1 @Qtde_Amostras = ID
  FROM #Tanques_Fabricados
 ORDER BY NEWID()

WHILE @i < @Qtde_Amostras
BEGIN
  INSERT INTO #Tanques_Capturados (ID)
  SELECT TOP 1 ID FROM #Tanques_Fabricados 
  WHERE NOT EXISTS(SELECT 1 FROM #Tanques_Capturados WHERE #Tanques_Capturados.ID = #Tanques_Fabricados.ID)
  ORDER BY NEWID()
  SET @i += 1;
END

SELECT @Maior_Valor = MAX(ID), @Qtde_Amostras = COUNT(*)
  FROM #Tanques_Capturados
INSERT INTO #Testes
SELECT @Qtde_Amostras AS Qtde_Amostras, 
       @Maior_Valor AS MaiorValor,
       ((@Maior_Valor - 1) * (@Qtde_Amostras + 1)) / @Qtde_Amostras AS Resultado
GO 1000

SELECT * FROM #Testes
GO

-- Considerando margem de erro de 5 tanques
SELECT COUNT(*) AS Qtde_Acertos
  FROM #Testes
 WHERE Resultado_Estimado BETWEEN 45 AND 55
GO
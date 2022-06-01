/*
  use master
  GO
  ALTER DATABASE Dica151 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Dica151

  RESTORE DATABASE [Dica151] FROM DISK = N'D:\Fabiano\Trabalho\FabricioLima\Cursos\25 Dicas de performance tuning em SQL Server - Parte 7\Scripts\Dica151.bak' 
  WITH  FILE = 1, MOVE N'ClearTraceFabiano' TO N'C:\DBs\Dica151.mdf',  
                  MOVE N'ClearTraceFabiano_log' TO N'C:\DBs\Dica151_log.ldf',  
  NOUNLOAD,  STATS = 5
*/
USE Dica151
GO

-- Utilizar COMPATIBILITY_LEVEL = SQL2014
ALTER DATABASE [Dica151] SET COMPATIBILITY_LEVEL = 120
GO
-- Vamos usar o LEGACY_CARDINALITY_ESTIMATION
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = ON;
GO


-- Vamos começar atualizando as estatísticas pra não ter erro, certo?... 
-- Aproximadamente 45 segundos pra rodar
EXECUTE master.dbo.IndexOptimize
@Databases = 'Dica151',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = NULL,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'N',
@LogToTable = 'Y'
GO


-- Estimativas horríveis
-- Ver linhas estimadas vs atuais
-- Estimativa horrível de linhas que serão retornadas estimado = 13883700, atual = 784
-- Resultado do join entre Tabelas FATURAMENTO_CAIXAS, FATURAMENTO_PROD e FATURAMENTO
---- Estimado 24225700 Atual = 6036596 
-- Aproximadamente 12 segundos pra rodar
SELECT C.CAIXA,
       A.FILIAL,
       A.NF_SAIDA,
       A.SERIE_NF,
       A.NOME_CLIFOR
FROM FATURAMENTO A
    INNER JOIN FATURAMENTO_PROD B
        ON A.NF_SAIDA = B.NF_SAIDA
           AND A.SERIE_NF = B.SERIE_NF
           AND A.FILIAL = B.FILIAL
    INNER JOIN FATURAMENTO_CAIXAS C
        ON B.CAIXA = C.CAIXA
    INNER JOIN CADASTRO_CLI_FOR D
        ON D.NOME_CLIFOR = A.NOME_CLIFOR
WHERE A.STATUS_NFE = 5
      AND C.NOME_CLIFOR_DESTINO_FINAL IS NOT NULL
      AND C.NOME_CLIFOR_DESTINO_FINAL <> C.NOME_CLIFOR
      AND D.UF = 'SP'
      AND C.CHAVE_NFE IS NULL
      AND B.PEDIDO IS NOT NULL
GROUP BY C.CAIXA,
         A.FILIAL,
         A.NF_SAIDA,
         A.SERIE_NF,
         A.NOME_CLIFOR
OPTION (RECOMPILE, MAXDOP 1);
GO


-- Isolando o joins entre as tabelas pra entender melhor o problema
-- Quantas linhas o QO está estimando que serão retornadas?
-- R. 21447900
SELECT C.CAIXA,
       A.FILIAL,
       A.NF_SAIDA,
       A.SERIE_NF,
       A.NOME_CLIFOR
FROM FATURAMENTO A
    INNER JOIN FATURAMENTO_PROD B
        ON A.NF_SAIDA = B.NF_SAIDA
           AND A.SERIE_NF = B.SERIE_NF
           AND A.FILIAL = B.FILIAL
    INNER JOIN FATURAMENTO_CAIXAS C
        ON B.CAIXA = C.CAIXA
WHERE A.STATUS_NFE = 5
      AND C.NOME_CLIFOR_DESTINO_FINAL IS NOT NULL
      AND C.NOME_CLIFOR_DESTINO_FINAL <> C.NOME_CLIFOR
      AND C.CHAVE_NFE IS NULL
      AND B.PEDIDO IS NOT NULL
GROUP BY C.CAIXA,
         A.FILIAL,
         A.NF_SAIDA,
         A.SERIE_NF,
         A.NOME_CLIFOR
OPTION (RECOMPILE, MAXDOP 1);
GO

-- E se eu atualizar as estatísticas com FULLSCAN? 
-- Ajuda?

-- Aproximadamente 28 minutos pra rodar
EXECUTE master.dbo.IndexOptimize
@Databases = 'Dica151',
@FragmentationLow = NULL,
@FragmentationMedium = NULL,
@FragmentationHigh = NULL,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'N',
@StatisticsSample = 100,
@LogToTable = 'Y'
GO


-- E agora, melhorou? 
-- Estimativas ainda ruins, porem está mais rápido...
-- Média de 1.4 segundo pra rodar
SELECT C.CAIXA,
       A.FILIAL,
       A.NF_SAIDA,
       A.SERIE_NF,
       A.NOME_CLIFOR
FROM FATURAMENTO A
    INNER JOIN FATURAMENTO_PROD B
        ON A.NF_SAIDA = B.NF_SAIDA
           AND A.SERIE_NF = B.SERIE_NF
           AND A.FILIAL = B.FILIAL
    INNER JOIN FATURAMENTO_CAIXAS C
        ON B.CAIXA = C.CAIXA
    INNER JOIN CADASTRO_CLI_FOR D
        ON D.NOME_CLIFOR = A.NOME_CLIFOR
WHERE A.STATUS_NFE = 5
      AND C.NOME_CLIFOR_DESTINO_FINAL IS NOT NULL
      AND C.NOME_CLIFOR_DESTINO_FINAL <> C.NOME_CLIFOR
      AND D.UF = 'SP'
      AND C.CHAVE_NFE IS NULL
      AND B.PEDIDO IS NOT NULL
GROUP BY C.CAIXA,
         A.FILIAL,
         A.NF_SAIDA,
         A.SERIE_NF,
         A.NOME_CLIFOR
OPTION (RECOMPILE, MAXDOP 1);
GO


-- Ummm, garantir um FULL update stats nem sempre é possível... isso pode demorar e consumir recurso
-- considerável... 

-- Como "ajudar" o otimizador com essas estimativas ruins? 
-- Fazer os joins "em partes" usando tabelas temporárias é uma opção...
-- Por exemplo:


-- Média de 100ms pra rodar
IF OBJECT_ID('tempdb.dbo.#tmp1') IS NOT NULL
    DROP TABLE #tmp1;

SELECT C.CAIXA
INTO #tmp1
FROM FATURAMENTO_CAIXAS C  
WHERE C.NOME_CLIFOR_DESTINO_FINAL IS NOT NULL
      AND C.NOME_CLIFOR_DESTINO_FINAL <> C.NOME_CLIFOR
      AND C.CHAVE_NFE IS NULL
OPTION (MAXDOP 1);

IF OBJECT_ID('tempdb.dbo.#tmp2') IS NOT NULL
    DROP TABLE #tmp2;

SELECT C.CAIXA, B.NF_SAIDA, B.SERIE_NF, B.FILIAL 
INTO #tmp2
FROM FATURAMENTO_PROD B
INNER JOIN #tmp1 C
    ON B.CAIXA = C.CAIXA
WHERE B.PEDIDO IS NOT NULL
OPTION (MAXDOP 1);

SELECT C.CAIXA,
       A.FILIAL,
       A.NF_SAIDA,
       A.SERIE_NF,
       A.NOME_CLIFOR
FROM FATURAMENTO A  
    INNER JOIN #tmp2 B  
        ON A.NF_SAIDA = B.NF_SAIDA
           AND A.SERIE_NF = B.SERIE_NF
           AND A.FILIAL = B.FILIAL
    INNER JOIN #tmp1 C  
        ON B.CAIXA = C.CAIXA
    INNER JOIN CADASTRO_CLI_FOR D  
        ON D.NOME_CLIFOR = A.NOME_CLIFOR
WHERE A.STATUS_NFE = 5
      AND D.UF = 'SP'
GROUP BY C.CAIXA,
         A.FILIAL,
         A.NF_SAIDA,
         A.SERIE_NF,
         A.NOME_CLIFOR
OPTION (MAXDOP 1);
GO


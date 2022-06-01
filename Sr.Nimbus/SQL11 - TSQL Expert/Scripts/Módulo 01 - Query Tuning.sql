/*
  Sr.Nimbus - T-SQL Expert
         Módulo 01
  http://www.srnimbus.com.br
*/

----------------------------------------
------------- Profiler -----------------
----------------------------------------

-- Functions para analise/gerenciamento dos traces rodando no servidor
-- Start
sp_trace_setstatus @traceid =  2, @status = 1
-- Stop
sp_trace_setstatus @traceid =  2, @status = 0
-- Delete
sp_trace_setstatus @traceid =  2, @status = 2
GO

-- Retorna informações de todos os traces que estão rodando no servidor
SELECT * FROM ::fn_trace_getinfo(DEFAULT)

-- Le os dados a partir de um arquivo de trace (.trc)
SELECT * FROM fn_trace_gettable('C:\MeuArquivoDeTrace.trc', default) AS TabTrace


----------------------------------------
------------- PerfMon ------------------
----------------------------------------

-- Retorna uma linha para cada contador do servidor SQL Server
SELECT * FROM sys.dm_os_performance_counters


----------------------------------------
--------------- DMVs -------------------
----------------------------------------

-- Retorna dados sobre acesso aos arquivos dos bancos de dados
SELECT * FROM sys.dm_io_virtual_file_stats(NULL, NULL)

-- Uso dos índices
SELECT * FROM sys.dm_db_index_usage_stats

sp_whoisactive
----------------------------------------
--------------- DEBUG ------------------
----------------------------------------
IF OBJECT_ID('fn_SomenteTexto', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_SomenteTexto
GO
CREATE FUNCTION dbo.fn_SomenteTexto(@Str       VarChar(8000),
                                    @SN_Numero Char(1))
RETURNS VarChar(8000)
BEGIN
  DECLARE @I     Smallint,
          @Str_2 VarChar(8000),
          @Str_3 VarChar(8000);
  
  SELECT @I     = 0,
         @Str_2 = @Str,
         @Str_3 = '';
  
  IF @SN_Numero = ''
  BEGIN
    SET @SN_Numero = 'N'
  END
  
  WHILE @I <= Len(@Str_2)
  BEGIN
    IF (SubString(@Str_2, @i, 1) LIKE '[A-Z]')
    OR ((SubString(@Str_2, @i, 1) LIKE '[0-9]') AND (@SN_Numero = 'S'))
    BEGIN
      SET @Str_3 = @Str_3 + SubString(@Str_2, @i, 1);
    END
    ELSE BEGIN
      SET @Str_3 = @Str_3 + ''; -- Caracter que vai substituir o texto
    END

    SET @I = @I + 1
  END

  SET @Str_3 = REPLACE(REPLACE(REPLACE(@Str_3, '   ', ' '), '   ', ' '), '  ', ' ');
  SET @Str_3 = LTRIM(RTRIM(@Str_3));

  RETURN(@Str_3);
END
GO
/*
  SELECT dbo.fn_SomenteTexto('ASD****123', 'N')
  SELECT dbo.fn_SomenteTexto('ASD****123', 'S')
*/
IF OBJECT_ID('TestDebug', 'P') IS NOT NULL
  DROP PROC TestDebug
GO
CREATE PROCEDURE dbo.TestDebug @Texto VarChar(200)
AS
BEGIN
  DECLARE @i Int

  IF dbo.fn_SomenteTexto(@Texto, 'N') <> @Texto
  BEGIN
    RAISERROR ('Valor informado na variável de entrada não é permitido!', 16, 0)
  END
  --...
END
GO

EXEC dbo.TestDebug 'Teste123'


----------------------------------------
------------ SQLQueryStress ------------
----------------------------------------
-- Scalar functions...
SELECT dbo.fn_SomenteTexto(ProductName, 'N') AS Col1,
       p.*
  FROM ProductsBig as p
GO
SELECT Tab1.Col1 AS Col1,
       p.* 
  FROM ProductsBig AS p
 CROSS APPLY (SELECT SUBSTRING(p.ProductName, fnSequencial.Num, 1) AS "text()"
                 FROM dbo.fnSequencial(LEN(p.ProductName))
                WHERE SUBSTRING(p.ProductName, fnSequencial.Num, 1) LIKE '[A-Z]'
                  FOR XML PATH('')) AS Tab1(Col1)


----------------------------------------
--------------- xEvents ----------------
----------------------------------------
-- Espera por sessão
USE master
GO
SET NOCOUNT ON
GO
DROP EVENT SESSION EsperaPorSessao ON SERVER
GO
EXEC xp_cmdShell 'del c:\wait*.*'
GO
CREATE EVENT SESSION EsperaPorSessao ON SERVER
   ADD EVENT sqlos.wait_info (WHERE sqlserver.session_id = Numero_Do_SPID_Da_Sessao),
   ADD EVENT sqlos.wait_info_external (WHERE sqlserver.session_id = Numero_Do_SPID_Da_Sessao)
   ADD TARGET package0.asynchronous_file_target
  (SET filename=N'c:\wait_stats.xel', metadatafile=N'c:\wait_stats.xem')
WITH (MAX_DISPATCH_LATENCY = 1 SECONDS)
GO
-- Iniciando a sessão
ALTER EVENT SESSION EsperaPorSessao ON SERVER STATE = START;
GO


-- EXECUTAR COMANDO DA SESSÃO --


-- Parando a sessão
ALTER EVENT SESSION EsperaPorSessao ON SERVER STATE = STOP;
GO

-- Lendo e formatando o resultado dados dos arquivos
IF OBJECT_ID('TMP_RawEventData') IS NOT NULL
  DROP TABLE TMP_RawEventData
GO
CREATE TABLE TMP_RawEventData(Rowid		    Int IDENTITY(1,1) PRIMARY KEY,
                             	event_data	XML);
GO
-- Insere os XE na tabela TMP...
INSERT INTO TMP_RawEventData (event_data)
SELECT CONVERT(XML, event_data) AS event_data
  FROM sys.fn_xe_file_target_read_file ('c:\wait_stats*.xel', 'c:\wait_stats*.xem', null, null)
GO
WITH CTE_1
AS
(
SELECT	event_data.value ('(/event/@timestamp)[1]',	'DATETIME') AS [Time],
	      event_data.value ('(/event/data[@name=''wait_type'']/text)[1]',	'VARCHAR(100)') AS [Wait Type],
	      event_data.value ('(/event/data[@name=''opcode'']/text)[1]',	'VARCHAR(100)') AS [Op],
	      event_data.value ('(/event/data[@name=''duration'']/value)[1]','BIGINT') AS [Duration (ms)],
	      event_data.value ('(/event/data[@name=''max_duration'']/value)[1]','BIGINT') AS [Max Duration (ms)],
	      event_data.value ('(/event/data[@name=''total_duration'']/value)[1]','BIGINT') AS [Total Duration (ms)],
	      event_data.value ('(/event/data[@name=''signal_duration'']/value)[1]','BIGINT') AS [Signal Duration (ms)],
	      event_data.value ('(/event/data[@name=''completed_count'']/value)[1]','BIGINT') AS [Count]
  FROM (SELECT event_data
          FROM TMP_RawEventData) AS Tab
)
SELECT	[Wait Type],
	      COUNT (*) AS [Wait Count],
	      SUM ([Duration (ms)]) AS [Total Wait Time (ms)],
	      ((SUM ([Duration (ms)]) / 1000.)/60.) AS [Total Wait Time (mins)],
	      SUM ([Duration (ms)]) - SUM ([Signal Duration (ms)]) AS [Total Resource Wait Time (ms)],
	      SUM ([Signal Duration (ms)]) AS [Total Signal Wait Time (ms)]
  FROM CTE_1
 GROUP BY [Wait Type]
 ORDER BY [Total Wait Time (ms)] DESC;
GO
exec xp_cmdShell 'del c:\wait*.*'
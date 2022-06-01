/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

-------------------------------
-- Monitorando Sort Warnings --
-------------------------------
USE NorthWind
GO

-- No SQL Server 2012 tem um warning no operador de sort
SELECT TOP 101
       CustomerID,
       CityID,
       CompanyName,
       ContactName,
       Col1,
       Col2
  FROM CustomersBig
 ORDER BY Col1
OPTION (MAXDOP 1)
GO

-- Também é possível capturar via xEvents
-- Demo


-- Versões anteriores a 2012, tem que pegar via Profiler
-- Porém o profiler não mostra a coluna TextData...


-- Passo 1 definir trace:
-- Passo 2 dar um PAUSE no trace
-- Passo 3 criar coluna TextData (caso não exista...)
-- Passo 4 criar a trigger
-- Passo 5 iniciar o trace


ALTER TABLE TabTraces ADD TextData VARCHAR(MAX)
GO

IF OBJECT_ID('tr_CapturaSQL_SortWarning') IS NOT NULL
  DROP TRIGGER tr_CapturaSQL_SortWarning
GO
-- Uma das soluções é salvar o trace em uma tabela criar uma trigger after insert
CREATE TRIGGER tr_CapturaSQL_SortWarning ON TabTraces
AFTER INSERT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SQL VARCHAR(MAX)

  SELECT @SQL = sqltext.text
   FROM sys.dm_exec_connections conn
  INNER JOIN inserted
     ON inserted.SPID = conn.session_id
  CROSS APPLY sys.dm_exec_sql_text(conn.most_recent_sql_handle) AS sqltext

  UPDATE	TabTraces
     SET TextData = @SQL
    FROM TabTraces
   INNER JOIN Inserted
      ON Inserted.SPID = TabTraces.SPID
   WHERE TabTraces.TextData IS NULL
END
GO

-- Consulta trace
SELECT * FROM TabTraces
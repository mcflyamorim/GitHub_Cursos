USE Northwind
GO

-- Quantas linhas tem na tabela OrdersBig?
SELECT COUNT(*) FROM OrdersBig
GO

SELECT Rowcnt
  FROM sysindexes
 WHERE id = OBJECT_ID('OrdersBig') 
   AND indid <= 1
   AND rowcnt > 0
GO

-- Verificando valores atuais...
DBCC SHOW_STATISTICS (OrdersBig) WITH STATS_STREAM
GO
-- Atualizando com números maiores
UPDATE STATISTICS OrdersBig WITH ROWCOUNT = 1000005, PAGECOUNT = 3589
GO

-- Reset ROWCOUNT e PAGECOUNT com números originais...
DBCC UPDATEUSAGE (Northwind,'OrdersBig') WITH COUNT_ROWS;
GO

-- Cuidado com migrações/upgrades de versão pois esses valores podem ficar desatualizados... 
-- Por isso é importante fazer um DBCC UPDATEUSAGE depois de uma migração
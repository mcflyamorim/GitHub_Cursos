
-------------------------------
-------- Prefetching ----------
-------------------------------
-- Locks gerados pelas leituras em Repeatable Read Isolation level... --

USE Northwind
GO
IF OBJECT_ID('Tab5') IS NOT NULL
  DROP TABLE Tab5
GO
CREATE TABLE Tab5 (Col1 Int IDENTITY(1,1) NOT NULL PRIMARY KEY, Col2 Int, Col3 Char(7500) DEFAULT NEWID())
GO
INSERT INTO Tab5(Col2) VALUES (1), (2), (3), (4), (5)
GO
CREATE INDEX ix1 ON Tab5(Col2)
GO
UPDATE STATISTICS Tab5 WITH ROWCOUNT = 1000, PAGECOUNT = 500
GO


-- Demo 1, locks gerados no nível repetable read...
-- SQL segura os locks compartilhados nas linhas...

-- Sessão 1
USE Northwind
GO
BEGIN TRAN

-- Update para gerar lock x na linha com Col1 = 5
UPDATE Tab5 SET Col3 = NEWID()
 WHERE Col1 = 5
GO

-- Rodar comando da sessão 2

ROLLBACK TRAN

-- Sessão 2
-- Consulta que faz seek + lookup com prefetch
SELECT *
  FROM Tab5 WITH(index=ix1)
 WHERE Col2 <= 5
OPTION (RECOMPILE, MAXDOP 1)

-- Sessão 3
-- Abrir outra sessão e analisar locks gerados pelo comando da sessão 2
sp_lock 54 -- ID da Sessão 2

-- Resultado locks compartilhados no indid 2 (indice por Col2)
/*
spid	dbid	ObjId	     IndId	Type	Resource	      Mode	 Status
54	  5	   2078630448	1	    KEY	(59855d342c69)  S	    WAIT
54	  5	   2078630448	2	    KEY	(b53a24a58f2a)  S	    GRANT
54	  5	   2078630448	2	    KEY	(e2338e2f4a9f)  S	    GRANT
54	  5	   2078630448	2	    KEY	(e94538932c7c)  S	    GRANT
*/

-- Teste sem prefetch

-- Sessão 2
-- Consulta que faz seek + lookup sem prefetch
SELECT *
  FROM Tab5 WITH(index=ix1)
 WHERE Col2 <= 5
OPTION (RECOMPILE, MAXDOP 1, QueryTraceON 8744) -- Desabilitar Prefetch

-- Sessão 3
-- Analisar locks gerados pelo comando da sessão 2 e ver diferença...
sp_lock 54 -- ID da Sessão 2


-- Demo 2, DeadLock

-- Sessão 1
USE Northwind
GO
BEGIN TRAN

-- Gero lock x na linha Col1 = 2
UPDATE Tab5 SET Col3 = NEWID()
 WHERE Col1 = 2
GO

-- Rodar select da Sessão 2 pra 
-- segurar os locks compartilhados e depois rodar update abaixo...

-- Tentar pegar lock x na linha 1 que está com lock compartilhado de leitura
-- gerado na sessão 2
-- Sessão 1 vai ficar esperando o select da sessão 2 terminar,  
-- para consegue obter o lock exclusivo 
-- Ou seja, sessão 2, esta esperando sessão 1 e sessão 1 está esperando sessão 2
-- resultado DEADLOCK
UPDATE Tab5 SET Col2 = 9999
 WHERE Col1 = 1

ROLLBACK TRAN

-- Sessão 2
SELECT *
  FROM Tab5 WITH(index=ix1)
 WHERE Col2 <= 2
OPTION (RECOMPILE, MAXDOP 1)
GO






SELECT session_id, 
       CASE transaction_isolation_level 
         WHEN 0 THEN 'Unspecified' 
         WHEN 1 THEN 'ReadUncommitted' 
         WHEN 2 THEN 'ReadCommitted' 
         WHEN 3 THEN 'Repeatable' 
         WHEN 4 THEN 'Serializable' 
         WHEN 5 THEN 'Snapshot' 
       END AS Isolation_Level 
  FROM sys.dm_exec_sessions 
 WHERE session_id = 53
GO

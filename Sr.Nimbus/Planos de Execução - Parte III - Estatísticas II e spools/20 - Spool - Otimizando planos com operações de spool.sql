/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

------------------------------------------------------------
--- Spool - Otimizando spools utilizando views indexadas ---
------------------------------------------------------------

USE Northwind
GO

-- Preparando o ambiente
-- 2 mins e 48 segundos
IF OBJECT_ID('vw_Rebind_Rewind') IS NOT NULL
  DROP VIEW vw_Rebind_Rewind
GO
IF OBJECT_ID('TabRebind_Rewind') IS NOT NULL
  DROP TABLE TabRebind_Rewind
GO
CREATE TABLE TabRebind_Rewind (ID        Integer IDENTITY(1,1),
                               Customer  Integer NOT NULL,
                               Employee  VarChar(30) NOT NULL,
                               Quantity  SmallInt NOT NULL,
                               Value     Numeric(18,2) NOT NULL,
                               OrderDate DateTime NOT NULL,
                               Col1      Char(500) DEFAULT NewID())
GO
CREATE UNIQUE CLUSTERED INDEX ix_PK ON TabRebind_Rewind(ID)
DECLARE @I SmallInt
  SET @I = 0
WHILE @I < 5000
BEGIN
  INSERT INTO TabRebind_Rewind(Customer, Employee, Quantity, Value, OrderDate)
  VALUES(ABS(CheckSUM(NEWID()) / 100000000),
         'Fabiano',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Neves',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000)),
         
         (ABS(CheckSUM(NEWID()) / 100000000),
         'Amorim',
         ABS(CheckSUM(NEWID()) / 10000000),
         ABS(CONVERT(Numeric(18,2), 
         (CheckSUM(NEWID()) / 1000000.5))),
         GETDATE() - (CheckSUM(NEWID()) / 1000000))
  SET @I = @I + 1;
END
SET @I = 0
WHILE @I < 5
BEGIN
  INSERT INTO TabRebind_Rewind(Customer, Employee, Quantity, Value, OrderDate)
  SELECT Customer, Employee, Quantity, Value, OrderDate
  FROM TabRebind_Rewind
  
  SET @I = @I + 1;
END
UPDATE TabRebind_Rewind SET OrderDate = CONVERT(Date, OrderDate)
GO
CREATE INDEX ix_OrderDate_Value ON TabRebind_Rewind(OrderDate, Value)
GO
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
GO

-- Tabela com 480000 linhas
sp_spaceused TabRebind_Rewind
GO


-- Utiliza Table Spool
-- Demora aproximadamente 4 mins e 52 segundos,
-- gera Sort warning por causa do sort por OrderDate
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value, Ped1.Col1
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM TabRebind_Rewind AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO
/*
  Resultados do Profiler
	 CPU: 257994	
  Reads: 3429973	
  Writes: 37	
  Duration: 292410
*/


-- Evitar sort warning
-- Utilizada Index Spool para maximizar número de Rewinds
-- Demora aproximadamente 4 mins e 29 segundos
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value, Ped1.Col1
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM TabRebind_Rewind AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff EnforceSort)
GO
/*
  Resultados do Profiler
	 CPU: 255654	
  Reads: 5349334	
  Writes: 35	
  Duration: 269562
*/


-- Teste com view indexada
IF OBJECT_ID('vw_Rebind_Rewind') IS NOT NULL
  DROP VIEW vw_Rebind_Rewind
GO
CREATE VIEW vw_Rebind_Rewind
WITH SCHEMABINDING
AS
SELECT SUM(Value) AS Soma,
       COUNT_BIG(*) AS Cnt,
       OrderDate
  FROM dbo.TabRebind_Rewind
 GROUP BY OrderDate
GO

CREATE UNIQUE CLUSTERED INDEX ix_vw_Rebind_Rewind ON vw_Rebind_Rewind(OrderDate)
GO

-- Consulta original (sem usar a view) já tem melhora significativa
-- Aproximadamente 21 segundos para rodar
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value, Ped1.Col1
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM TabRebind_Rewind AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO
/*
  Resultados do Profiler
	 CPU: 8081	
  Reads: 2039574	
  Writes: 63	
  Duration: 21159
*/


-- Porém ao forçar o uso da view conseguimos um resultado ainda melhor
-- Aproximadamente 19 segundos para rodar
CHECKPOINT; DBCC FREEPROCCACHE(); DBCC DROPCLEANBUFFERS();
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value, Ped1.Col1
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT SUM(Soma) / SUM(Cnt)
                       FROM vw_Rebind_Rewind WITH(NOEXPAND)
                      WHERE vw_Rebind_Rewind.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO
/*
  Resultados do Profiler
	 CPU: 6708	
  Reads: 2035054	
  Writes: 36	
  Duration: 19753
*/



IF OBJECT_ID('vw_Rebind_Rewind') IS NOT NULL
  DROP VIEW vw_Rebind_Rewind
GO
-- Sem spool demora 7 horas e 24 minutos para rodar...
SELECT Ped1.ID, Ped1.Customer, Ped1.Employee, Ped1.Value, Ped1.Col1
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM TabRebind_Rewind AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1, QueryRuleOff BuildSpool)
GO
/*
  Resultados do Profiler
	 CPU: 26629995 -- SELECT (389003163. * 8.) / 1024. /1024 / 1024 - 2.89 TB de dados
  Reads: 389003163
  Writes: 0
  Duration: 26670768
*/
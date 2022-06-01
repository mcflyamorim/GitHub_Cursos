-- Dicas do mestre Itzik em 
-- https://sqlperformance.com/2019/10/t-sql-queries/overlooked-t-sql-gems

USE Northwind
GO

DECLARE @dbname AS sysname;
 
DECLARE C CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
  SELECT name FROM sys.databases;
 
OPEN C;
 
FETCH NEXT FROM C INTO @dbname;
 
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT N'Handling database ' + QUOTENAME(@dbname) + N'...';
  /* ... do your thing here ... */
  FETCH NEXT FROM C INTO @dbname;
END;
 
--CLOSE C;
--DEALLOCATE C;
GO

DECLARE @dbname AS sysname;
 
DECLARE C CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
  SELECT name FROM sys.databases;
 
OPEN C;
 
FETCH NEXT FROM C INTO @dbname;
 
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT N'Handling database ' + QUOTENAME(@dbname) + N'...';
  /* ... do your thing here ... */
  FETCH NEXT FROM C INTO @dbname;
END;
/*
  Msg 16915, Level 16, State 1, Line 30
  A cursor with the name 'C' already exists.
  Msg 16905, Level 16, State 1, Line 32
  The cursor is already open.
*/


-- Da pra declarar o cursor como variável e nunca mais se preocupar com isso :-) ...
DECLARE @dbname AS sysname, @C AS CURSOR;
 
SET @C = CURSOR FORWARD_ONLY STATIC READ_ONLY FOR
  SELECT name FROM sys.databases;
 
OPEN @C;
 
FETCH NEXT FROM @C INTO @dbname;
 
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT N'Handling database ' + QUOTENAME(@dbname) + N'...';
  /* ... do your thing here ... */
  FETCH NEXT FROM @C INTO @dbname;
END;
GO

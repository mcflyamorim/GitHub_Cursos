/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

-- Até quando vale a pena fazer um key lookup?

-- ALTER TABLE OrdersBig DROP COLUMN Col1
ALTER TABLE OrdersBig ADD Col1 Int
GO
UPDATE OrdersBig SET Col1 = OrderID
GO
IF EXISTS(SELECT * FROM sysindexes WHERE name ='ix_Col1' and id = object_id('OrdersBig'))
  DROP INDEX ix_Col1 ON OrdersBig
GO
CREATE NONCLUSTERED INDEX ix_Col1 ON OrdersBig(Col1)
GO


-- Retornar 1 pedido da tabela OrdersBig utilizando o índice ix_Col1
SELECT * FROM OrdersBig
 WHERE Col1 = 10
OPTION (RECOMPILE)
/*
  Quão seletiva a coluna precisa ser para compensar fazer o lookup
  utilizando o índice ix_Col1?




















  50% ? 500000
  40% ? 400000
  30% ? 300000
  20% ? 200000
  10% ? 100000
  5% ? 50000
  1% ? 10000
*/
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 500000 -- 50%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 400000 -- 40%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 300000 -- 30%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 200000 -- 20%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 100000 -- 10%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 50000 -- 5%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 10000 -- 1%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 5000 -- 0.5%
OPTION (RECOMPILE)
GO
SELECT *
  FROM OrdersBig
 WHERE Col1 <= 2000 -- 0.2%
OPTION (RECOMPILE)
GO

/*
  Proc sp_TestLookup
*/
EXEC dbo.sp_TestLookup @Table_Name   = 'OrdersBig',
                       @Lookup_Index = 'ix_Col1',
                       @Trace_Path   = 'C:\TesteTrace.trc'
GO
EXEC dbo.sp_TestLookup @Table_Name   = 'ProductsBig',
                       @Lookup_Index = 'ix_ProductName',
                       @Trace_Path   = 'C:\TesteTrace.trc'
GO
EXEC dbo.sp_TestLookup @Table_Name   = 'TestTable',
                       @Lookup_Index = 'ix_Test',
                       @Trace_Path   = 'C:\TesteTrace.trc'
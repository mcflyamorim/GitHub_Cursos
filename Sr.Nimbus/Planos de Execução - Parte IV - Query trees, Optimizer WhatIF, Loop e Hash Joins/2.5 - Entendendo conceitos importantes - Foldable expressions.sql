-- Exemplo de nonfoldable expressions

-- Large types

DECLARE @Var VarChar(MAX) = 'Fabi999'
SELECT * 
  FROM CustomersBig
  WHERE ContactName = REPLACE(@Var, '999', 'ano')
OPTION (MAXDOP 1, RECOMPILE)
GO

DECLARE @Var VarChar(200) = 'Fabi999'
SELECT * 
  FROM CustomersBig
  WHERE ContactName = REPLACE(@Var, '999', 'ano')
OPTION (MAXDOP 1, RECOMPILE)


-- Função não determinística

SELECT * 
  FROM OrdersBig
 WHERE Value <= RAND(100)
OPTION (MAXDOP 1, RECOMPILE)
GO

DECLARE @i Float = RAND(100)
SELECT * 
  FROM OrdersBig
 WHERE Value <= @i
OPTION (MAXDOP 1, RECOMPILE)



-- SET Options

DBCC FREEPROCCACHE()
GO
-- Roda?
-- Plano estimado, 30%
SELECT *
  FROM OrdersBig
 WHERE Value <= CONVERT(tinyInt, 256)
GO










-- Depende do ARITHABORT e ANSI_WARNINGS!


SET ARITHABORT OFF
SET ANSI_WARNINGS OFF

DBCC FREEPROCCACHE()
GO
-- Roda?
-- Plano estimado, 30%
SELECT *
  FROM OrdersBig
 WHERE Value <= CONVERT(tinyInt, 256)
GO

/*
  SET ARITHABORT ON -- Default
  SET ANSI_WARNINGS ON -- Default
  DBCC USEROPTIONS
*/



-- Funções "não suportadas" pelo SQL Server
-- lista de funções suportadas:
-- http://blogs.msdn.com/b/ianjo/archive/2005/11/10/491543.aspx

DBCC FREEPROCCACHE()
GO
SELECT *
  FROM OrdersBig
 WHERE Value <= ABS(-10)
GO


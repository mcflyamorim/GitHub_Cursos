/*
  Sr.Nimbus - OnDemand
  http://www.srnimbus.com.br
*/

USE NorthWind
GO

-- Missing indexes

-- Preparando tabela
IF OBJECT_ID('EmployeesBig') IS NOT NULL
  DROP TABLE EmployeesBig
GO
SELECT IDENTITY(Int, 1,1) AS EmployeeID,
       a.LastName,
       a.FirstName + SUBSTRING(CONVERT(VarChar(200), NEWID()), 0, 5) AS FirstName,
       a.Title,
       a.TitleOfCourtesy,
       a.BirthDate,
       a.HireDate,
       a.Address,
       a.City,
       a.Region,
       a.PostalCode,
       a.Country,
       a.HomePhone,
       a.Extension,
       a.Notes,
       a.ReportsTo,
       a.PhotoPath
  INTO EmployeesBig
  FROM Employees AS a, Employees AS b, Employees AS c, Employees AS d, Employees AS e
GO
ALTER TABLE EmployeesBig ADD CONSTRAINT xpkEmployeeID PRIMARY KEY (EmployeeID)
GO

-- Sugestões não são exibidas para planos triviais...
SELECT LastName,
       FirstName,
       Title,
       TitleOfCourtesy,
       BirthDate,
       HireDate,
       Address,
       City,
       Region,
       PostalCode,
       Country,
       HomePhone,
       Extension
  FROM EmployeesBig
 WHERE PostalCode = '98122'
OPTION (RECOMPILE)
GO

-- Ligar TraceFlag 8758 para desabilitar planos trivial plans
DBCC TRACEON(8757)
GO
-- A recomendação é de um índice com TODAS as colunas no include cuidado com isso!
SELECT LastName,
       FirstName,
       Title,
       TitleOfCourtesy,
       BirthDate,
       HireDate,
       Address,
       City,
       Region,
       PostalCode,
       Country,
       HomePhone,
       Extension
  FROM EmployeesBig
 WHERE PostalCode = '98122'
OPTION (RECOMPILE)
GO
-- Desligar TraceFlag 8758 para voltar trivial plans
DBCC TRACEOFF(8757)
GO


-- Recomendações são feitas com base no plano ESTIMADO,
-- Se a estimativa estiver errada, ele não vai recomendar nada, 
-- ou pode recomendar errado
-- Ou seja, recomendação é feita baseada no plano estimado, 
-- com base nos filtros utilizados...
-- Talvez não sirva para todos os casos...

-- Atualizando as estatísticas para "enganar" o Otimizador
-- DBCC SHOW_STATISTICS (EmployeesBig) WITH STATS_STREAM
-- Stats_Stream	Rows	Data Pages
-- NULL	59049	1543
UPDATE STATISTICS EmployeesBig WITH ROWCOUNT = 1, PAGECOUNT = 1
GO
SELECT LastName, FirstName, Title
  FROM EmployeesBig
 WHERE PostalCode = '98122'
OPTION (RECOMPILE, QUERYTRACEON 8757) -- Outra forma de habilitar o traceflag
GO
UPDATE STATISTICS EmployeesBig WITH ROWCOUNT = 59049, PAGECOUNT = 1543
GO



-- Índice sugerido não é a melhor opção
SELECT OrderID, CustomerID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = '20080205'
 ORDER BY Value
OPTION (RECOMPILE, QUERYTRACEON 8757) -- Outra forma de habilitar o traceflag

-- Consegue ver o problema no índice sugerido?
CREATE NONCLUSTERED INDEX ix1 ON [dbo].[OrdersBig] ([OrderDate]) 
INCLUDE ([CustomerID],[Value])
GO

-- E agora o sort? ...
SELECT CustomerID, OrderDate, Value
  FROM OrdersBig
 WHERE OrderDate = '20080205'
 ORDER BY Value
OPTION (RECOMPILE, QUERYTRACEON 8757) -- Outra forma de habilitar o traceflag

-- O índice correto é: 
 -- DROP INDEX ix1 ON [dbo].[OrdersBig] 
CREATE NONCLUSTERED INDEX ix1 ON [dbo].[OrdersBig] ([OrderDate], [Value]) INCLUDE ([CustomerID])
GO





-- Vamos criar o índice sugerido para a tabela EmployeesBig
-- DROP INDEX ix1 ON [dbo].[EmployeesBig]
CREATE NONCLUSTERED INDEX ix1 ON [dbo].[EmployeesBig] ([PostalCode]) INCLUDE ([LastName],[FirstName],[Title])
GO

-- Continua sugerindo o índice...
DECLARE testcursor CURSOR FOR
SELECT LastName, Title, FirstName
  FROM EmployeesBig
 WHERE PostalCode = '98122'
OPTION (RECOMPILE, QUERYTRACEON 8757) -- Outra forma de habilitar o traceflag
DEALLOCATE testcursor;


-- Bug (corrigido no SQL2012)
https://connect.microsoft.com/SQLServer/feedback/details/416197/the-missing-index-feature-suggests-an-index-which-is-already-present#details

if object_id('t') is not null 
    drop table t
go
create table t
    (
      col1 int,
      col2 char(1000) not null
                      default ( '' )
    )
go
set nocount on
declare @i int
set @i = 0
while @i < 1000 
    begin
        insert  into t
                ( col1 )
        values  ( @i )
        set @i = @i + 1
    end
set @i = 0
while @i < 1000 
    begin
        insert  into t
                ( col1 )
        values  ( 5000 )
        set @i = @i + 1
    end
set nocount off
go

-- Sugere o índice eternamente
select  *
from    t
where   col1 = 5000
OPTION (recompile)

-- Criar o índice sugerido
DROP INDEX [<Name of Missing Index, sysname,>] ON [dbo].[t] 
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>] ON [dbo].[t] ([col1]) -- Por favor altere o nome! :-)
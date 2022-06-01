/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-------------------------------------------------------------
--- Index Spool e regra diferenciada para rebind e rewind ---
-------------------------------------------------------------

USE Northwind
GO

-- Preparando o ambiente
IF OBJECT_ID('TabRebind_Rewind') IS NOT NULL
  DROP TABLE TabRebind_Rewind
GO
CREATE TABLE TabRebind_Rewind (ID        Integer IDENTITY(1,1),
                               Customer  Integer NOT NULL,
                               Employee  VarChar(30) NOT NULL,
                               Quantity  SmallInt NOT NULL,
                               Value     Numeric(18,2) NOT NULL,
                               OrderDate DateTime NOT NULL)
GO
CREATE UNIQUE CLUSTERED INDEX ix_PK ON TabRebind_Rewind(ID)
GO

TRUNCATE TABLE TabRebind_Rewind
GO
SET IDENTITY_INSERT TabRebind_Rewind ON
INSERT INTO TabRebind_Rewind(ID, Customer, Employee, Quantity, Value, OrderDate)
VALUES(1,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203'),
      (2,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203'),
      (3,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '20100622'),
      (4,
       ABS(CheckSUM(NEWID()) / 100000000),
       'Fabiano',
       ABS(CheckSUM(NEWID()) / 10000000),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),
       '19831203')
SET IDENTITY_INSERT TabRebind_Rewind OFF
GO

-- Visualizando os dados
SELECT * FROM TabRebind_Rewind
GO


/*
  Vejamos o comportamento do Rebind e Rewind no "Index Spool"
  
  Novamente supondo que a tabela TabRebind_Rewind contêm 4 linhas
  na seguinte ordem "19831203", "19831203", "20100622" e "19831203"
  Uma representação do Rebind e Rewind seria o seguinte:
  
  * Value = "19831203". Ocorre um rebind, já que é a primeira vez que o operador é chamado.
  * Value = "19831203". Ocorre um rewind, já que o Value já foi lido, e está no spool cache.
  * Value = "20100622". Ocorre um rebind já que o Value "20100622" ainda não está no cache.
  * Value = "19831203". Um rewind ocorre, este Value foi lido no passo 1, e continua no cache.

  Números finais: 2 Rebinds (passos 1 e 3) e 2 rewinds (passos 2 e 4).
  
  Com o script abaixo podemos tirar a prova:
*/

-- Fingir que a tabela é grande para forçar o uso do index spool
UPDATE STATISTICS TabRebind_Rewind WITH ROWCOUNT = 1000, PAGECOUNT = 1000
GO

-- Analisar o Rebind Rewind do operador Index Spool
-- Qual é a diferença entre o Eager e o Lazy?
SELECT *
  FROM TabRebind_Rewind AS Ped1
 WHERE Ped1.Value > (SELECT AVG(Ped2.Value)
                       FROM TabRebind_Rewind AS Ped2
                      WHERE Ped2.OrderDate < Ped1.OrderDate)
OPTION (RECOMPILE, MAXDOP 1)
GO

/*
  Segundo nossas contas (texto acima) esperamos os seguintes valores:
  Rebind = 2
  Rewind = 2
  
  Valores atuais são:
  Rebind = 3
  Rewind = 1
  
  Pergunta: Porque os valores não bateram?
  
  
  
  

  
  
  
  
  
  
  
  
  
  Resposta: Por que o SQL está mentindo. :-)
  
  Texto extraido do livro “Inside Microsoft SQL Server 2005 Query Tuning and Optimization”, 
  Craig Freedman do time de desenvolvimento do SQL Server escreveu o seguinte:

  “Note that rewinds and rebinds are counted the same way for index and nonindex spools. 
  As described previously, a reexecution is counted as a rewind only if the 
  correlated parameter(s) remain the same as the immediately prior execution, 
  and is counted as a rebind if the correlated parameter(s) change from the prior execution. 
  This is true even for reexecutions, in which the same correlated parameter(s) 
  were encountered in an earlier, though not the immediately prior, execution.
  However, since lazy index spools, like the one in this example, 
  retain results for all prior executions and all previously encountered 
  correlated parameter values, the spool may treat some reported rebinds as rewinds.
  In other words, by failing to account for correlated parameter(s) that were seen 
  prior to the most recent execution, the query plan statistics may overreport the
  number of rebinds for an index spool.”
*/
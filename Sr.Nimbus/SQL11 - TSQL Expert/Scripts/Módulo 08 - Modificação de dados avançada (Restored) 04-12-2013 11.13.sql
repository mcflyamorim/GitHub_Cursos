/*
  Sr.Nimbus - T-SQL Expert
         Módulo 08
  http://www.srnimbus.com.br
*/

USE Northwind
GO


----------------------------------------
----------- SELECT INTO ----------------
----------------------------------------
SET NOCOUNT ON
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (ID Int IDENTITY(1,1), Col1 Char(2000) DEFAULT NEWID(), Col2 Char(5000) DEFAULT NEWID())
GO
CHECKPOINT
GO
-- 7 segundos
INSERT INTO T1(Col1, Col2) DEFAULT VALUES
GO 10000

-- 2 segundos
BEGIN TRAN
GO
INSERT INTO T1(Col1, Col2) DEFAULT VALUES
GO 10000
COMMIT
GO
-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)
GO
CHECKPOINT
GO

--DROP TABLE T2
-- SELECT + INTO, minimmal logged
SELECT * INTO T2
  FROM T1

-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

----------------------------------------
---------- INSERT SELECT ---------------
----------------------------------------

IF OBJECT_ID('T3') IS NOT NULL
  DROP TABLE T3
GO
CREATE TABLE T3 (ID Int IDENTITY(1,1), Col1 Char(2000), Col2 Char(5000) )
GO

checkpoint
GO
-- insert into tbm é minimal logged?
INSERT INTO t3(Col1, Col2)
SELECT Col1, Col2 FROM T1

-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

-- 147 MB de log gerado pelo insert

-- recriando a tabela
DROP TABLE T3
GO
CREATE TABLE T3 (ID Int IDENTITY(1,1), Col1 Char(2000), Col2 Char(5000) )
GO

checkpoint
GO
-- insert into com TABLOCK para gerar minimal logged
INSERT INTO t3 WITH(tablock) (Col1, Col2) 
SELECT Col1, Col2 FROM T1
GO

-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)
GO

-- Quando é minimal logged?
/*           http://msdn.microsoft.com/en-us/library/dd425070%28v=sql.100%29.aspx
  -----------------------------------------------------------------------------------------------------------
  |Table Indexes    |Rows in table 	|Hints 	            |Without TF 610  |With TF 610 	|Concurrent possible |
  -----------------------------------------------------------------------------------------------------------
  |Heap             |Any            |TABLOCK            |Minimal         |Minimal      |Yes                 |
  |Heap             |Any            |None               |Full            |Full         |Yes                 |
  |Heap + Index     |Any            |TABLOCK            |Full            |Depends (3)  |No                  |
  |Cluster          |Empty          |TABLOCK, ORDER (1) |Minimal         |Minimal      |No                  |
  |Cluster          |Empty          |None               |Full            |Minimal      |Yes (2)             |
  |Cluster          |Any            |None               |Full            |Minimal      |Yes (2)             |
  |Cluster          |Any            |TABLOCK            |Full            |Minimal      |No                  |
  |Cluster + Index  |Any            |None               |Full            |Depends (3)  |Yes (2)             |
  |Cluster + Index  |Any            |TABLOCK            |Full            |Depends (3)  |No                  |
  -----------------------------------------------------------------------------------------------------------
*/

IF OBJECT_ID('T4') IS NOT NULL
  DROP TABLE T4
GO
CREATE TABLE T4 (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Char(2000), Col2 Char(5000) )
GO
CHECKPOINT
GO
INSERT INTO T4 (Col1, Col2) VALUES('', '')
GO

-- Se já existir dados na tabela, precisamos habilitar o TraceFlag 610
-- para conseguir usar minimal log
DBCC TRACEON(610)
--DBCC TRACEOFF(610)
GO
INSERT INTO T4 WITH(TABLOCK) (Col1, Col2)
SELECT Col1, Col2 FROM T1
GO
-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

----------------------------------------
------------ BULK INSERTS --------------
----------------------------------------

-- Gerando arquivo para testes usando BCP
DECLARE @SQL VarChar(8000)
SELECT @SQL = 'bcp northwind.dbo.T1 OUT C:\T1.csv -c -t, -T -S' + @@servername
EXEC xp_cmdshell 'del c:\T1.csv'
EXEC xp_cmdshell @SQL

-- Criando tabela para importar o csv
IF OBJECT_ID('T5') IS NOT NULL
  DROP TABLE T5
GO
CREATE TABLE T5 (ID Int IDENTITY(1,1) PRIMARY KEY, Col1 Char(2000), Col2 Char(5000) )
GO
CHECKPOINT
GO

BULK INSERT T5
    FROM 'C:\T1.csv' 
    WITH 
    ( 
      FIELDTERMINATOR = ',',
      TABLOCK
    )
-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

----------------------------------------
------- ROW VALUE CONSTRUCTORS ---------
----------------------------------------
SELECT *
  FROM  (VALUES (1, 'Cli 1', '(111) 111-1111', 'Endereço 1'),
                (2, 'Cli 2', '(222) 222-2222', 'Endereço 2'),
                (3, 'Cli 3', '(333) 333-3333', 'Endereço 3'),
                (4, 'Cli 4', '(444) 444-4444', 'Endereço 4'),
                (5, 'Cli 5', '(555) 555-5555', 'Endereço 5')) AS Tab(CliID, CompanyName, Telefone, Endereco);
GO


-- Como Duplicar os dados da tabela?
SELECT * FROM Shippers
GO

SELECT Shippers.* FROM Shippers
 CROSS JOIN (VALUES(''),('')) AS Tab(id)


----------------------------------------
------- TRUNCATE versus DELETE ---------
----------------------------------------
CHECKPOINT
GO
DELETE FROM T5
-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

-- Inserir novamente dados na T5
CHECKPOINT
GO
TRUNCATE TABLE T5
-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)

/*
Truncate
Vantagens:
  Muito mais rápido que delete
  Reseta um ID
  Espaço utilizado pela tabela é liberado
Desvantagens:
  Não é possível usar na clausula WHERE
  Triggers não são disparadas
  Se a tabela estiver replicada não é possível usar truncate
  Se tiver view indexada não pose ser utilizado
*/

----------------------------------------
---------- Lock Escalation -------------
----------------------------------------
-- Lock Escalation

-- DROP TABLE Products_TestLockEscalation
-- Cria tabela de teste, aprox. 2 mins para rodar o código abaixo
SELECT TOP 0
       IDENTITY(Int, 1,1) AS ProductID,
       a.ProductName,
       a.Col1 
  INTO Products_TestLockEscalation 
  FROM ProductsBig a
GO
CREATE UNIQUE CLUSTERED INDEX IX ON Products_TestLockEscalation(ProductID)
GO
DBCC TRACEON(610)
GO
INSERT INTO Products_TestLockEscalation WITH(TABLOCK)(ProductName, Col1)
SELECT NEWID(), NEWID()
FROM CustomersBig
GO 5


/* Um pouco sobre o Lock Manager

Por padrão o SQL inicia alocando uma área de 234 a 350 Kbs reservada para o LockManager.
Este valor não é exato, mas a minha conta foi a seguinte:
Cada lock ocupa aprox. 96 bytes e o SQL inicia com uma reserva para manter 2500 lock, 
ou seja, 2500 * 96 = 240000 bytes ou 234 KBs
Conforme o SQL precisa de mais memória para armazenar os dados dos Locks ele 
solicita mais memória a partir da memória disponível para o SQL Server.

Por padrão a área de Lock Manager utiliza até 60% da memória disponível para o SQL Server.
Na minha instância limitei a como 512 MB ou seja, o Lock Manager pode ir até aprox. 307 MB ou 314368 KBs

Para alterar este valor podemos alterar a opção de lock usando a sp_configure, por ex:

sp_configure 'show advanced options', 1
RECONFIGURE
GO
sp_configure 'locks', 0
RECONFIGURE
GO
*/

-- Desabilitanto o lock escalation para a tabela Products_TestLockEscalation, 
-- o padrão é TABLE
ALTER TABLE Products_TestLockEscalation SET (LOCK_ESCALATION = DISABLE);

-- Delete para apagar 1 milhão de linhas, usando o hint ROWLOCK 
-- para forçar o lock por linha
DELETE FROM Products_TestLockEscalation WITH(ROWLOCK)
WHERE ProductID BETWEEN 0 AND 1000000
/* 
Aprox. 14 segundos para rodar a consulta acima
Requer aprox. 95752KBs ou 93MBs para apagar 1 milhão de linhas
ou seja, para apagar 4 milhões irá demandar 376 MB, o que irá
demandar mais memória do que o disponível, quando isso acontece 
um erro é exibido. 
*/

-- Simulando o Erro tentando apagar 4 milhões de linhas
DELETE FROM Products_TestLockEscalation WITH(ROWLOCK)
WHERE ProductID BETWEEN 1000001 AND 5000000
-- Aprox. 8 mins para dar erro na consulta acima

/* Msg 1204, Level 19, State 4, Line 1
The instance of the SQL Server Database Engine cannot obtain a LOCK resource at this time.
Rerun your statement when there are fewer active users. 
Ask the database administrator to check the lock and memory configuration for this instance, 
or to check for long-running transactions. */


ALTER TABLE dbo.Products_TestLockEscalation SET (LOCK_ESCALATION = AUTO);
GO

-- Rodar o DELETE novamente
DELETE FROM Products_TestLockEscalation WITH(ROWLOCK)
WHERE ProductID BETWEEN 1000001 AND 5000000

-- Rodar os comandos abaixo em uma nova sessão 

-- Consulta para analisar os locks
SELECT * FROM sys.dm_tran_locks
where resource_database_id = DB_ID('Treinamento')

-- Consulta 1 - Verificar quantos KBs de memória estão sendo utilizados para o lock
SELECT s.type, 
       s.Name, 
       s.single_pages_kb
  FROM sys.dm_os_memory_clerks s
 WHERE s.type like '%lock%'
   AND s.name = 'Lock Manager : Node 0'
WAITFOR DELAY '00:00:03'
GO 20

-- Analisar no PerfMon o contador SQLServer: Memory Manager: Lock Memory
-- Consulta 2 - Verificar quantos KBs de memória estão sendo utilizados para o lock
SELECT cntr_value 
  FROM sys.dm_os_performance_counters 
 WHERE counter_name = 'Lock Memory (KB)'

-- Zerar os contadores do SQL
DBCC FREESYSTEMCACHE('ALL')

-- No SQL Server 2005 somente a nível de instância com o trace flag 1211

----------------------------------------
--------------- Expurgo ----------------
----------------------------------------
USE Northwind
GO

-- Solução 1
INSERT INTO OrdersBigHistory
SELECT FROM OrdersBig
WHERE Data < ...

DELETE FROM OrdersBig
WHERE Data < ...

-- Solução 2 (Evitar table lock escalation)
INSERT INTO OrdersBigHistory
SELECT FROM OrdersBig
WHERE Data < ...

WHILE @@RowCount > 0
BEGIN
  DELETE TOP (1000) FROM OrdersBig
  WHERE Data < ...
END

-- Solução 3 (Evitar um passo no processo)
WHILE @@RowCount > 0
BEGIN
  DELETE TOP (1000) FROM OrdersBig
  OUTPUT DELETED.OrdersID,
         DELETED.CustomerID,
         DELETED.OrderDate,
         DELETED.Value
    INTO OrdersBigHistory
  WHERE Data < ...
END



-- Solução 4 (Partition)


-- Cria a função da partição para definir o Range
-- DROP PARTITION FUNCTION pfunc
CREATE PARTITION FUNCTION pfunc (int)
AS RANGE LEFT FOR VALUES (2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
GO

-- Cria o schema da partição para mapear a função da partição para o FileGroup(s)
-- DROP PARTITION SCHEME psche
CREATE PARTITION SCHEME psche
AS PARTITION pfunc ALL TO ([Primary])
GO


--ALTER TABLE OrdersBig DROP COLUMN YearOrderDate
ALTER TABLE OrdersBig ADD YearOrderDate AS ISNULL(YEAR(OrderDate),1900) PERSISTED
GO
-- ALTER TABLE Order_DetailsBig DROP CONSTRAINT FK
-- ALTER TABLE OrdersBig DROP CONSTRAINT [xpk_OrdersBig]
-- ALTER TABLE OrdersBig ADD CONSTRAINT [xpk_OrdersBig] PRIMARY KEY(OrderID)
ALTER TABLE OrdersBig ADD CONSTRAINT [xpk_OrdersBig] PRIMARY KEY(OrderID, YearOrderDate) ON psche(YearOrderDate)

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBig b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBig a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

IF OBJECT_ID('OrdersBigHistory') IS NOT NULL
  DROP TABLE OrdersBigHistory
GO
CREATE TABLE OrdersBigHistory([OrderID] [int] NOT NULL IDENTITY(1, 1),
                              [CustomerID] [int] NULL,
                              [OrderDate] [date] NOT NULL,
                              [Value] [numeric] (18, 2) NOT NULL,
                              YearOrderDate AS ISNULL(YEAR(OrderDate),1900) PERSISTED) ON psche(YearOrderDate)
GO
ALTER TABLE OrdersBigHistory ADD CONSTRAINT [xpk_OrdersBigHistory] PRIMARY KEY(OrderID, YearOrderDate) ON psche(YearOrderDate)
GO

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBigHistory b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBigHistory a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Fazer expurgo da primeira partição
-- Move a primeira partição da tabela OrdersBig para a primeira partição da tabela OrdersBigHistory
ALTER TABLE OrdersBig SWITCH PARTITION 1 TO OrdersBigHistory PARTITION 1
ALTER TABLE OrdersBig SWITCH PARTITION 2 TO OrdersBigHistory PARTITION 2
ALTER TABLE OrdersBig SWITCH PARTITION 3 TO OrdersBigHistory PARTITION 3
...

-- Verifica os dados da tabela OrdersBigHistory
SELECT * FROM OrdersBigHistory

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBig b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBig a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Verificar a distribuição dos dados nas partições
SELECT $PARTITION.pfunc(a.YearOrderDate) AS "Número da Partição",
       COUNT(*) AS "Total de Linhas",
       (SELECT TOP 1 OrderDate FROM OrdersBigHistory b WHERE a.YearOrderDate = b.YearOrderDate) AS "Dados de Exemplo"
  FROM OrdersBigHistory a
 GROUP BY $PARTITION.pfunc(a.YearOrderDate), a.YearOrderDate
 ORDER BY 1
GO

-- Limitações
-- Transferring Data Efficiently by Using Partition Switching
-- ms-help://MS.SQLCC.v10/MS.SQLSVR.v10.en/s10de_1devconc/html/e3318866-ff48-4603-a7af-046722a3d646.htm

----------------------------------------
------- OUTPUT:Composable DML ----------
----------------------------------------

BEGIN TRAN
DECLARE @tb TABLE (ProductID Int, ValorAntigo Float, NovoValor Float)
INSERT INTO @tb
SELECT ProductID, ValorAntigo, NovoValor
  FROM (UPDATE dbo.Products
           SET UnitPrice *= 1.10 -- Atualiza em 10%
        OUTPUT inserted.ProductID,
               deleted.UnitPrice AS ValorAntigo,
               inserted.UnitPrice AS NovoValor
         WHERE SupplierID = 1) AS D
 WHERE ValorAntigo < 20.0 AND NovoValor >= 20.0;
SELECT * FROM @tb
ROLLBACK TRAN

----------------------------------------
--------------- MERGE ------------------
----------------------------------------
IF OBJECT_ID('Agenda') IS NOT NULL
  DROP TABLE Agenda
GO
CREATE TABLE Agenda (Codigo int NOT NULL, Nome varchar(100) NOT NULL,
                     Telefone varchar(20) NULL, DataNascimento date NULL)
GO

MERGE Agenda AS A
USING Suppliers S
  	ON (A.Codigo = S.SupplierID)
	WHEN NOT MATCHED BY TARGET
	THEN INSERT VALUES (SupplierID, ContactName, Phone, NULL)
	WHEN MATCHED
	THEN UPDATE SET Nome = ContactName, Telefone = Phone
	WHEN NOT MATCHED BY SOURCE
	THEN DELETE
OUTPUT $action, inserted.*, deleted.*;

-- QO Bug, MERGE.sql

-- Performance

-- Preparando base
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000 
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO
IF OBJECT_ID('TestMergeCustomersBig') IS NOT NULL
  DROP TABLE TestMergeCustomersBig
GO
CREATE TABLE [dbo].[TestMergeCustomersBig] ([CustomerID] [int] NOT NULL,
                                            [CityID] [int] NULL,
                                            [CompanyName] [varchar] (209) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            [ContactName] [varchar] (209) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            [Col1] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
                                            [Col2] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL)
GO
ALTER TABLE [TestMergeCustomersBig] ADD CONSTRAINT xpk_TestMergeCustomersBig PRIMARY KEY(CustomerID)
GO
INSERT INTO TestMergeCustomersBig WITH(TABLOCK)
SELECT TOP 300000 * 
  FROM CustomersBig
GO
-- Remover algumas linhas para gerar o delete
DELETE TOP (10) PERCENT FROM CustomersBig
GO
-- Atualizar algumas linhas da CustomersBig para gerar update
UPDATE TOP (10) PERCENT CustomersBig SET Col1 = NEWID()
GO





-- 5 segundos para rodar os 3 comandos abaixo
UPDATE TestMergeCustomersBig SET Col1 = CustomersBig.Col1
  FROM TestMergeCustomersBig
 INNER JOIN CustomersBig
    ON TestMergeCustomersBig.CustomerID = CustomersBig.CustomerID
 WHERE TestMergeCustomersBig.Col1 <> CustomersBig.Col1

INSERT INTO TestMergeCustomersBig
SELECT * 
  FROM CustomersBig
 WHERE NOT EXISTS(SELECT 1 
                    FROM TestMergeCustomersBig
                   WHERE TestMergeCustomersBig.CustomerID = CustomersBig.CustomerID)

DELETE TestMergeCustomersBig
  FROM TestMergeCustomersBig
 WHERE NOT EXISTS(SELECT 1 
                    FROM CustomersBig
                   WHERE TestMergeCustomersBig.CustomerID = CustomersBig.CustomerID)
GO

-- Recriar tabsTestMergeCustomersBig_RESULTADOCOMANDOS

MERGE TestMergeCustomersBig
USING CustomersBig
  	ON (TestMergeCustomersBig.CustomerID = CustomersBig.CustomerID)
	WHEN NOT MATCHED BY TARGET
	THEN INSERT VALUES (CustomerID, CityID, CompanyName, ContactName, Col1, Col2)
	WHEN MATCHED AND TestMergeCustomersBig.Col1 <> CustomersBig.Col1
	THEN UPDATE SET TestMergeCustomersBig.Col1 = CustomersBig.Col1
	WHEN NOT MATCHED BY SOURCE
	THEN DELETE;
/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

SET NOCOUNT ON
IF OBJECT_ID('T1') IS NOT NULL
  DROP TABLE T1
GO
CREATE TABLE T1 (Col1 Char(2000) DEFAULT NEWID(), Col2 Char(5000) DEFAULT NEWID())
GO
CHECKPOINT
GO
-- Popular tabela com algumas linhas pra usar no teste...
BEGIN TRAN
GO
INSERT INTO T1(Col1, Col2) DEFAULT VALUES
GO 30000
COMMIT
GO
SELECT @@TRANCOUNT
GO

IF OBJECT_ID('T2') IS NOT NULL
  DROP TABLE T2
GO
CREATE TABLE T2 (Col1 Char(2000) DEFAULT NEWID(), Col2 Char(5000) DEFAULT NEWID())
GO
CHECKPOINT
GO

-- insert into é minimal logged?
INSERT INTO T2(Col1, Col2)
SELECT Col1, Col2 
  FROM T1
GO

-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)
GO

-- 219.87 MB de log gerado pelo insert

-- recriando a tabela
IF OBJECT_ID('T2') IS NOT NULL
  DROP TABLE T2
GO
CREATE TABLE T2 (Col1 Char(2000) DEFAULT NEWID(), Col2 Char(5000) DEFAULT NEWID())
GO
CHECKPOINT
GO


-- insert into com TABLOCK para gerar minimal logged
-- alem de ser minimamente logado, ainda rodou em paralelo por causa da feature do SQL2016+
INSERT INTO T2 WITH(TABLOCK) (Col1, Col2) 
SELECT Col1, Col2 FROM T1
GO

-- Consulta eventos gerados no Log
SELECT CONVERT(Numeric(18,2), SUM("Log Record Length") / 1024. / 1024.) AS MBs
  FROM ::fn_dblog(null, null)
GO

-- 3.69


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
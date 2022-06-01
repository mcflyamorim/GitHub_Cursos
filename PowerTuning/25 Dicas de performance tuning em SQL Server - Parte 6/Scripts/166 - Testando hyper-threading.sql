USE NorthWind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
BEGIN
  DROP TABLE OrdersBig
END
GO
CREATE TABLE [dbo].[OrdersBig](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NULL,
	[OrderDate] [date] NOT NULL,
	[Value] [numeric](18, 2) NOT NULL
) ON [PRIMARY]
GO
INSERT INTO [OrdersBig] WITH (TABLOCK) ([CustomerID], OrderDate, Value) 
SELECT TOP 100000
       ABS(CHECKSUM(NEWID())) / 100000 AS CustomerID,
       ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('fnSequencial', 'IF') IS NOT NULL
  DROP FUNCTION dbo.fnSequencial
GO
CREATE FUNCTION dbo.fnSequencial (@i Int)
RETURNS TABLE
AS
RETURN 
(
 WITH L0   AS(SELECT 1 AS C UNION ALL SELECT 1 AS O), -- 2 rows
     L1   AS(SELECT 1 AS C FROM L0 AS A CROSS JOIN L0 AS B), -- 4 rows
     L2   AS(SELECT 1 AS C FROM L1 AS A CROSS JOIN L1 AS B), -- 16 rows
     L3   AS(SELECT 1 AS C FROM L2 AS A CROSS JOIN L2 AS B), -- 256 rows
     L4   AS(SELECT 1 AS C FROM L3 AS A CROSS JOIN L3 AS B), -- 65,536 rows
     L5   AS(SELECT 1 AS C FROM L4 AS A CROSS JOIN L4 AS B), -- 4,294,967,296 rows
     Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS N FROM L5)

SELECT TOP (@i) N AS Num
  FROM Nums
)
GO
DROP TABLE IF EXISTS Table1_8GB
-- Creating tables to simulate issue
SELECT ABS(CHECKSUM(NEWID())) / 100000 AS ProductID, 
       SubString(CONVERT(VarChar(250),NEWID()),1,8) AS ProductName, 
       CONVERT(VarChar(250), NEWID()) AS Col1,
       CONVERT(Char(4000), NEWID()) AS Col2
  INTO Table1_8GB
  FROM dbo.fnSequencial(1024000)
OPTION (MAXDOP 4)
GO
CREATE CLUSTERED INDEX ix1 ON Table1_8GB(ProductID)
GO




-- Comando pra ficar "gastando" CPU
SELECT ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000))),0)
GO

-- Proc para ler algo da tab OrdersBig
IF OBJECT_ID('st_SOS_SCHEDULER_YIELD') IS NOT NULL
  DROP PROC st_SOS_SCHEDULER_YIELD
GO
CREATE PROC st_SOS_SCHEDULER_YIELD
AS
BEGIN
  DECLARE @i INT, @y INT, @x INT, @counter INT = 1

  WHILE @counter <= 10
  BEGIN
    SET @i = ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 100000))),0)
    SET @y = @i + 1000
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

    SELECT TOP 1000 @x = OrderiD FROM OrdersBig WITH(NOLOCK)
    WHERE OrderID BETWEEN @i AND @y

    SET @counter += 1;
  END
END
GO
-- Reiniciar instância...
EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT create_date FROM sys.databases WHERE name = 'tempdb'
GO


-- Testar a proc
EXEC st_SOS_SCHEDULER_YIELD
GO


-- Rodar load de CPU
-- C:\RMLUtils\ostress.exe -Usa -P@bc12345 -Sdellfabiano\sql2019 -n200 -r500 -dNorthwind -Q"EXEC st_SOS_SCHEDULER_YIELD" -q
/*
  Starting query execution...
   BETA: Custom CLR Expression support enabled.
  Creating 200 thread(s) to process queries
  PROGRESS: Creating thread 100
  Worker threads created, beginning execution...
  Total IO waits: 0, Total IO wait time: 0 (ms)
  OSTRESS exiting normally, elapsed time: 00:00:12.293
*/
/*
  Starting query execution...
   BETA: Custom CLR Expression support enabled.
  Creating 200 thread(s) to process queries
  PROGRESS: Creating thread 100
  Worker threads created, beginning execution...
  Total IO waits: 0, Total IO wait time: 0 (ms)
  OSTRESS exiting normally, elapsed time: 00:00:12.549
*/


-- Quanto tempo pra fazer um Scan+Sort em uma tabela de 8GB?
SET STATISTICS TIME ON
DECLARE @i INT
SELECT @i = ProductID FROM Table1_8GB
ORDER BY ProductName
OPTION (MIN_GRANT_PERCENT = 50, MAXDOP 20)
SET STATISTICS TIME OFF
GO
--SQL Server Execution Times:
--  CPU time = 5381 ms,  elapsed time = 3277 ms.
/*
<WaitStats>
  <Wait WaitType="PAGEIOLATCH_SH" WaitTimeMs="32431" WaitCount="16246" />
  <Wait WaitType="MEMORY_ALLOCATION_EXT" WaitTimeMs="20402" WaitCount="993055" />
  <Wait WaitType="CXPACKET" WaitTimeMs="10204" WaitCount="3316" />
  <Wait WaitType="LATCH_EX" WaitTimeMs="242" WaitCount="30" />
  <Wait WaitType="RESERVED_MEMORY_ALLOCATION_EXT" WaitTimeMs="219" WaitCount="8066" />
  <Wait WaitType="LATCH_SH" WaitTimeMs="156" WaitCount="15" />
  <Wait WaitType="SOS_SCHEDULER_YIELD" WaitTimeMs="96" WaitCount="4625" />
  <Wait WaitType="SESSION_WAIT_STATS_CHILDREN" WaitTimeMs="67" WaitCount="16" />
</WaitStats>

-- Operador Clustered Index Scan
<RunTimeInformation>
  <RunTimeCountersPerThread Thread="20" ActualElapsedms="2756" ActualCPUms="1198" ...
  <RunTimeCountersPerThread Thread="19" ActualElapsedms="2802" ActualCPUms="1222" ...
  <RunTimeCountersPerThread Thread="18" ActualElapsedms="2836" ActualCPUms="1201" ...
  <RunTimeCountersPerThread Thread="17" ActualElapsedms="2829" ActualCPUms="1224" ...
  <RunTimeCountersPerThread Thread="16" ActualElapsedms="2779" ActualCPUms="1189" ...
  <RunTimeCountersPerThread Thread="15" ActualElapsedms="2831" ActualCPUms="1225" ...
  <RunTimeCountersPerThread Thread="14" ActualElapsedms="2809" ActualCPUms="1228" ...
  <RunTimeCountersPerThread Thread="13" ActualElapsedms="2799" ActualCPUms="1218" ...
  <RunTimeCountersPerThread Thread="12" ActualElapsedms="2806" ActualCPUms="1226" ...
  <RunTimeCountersPerThread Thread="11" ActualElapsedms="2733" ActualCPUms="1214" ...
  <RunTimeCountersPerThread Thread="10" ActualElapsedms="2867" ActualCPUms="1240" ...
  <RunTimeCountersPerThread Thread="9"  ActualElapsedms="2810" ActualCPUms="1224" ...
  <RunTimeCountersPerThread Thread="8"  ActualElapsedms="2823" ActualCPUms="1226" ...
  <RunTimeCountersPerThread Thread="7"  ActualElapsedms="2834" ActualCPUms="1226" ...
  <RunTimeCountersPerThread Thread="6"  ActualElapsedms="2877" ActualCPUms="1235" ...
  <RunTimeCountersPerThread Thread="5"  ActualElapsedms="2849" ActualCPUms="1242" ...
  <RunTimeCountersPerThread Thread="4"  ActualElapsedms="2787" ActualCPUms="1204" ...
  <RunTimeCountersPerThread Thread="3"  ActualElapsedms="2826" ActualCPUms="1201" ...
  <RunTimeCountersPerThread Thread="2"  ActualElapsedms="2831" ActualCPUms="1217" ...
  <RunTimeCountersPerThread Thread="1"  ActualElapsedms="2806" ActualCPUms="1239" ...
  <RunTimeCountersPerThread Thread="0"  ActualElapsedms="0"    ActualCPUms="0"    ...
</RunTimeInformation>


-- Interessante, o CpuTime aqui é diferente do exibido no "STATISTICS TIME ON"
<QueryTimeStats CpuTime="25987" ElapsedTime="3269" />

*/

-- Usar CoreInfo pra identificar o mapeamento das CPUs Lógicas pra Físicas
EXEC xp_cmdShell 'D:\Fabiano\Utilitarios\Sysinternals\Coreinfo.exe'
GO
/*
  Logical to Physical Processor Map:
  **------------------  Physical Processor 0 (Hyperthreaded)
  --**----------------  Physical Processor 1 (Hyperthreaded)
  ----**--------------  Physical Processor 2 (Hyperthreaded)
  ------**------------  Physical Processor 3 (Hyperthreaded)
  --------**----------  Physical Processor 4 (Hyperthreaded)
  ----------**--------  Physical Processor 5 (Hyperthreaded)
  ------------**------  Physical Processor 6 (Hyperthreaded)
  --------------**----  Physical Processor 7 (Hyperthreaded)
  ----------------**--  Physical Processor 8 (Hyperthreaded)
  ------------------**  Physical Processor 9 (Hyperthreaded)
*/


-- Ajustar affinity
ALTER SERVER CONFIGURATION SET PROCESS AFFINITY CPU = 0,2,4,6,8,10,12,14,16,18
GO
-- Ligar TF8002 pro scheduler não ficar mais "CPU bound", ou seja, 
-- mesmo comportamento do "SET PROCESS AFFINITY CPU = AUTO"
EXEC xp_cmdShell 'Powershell.exe -Command "Set-DbaStartupParameter -SqlInstance DELLFABIANO\SQL2019 -TraceFlag 8002 -Confirm:$false"'
GO
-- Reiniciar instância...
EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT create_date FROM sys.databases WHERE name = 'tempdb'
GO
-- Verifica TF
DBCC TRACESTATUS(-1)
GO

-- Rodar load de CPU
-- C:\RMLUtils\ostress.exe -Usa -P@bc12345 -Sdellfabiano\sql2019 -n200 -r500 -dNorthwind -Q"EXEC st_SOS_SCHEDULER_YIELD" -q
/*
  [0x000044C0] Starting query execution...
  [0x000044C0]  BETA: Custom CLR Expression support enabled.
  [0x000044C0] Creating 200 thread(s) to process queries
  [0x000044C0] PROGRESS: Creating thread 100
  [0x000044C0] Worker threads created, beginning execution...
  [0x000044C0] Total IO waits: 0, Total IO wait time: 0 (ms)
  [0x000044C0] OSTRESS exiting normally, elapsed time: 00:00:13.353
*/
/*
  [0x0000753C] Starting query execution...
  [0x0000753C]  BETA: Custom CLR Expression support enabled.
  [0x0000753C] Creating 200 thread(s) to process queries
  [0x0000753C] PROGRESS: Creating thread 100
  [0x0000753C] Worker threads created, beginning execution...
  [0x0000753C] Total IO waits: 0, Total IO wait time: 0 (ms)
  [0x0000753C] OSTRESS exiting normally, elapsed time: 00:00:14.159
*/


-- Quanto tempo pra fazer um scan+sort em uma tabela de 8GB?
SET STATISTICS TIME ON
DECLARE @i INT
SELECT @i = ProductID FROM Table1_8GB
ORDER BY ProductName
OPTION (MIN_GRANT_PERCENT = 50, MAXDOP 20)
SET STATISTICS TIME OFF
GO
--SQL Server Execution Times:
--  CPU time = 4169 ms,  elapsed time = 3144 ms.
/*
<WaitStats>
  <Wait WaitType="PAGEIOLATCH_SH" WaitTimeMs="17356" WaitCount="14471" />
  <Wait WaitType="MEMORY_ALLOCATION_EXT" WaitTimeMs="6857" WaitCount="998651" />
  <Wait WaitType="CXPACKET" WaitTimeMs="6413" WaitCount="3412" />
  <Wait WaitType="LATCH_EX" WaitTimeMs="131" WaitCount="20" />
  <Wait WaitType="RESERVED_MEMORY_ALLOCATION_EXT" WaitTimeMs="58" WaitCount="7932" />
  <Wait WaitType="LATCH_SH" WaitTimeMs="49" WaitCount="7" />
  <Wait WaitType="SOS_SCHEDULER_YIELD" WaitTimeMs="32" WaitCount="1393" />
  <Wait WaitType="SESSION_WAIT_STATS_CHILDREN" WaitTimeMs="12" WaitCount="6" />
</WaitStats>

-- Operador Clustered Index Scan
<RunTimeInformation>
  <RunTimeCountersPerThread Thread="10" ActualElapsedms="2753" ActualCPUms="1027"  ...
  <RunTimeCountersPerThread Thread="9"  ActualElapsedms="1915" ActualCPUms="698"  ...
  <RunTimeCountersPerThread Thread="8"  ActualElapsedms="2755" ActualCPUms="1043" ...
  <RunTimeCountersPerThread Thread="7"  ActualElapsedms="2743" ActualCPUms="1039" ...
  <RunTimeCountersPerThread Thread="6"  ActualElapsedms="2750" ActualCPUms="1059" ...
  <RunTimeCountersPerThread Thread="5"  ActualElapsedms="2747" ActualCPUms="1025" ...
  <RunTimeCountersPerThread Thread="4"  ActualElapsedms="2749" ActualCPUms="1036" ...
  <RunTimeCountersPerThread Thread="3"  ActualElapsedms="2762" ActualCPUms="1042" ...
  <RunTimeCountersPerThread Thread="2"  ActualElapsedms="2739" ActualCPUms="1046" ...
  <RunTimeCountersPerThread Thread="1"  ActualElapsedms="2759" ActualCPUms="1043" ...
  <RunTimeCountersPerThread Thread="0"  ActualElapsedms="0"    ActualCPUms="0"...
</RunTimeInformation> 

-- Interessante, o CpuTime aqui é diferente do exibido no "STATISTICS TIME ON"
<QueryTimeStats CpuTime="11382" ElapsedTime="3144" />

*/


-- Clean up
ALTER SERVER CONFIGURATION SET PROCESS AFFINITY CPU = AUTO
GO
EXEC xp_cmdShell 'Powershell.exe -Command "Set-DbaStartupParameter -SqlInstance DELLFABIANO\SQL2019 -TraceFlagOverride -Confirm:$false"'
GO
-- Reiniciar instância...
EXEC xp_cmdShell 'net stop MSSQL$SQL2019 && net start MSSQL$SQL2019'
GO
SELECT create_date FROM sys.databases WHERE name = 'tempdb'
GO
-- Verifica TF
DBCC TRACESTATUS(-1)
GO

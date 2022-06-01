/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind
GO

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 8GB
EXEC sp_configure 'max server memory', 8192
RECONFIGURE
GO


-- 0 - Memory... Everyone wants and need it... 
-- Buffer pool, lock manager, cache plans, query optimizer compilation memory, 
-- workspace memory grant...

-- Memory Clerk Usage for instance
SELECT TOP(10) [type] AS [Memory Clerk Type], 
       SUM(pages_kb)/1024 AS [Memory Usage (MB)] 
  FROM sys.dm_os_memory_clerks WITH (NOLOCK)
 GROUP BY [type]  
 ORDER BY SUM(pages_kb) DESC 
OPTION (RECOMPILE);

-- Results from a customer server:

-- | Memory Clerk Type             | Memory Usage (MB)    |
-- | ------------------------------| -------------------- |
-- | MEMORYCLERK_SQLBUFFERPOOL     | 77144                |
-- | CACHESTORE_SQLCP              | 3327                 |
-- | CACHESTORE_OBJCP              | 946                  |
-- | USERSTORE_TOKENPERM           | 518                  |
-- | USERSTORE_DBMETADATA          | 451                  |
-- | OBJECTSTORE_LOCK_MANAGER      | 415                  |
-- | CACHESTORE_PHDR               | 321                  |
-- | MEMORYCLERK_SOSNODE           | 225                  |
-- | MEMORYCLERK_SQLGENERAL        | 106                  |
-- | OBJECTSTORE_XACT_CACHE        | 82                   |


-- Check Memory grant size
-- Woskpace memory grant is 75% of available memory...
-- 
SELECT counter_name, cntr_value
  FROM sys.dm_os_performance_counters
 WHERE object_name LIKE '%Memory Manager%'
   AND (counter_name LIKE 'Maximum Workspace Memory (KB)%'
    OR counter_name LIKE 'Target Server Memory (KB)%')
GO
-- Maximum Workspace Memory (KB) / Target Server Memory (KB)
SELECT (5594280 / 7444616.)
GO

-- One query can get up to 25% of available woskpace 
-- 1538.99
SELECT ((5594280 * 25) / 1024) / 100. AS QueryMemoryMB
GO


-- 1 - Talk about workspace memory grant and how query plan iterators need 
-- memory... NLJ or SMJ

-- Every query plan needs a "runtime" memory

-- Check query plan flow
-- the following plan doesn't require a memory grant
SELECT COUNT(*)
  FROM OrdersBig
 INNER LOOP JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 10
OPTION (MAXDOP 1, RECOMPILE,
        QueryTraceON 2340, -- Disable batchsort...
        QueryTraceON 8744) -- Disable prefetch...
GO


-- Some iterators need more memory (i.e. sort to run a SMJ)
-- memory grant = 1600KB
-- Check query plan flow
SELECT TOP 100 OrdersBig.CustomerID, OrdersBig.Value
  FROM OrdersBig
 INNER MERGE JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 10
 ORDER BY OrdersBig.CustomerID
OPTION (MAXDOP 1, RECOMPILE) 
GO


-- Open windbg
-- "1 - Open Windbg attached to sqlservr.exe.cmd"

-- set a break point on CbufAcquireGrant
---- bp sqlmin!CQryMemQueue::CbufAcquireGrant
-- g

-- Run query that doesn't require memory grant
SELECT COUNT(*)
  FROM OrdersBig
 INNER LOOP JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 10
OPTION (MAXDOP 1, RECOMPILE,
        QueryTraceON 2340, -- Disable batchsort...
        QueryTraceON 8744) -- Disable prefetch...
GO

-- Run query that require a grant
-- windb will stop at breakpoint
SELECT TOP 100 OrdersBig.CustomerID, OrdersBig.Value
  FROM OrdersBig
 INNER MERGE JOIN CustomersBig
    ON CustomersBig.CustomerID = OrdersBig.CustomerID
 WHERE OrdersBig.Value < 10
 ORDER BY OrdersBig.CustomerID
OPTION (MAXDOP 1, RECOMPILE) 
GO

/*
 # Child-SP          RetAddr           Call Site
00 000000d1`36ffd818 00007ffa`27e5456c sqlmin!CQryMemQueue::CbufAcquireGrant
01 000000d1`36ffd820 00007ffa`27db8cc8 sqlmin!CQueryResourceGrantManager::AcquireGrant+0x7dd
02 000000d1`36ffdaa0 00007ffa`27db8b40 sqlmin!CQueryScan::Setup+0x230
03 000000d1`36ffdb50 00007ffa`2561310e sqlmin!CQuery::CreateExecPlan+0xce
04 000000d1`36ffdbb0 00007ffa`25613424 sqllang!CXStmtQuery::SetupQueryScanAndExpression+0x330
05 000000d1`36ffdc30 00007ffa`2561843b sqllang!CXStmtQuery::InitForExecute+0x34
06 000000d1`36ffdc60 00007ffa`25618649 sqllang!CXStmtQuery::ErsqExecuteQuery+0x49f
07 000000d1`36ffdde0 00007ffa`25614290 sqllang!CXStmtSelect::XretExecute+0x2f2
08 000000d1`36ffdeb0 00007ffa`25614c13 sqllang!CMsqlExecContext::ExecuteStmts<1,1>+0x4c5
09 000000d1`36ffe000 00007ffa`25613d14 sqllang!CMsqlExecContext::FExecute+0xaae
0a 000000d1`36ffe330 00007ffa`2561df95 sqllang!CSQLSource::Execute+0xa2c
0b 000000d1`36ffe640 00007ffa`2561b6d2 sqllang!process_request+0xe29
0c 000000d1`36ffec60 00007ffa`2561b7d3 sqllang!process_commands_internal+0x289
0d 000000d1`36ffed20 00007ffa`4f184e7d sqllang!process_messages+0x213
0e 000000d1`36ffef40 00007ffa`4f185378 sqldk!SOS_Task::Param::Execute+0x231
0f 000000d1`36fff540 00007ffa`4f184fed sqldk!SOS_Scheduler::RunTask+0xad
10 000000d1`36fff5b0 00007ffa`4f1b0c38 sqldk!SOS_Scheduler::ProcessTasks+0x3cd
11 000000d1`36fff6a0 00007ffa`4f1b0d30 sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
12 000000d1`36fff770 00007ffa`4f1b0857 sqldk!SystemThread::RunWorker+0x8f
13 000000d1`36fff7a0 00007ffa`4f1b1049 sqldk!SystemThreadDispatcher::ProcessWorker+0x2e7
14 000000d1`36fff840 00007ffa`87852774 sqldk!SchedulerManager::ThreadEntryPoint+0x1d8
15 000000d1`36fff8f0 00007ffa`88240d51 KERNEL32!BaseThreadInitThunk+0x14
16 000000d1`36fff920 00000000`00000000 ntdll!RtlUserThreadStart+0x21
*/




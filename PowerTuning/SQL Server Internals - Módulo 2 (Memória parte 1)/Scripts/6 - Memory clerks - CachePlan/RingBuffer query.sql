USE master
go
SET NOCOUNT ON
SET QUOTED_IDENTIFIER ON
GO
PRINT 'Start Time: ' + CONVERT (varchar(30), GETDATE(), 121)
GO
PRINT ''
PRINT '==== SELECT GETDATE()'
SELECT GETDATE()
PRINT ''
PRINT ''
PRINT '==== SELECT @@version'
SELECT @@VERSION
GO
PRINT ''
PRINT '==== SQL Server name'
SELECT @@SERVERNAME
GO
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_CONNECTIVITY - LOGIN TIMERS'
  
SELECT a.* FROM
(SELECT
x.value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(30)') AS [RecordType], 
x.value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(30)') AS [RecordSource], 
x.value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'bigint') AS [Spid], 
x.value('(//Record/ConnectivityTraceRecord/OSError)[1]', 'bigint') AS [OSError], 
x.value('(//Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'bigint') AS [SniConsumerError], 
x.value('(//Record/ConnectivityTraceRecord/State)[1]', 'bigint') AS [State], 
x.value('(//Record/ConnectivityTraceRecord/RecordTime)[1]', 'nvarchar(30)') AS [RecordTime],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'bigint') AS [TdsInputBufferError],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'bigint') AS [TdsOutputBufferError],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'bigint') AS [TdsInputBufferBytes],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/TotalLoginTimeInMilliseconds)[1]', 'bigint') AS [TotalLoginTimeInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/LoginTaskEnqueuedInMilliseconds)[1]', 'bigint') AS [LoginTaskEnqueuedInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/NetworkWritesInMilliseconds)[1]', 'bigint') AS [NetworkWritesInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/NetworkReadsInMilliseconds)[1]', 'bigint') AS [NetworkReadsInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/SslProcessingInMilliseconds)[1]', 'bigint') AS [SslProcessingInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/SspiProcessingInMilliseconds)[1]', 'bigint') AS [SspiProcessingInMilliseconds],
x.value('(//Record/ConnectivityTraceRecord/LoginTimers/LoginTriggerAndResourceGovernorProcessingInMilliseconds)[1]', 'bigint') AS [LoginTriggerAndResourceGovernorProcessingInMilliseconds]
FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') AS R(x)) a
where a.RecordType = 'LoginTimers'
order by a.recordtime 
  
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_CONNECTIVITY - TDS Data'
  
SELECT a.* FROM
(SELECT
x.value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(30)') AS [RecordType], 
x.value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(30)') AS [RecordSource], 
x.value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'bigint') AS [Spid], 
x.value('(//Record/ConnectivityTraceRecord/OSError)[1]', 'bigint') AS [OSError], 
x.value('(//Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'bigint') AS [SniConsumerError], 
x.value('(//Record/ConnectivityTraceRecord/State)[1]', 'bigint') AS [State], 
x.value('(//Record/ConnectivityTraceRecord/RecordTime)[1]', 'nvarchar(30)') AS [RecordTime],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'bigint') AS [TdsInputBufferError],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'bigint') AS [TdsOutputBufferError],
x.value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'bigint') AS [TdsInputBufferBytes],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'bigint') AS [PhysicalConnectionIsKilled],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'bigint') AS [DisconnectDueToReadError],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'bigint') AS [NetworkErrorFoundInInputStream],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'bigint') AS [ErrorFoundBeforeLogin],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'bigint') AS [SessionIsKilled],
x.value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'bigint') AS [NormalDisconnect]
FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers 
WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY') AS R(x)) a
where a.RecordType = 'Error'
order by a.recordtime
  
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_SECURITY_EORROR'
  
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, rbf.[timestamp] - tme.ms_ticks, GETDATE()) as [Notification_Time],
cast(record as xml).value('(//SPID)[1]', 'bigint') as SPID,
cast(record as xml).value('(//ErrorCode)[1]', 'varchar(255)') as Error_Code,
cast(record as xml).value('(//CallingAPIName)[1]', 'varchar(255)') as [CallingAPIName],
cast(record as xml).value('(//APIName)[1]', 'varchar(255)') as [APIName],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],tme.ms_ticks as [Current Time]
from sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
where rbf.ring_buffer_type = 'RING_BUFFER_SECURITY_ERROR'
ORDER BY rbf.timestamp ASC
  
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_EXCEPTION'
  
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as Time_Stamp,
cast(record as xml).value('(//Exception//Error)[1]', 'varchar(255)') as [Error],
cast(record as xml).value('(//Exception/Severity)[1]', 'varchar(255)') as [Severity],
cast(record as xml).value('(//Exception/State)[1]', 'varchar(255)') as [State],
msg.description,
cast(record as xml).value('(//Exception/UserDefined)[1]', 'bigint') AS [isUserDefinedError],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type], 
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
from sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
cross join sys.sysmessages msg
where rbf.ring_buffer_type = 'RING_BUFFER_EXCEPTION'
and msg.error = cast(record as xml).value('(//Exception//Error)[1]', 'varchar(500)') and msg.msglangid = 1033 
ORDER BY rbf.timestamp ASC
 
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_RESOURCE_MONITOR to capture external and internal memory pressure'
 
SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime], 
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as [Notification_Time],  
cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type],  
cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %],  
cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id],  
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'bigint') AS [Process_Indicator],  
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'bigint') AS [System_Indicator], 
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'bigint') AS [reserved], 
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect], 
   
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'bigint') AS [reserved],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect], 
   
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'bigint') AS [reserved],  
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect], 
   
cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') AS [SQL_ReservedMemory_KB],  
cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') AS [SQL_CommittedMemory_KB],  
cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory],  
cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory],  
cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory],  
cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') AS [TotalPhysicalMemory_KB],  
cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [AvailablePhysicalMemory_KB],  
cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') AS [TotalPageFile_KB],  
cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') AS [AvailablePageFile_KB],  
cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') AS [TotalVirtualAddressSpace_KB],  
cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [AvailableVirtualAddressSpace_KB],  
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],  
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],  
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time], 
tme.ms_ticks as [Current Time] 
FROM sys.dm_os_ring_buffers rbf 
cross join sys.dm_os_sys_info tme 
where rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW' 
ORDER BY rbf.timestamp ASC
 
 
PRINT ''
PRINT ''
PRINT '==== RING_BUFFER_SCHEDULER_MONITOR to Monitor system health'
 
SELECT  CONVERT (varchar(30), GETDATE(), 121) as runtime, DATEADD (ms, a.[Record Time] - sys.ms_ticks, GETDATE()) AS Notification_time,    a.* , sys.ms_ticks AS [Current Time]  
FROM   (SELECT x.value('(//Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'bigint') AS [ProcessUtilization],    
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'bigint') AS [SystemIdle %],   
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/UserModeTime) [1]', 'bigint') AS [UserModeTime],   
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime) [1]', 'bigint') AS [KernelModeTime],    
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/PageFaults) [1]', 'bigint') AS [PageFaults],   
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta) [1]', 'bigint')/1024 AS [WorkingSetDelta],   
x.value('(//Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization) [1]', 'bigint') AS [MemoryUtilization (%workingset)],   
x.value('(//Record/@time)[1]', 'bigint') AS [Record Time]  FROM (SELECT CAST (record as xml) FROM sys.dm_os_ring_buffers    
WHERE ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR') AS R(x)) a  CROSS JOIN sys.dm_os_sys_info sys ORDER BY DATEADD (ms, a.[Record Time] - sys.ms_ticks, GETDATE())
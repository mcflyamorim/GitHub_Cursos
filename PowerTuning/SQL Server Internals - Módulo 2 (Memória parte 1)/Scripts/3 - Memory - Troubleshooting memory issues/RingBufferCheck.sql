--System Memory Usage
SELECT EventTime,
       record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') AS [Type],
       record.value('(/Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [IndicatorsProcess],
       record.value('(/Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [IndicatorsSystem],
       record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') / 1024. AS [Avail Phys Mem, Mb],
       record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') /1024. AS [Avail VAS, Mb]
FROM
(
    SELECT DATEADD(ss, (-1 * ((cpu_ticks / CONVERT(FLOAT, (cpu_ticks / ms_ticks))) - [timestamp]) / 1000), GETDATE()) AS EventTime,
           CONVERT(XML, record) AS record
    FROM sys.dm_os_ring_buffers
        CROSS JOIN sys.dm_os_sys_info
    WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
) AS tab
ORDER BY EventTime DESC;
GO

SELECT CONVERT (varchar(30), GETDATE(), 121) as [RunTime],
dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), GETDATE()) as [Notification_Time],
cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') AS [Notification_type],
cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') AS [MemoryUtilization %],
cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') AS [Node Id],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') AS [Process_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') AS [System_Indicator],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') AS [type],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') AS [state],
cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') AS [reserved],
cast(record as xml).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') AS [Effect],
 
cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') / 1024. AS [SQL_ReservedMemory_MB],
cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') / 1024. AS [SQL_CommittedMemory_MB],
cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') AS [SQL_AWEMemory],
cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') AS [SinglePagesMemory],
cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') AS [MultiplePagesMemory],
cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') / 1024.AS [TotalPhysicalMemory_MB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') / 1024.AS [AvailablePhysicalMemory_MB],
cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') / 1024. AS [TotalPageFile_MB],
cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') / 1024. AS [AvailablePageFile_MB],
cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') / 1024. AS [TotalVirtualAddressSpace_MB],
cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') / 1024. AS [AvailableVirtualAddressSpace_MB],
cast(record as xml).value('(//Record/@id)[1]', 'bigint') AS [Record Id],
cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') AS [Type],
cast(record as xml).value('(//Record/@time)[1]', 'bigint') AS [Record Time],
tme.ms_ticks as [Current Time]
FROM sys.dm_os_ring_buffers rbf
cross join sys.dm_os_sys_info tme
where rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' --and cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
ORDER BY rbf.timestamp ASC
GO


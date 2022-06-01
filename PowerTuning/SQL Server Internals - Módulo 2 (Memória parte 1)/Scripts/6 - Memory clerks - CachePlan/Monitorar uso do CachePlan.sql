
SELECT * FROM sys.dm_os_memory_cache_counters
WHERE [type] = 'CACHESTORE_SQLCP' OR [type] = 'CACHESTORE_OBJCP'
GO

SELECT * FROM sys.dm_os_memory_cache_hash_tables
WHERE [type] = 'CACHESTORE_SQLCP' OR [type] = 'CACHESTORE_OBJCP'
GO

SELECT dm_os_memory_cache_clock_hands.*, DATEADD(ms, last_tick_time - info.ms_ticks, GETDATE()) FROM sys.dm_os_memory_cache_clock_hands
CROSS JOIN sys.dm_os_sys_info AS info
WHERE [type] = 'CACHESTORE_SQLCP' OR [type] = 'CACHESTORE_OBJCP'
GO

SELECT TOP 3 type, name, pages_kb / 1024. size_in_mb, pages_kb AS size_in_kb
FROM sys.dm_os_memory_clerks
ORDER BY pages_kb DESC
GO

--SELECT DATEADD(ss, (-1 * ((cpu_ticks / CONVERT(FLOAT, (cpu_ticks / ms_ticks))) - [timestamp]) / 1000), GETDATE()) AS EventTime,
--       CONVERT(XML, record) AS record,
--       ring_buffer_type
--FROM sys.dm_os_ring_buffers
--    CROSS JOIN sys.dm_os_sys_info
--WHERE ring_buffer_type NOT IN ('RING_BUFFER_SCHEDULER', 'RING_BUFFER_XE_LOG', 'RING_BUFFER_HOBT_SCHEMAMGR', 
--                               'RING_BUFFER_QE_MEM_BUFF_POOL_RESERVE', 'RING_BUFFER_XE_BUFFER_STATE', 'RING_BUFFER_SECURITY_ERROR',
--                               'RING_BUFFER_SCHEDULER_MONITOR', 'RING_BUFFER_SECURITY_CACHE', 'RING_BUFFER_CONNECTIVITY', 'RING_BUFFER_CLRAPPDOMAIN')
--ORDER BY 1 DESC;
--GO

-- Note: MEMORYBROKER_FOR_CACHE = Memory that is allocated for use by cached objects (Not Buffer Pool cache).
--SELECT DATEADD(ms, (Buffer.Record.value('@time', 'BIGINT') - info.ms_ticks), GETDATE()) AS [Notification_Time],
--       Data.ring_buffer_type AS [Type],
--       Buffer.Record.value('(MemoryBroker/Pool)[1]', 'INT') AS [Pool],
--       Buffer.Record.value('(MemoryBroker/Broker)[1]', 'NVARCHAR(128)') AS [Broker],
--       Buffer.Record.value('(MemoryBroker/Notification)[1]', 'NVARCHAR(128)') AS [Notification],
--       Buffer.Record.value('@time', 'BIGINT') AS [time],
--       Buffer.Record.value('@id', 'int') AS [Id],
--       Data.EventXML
--FROM
--(
--    SELECT CAST(record AS XML) AS EventXML,
--           ring_buffer_type
--    FROM sys.dm_os_ring_buffers
--    WHERE ring_buffer_type = 'RING_BUFFER_MEMORY_BROKER'
--) AS Data
--    CROSS APPLY EventXML.nodes('//Record') AS Buffer(Record)
--    CROSS JOIN sys.dm_os_sys_info AS info
--ORDER BY [Notification_Time] DESC;
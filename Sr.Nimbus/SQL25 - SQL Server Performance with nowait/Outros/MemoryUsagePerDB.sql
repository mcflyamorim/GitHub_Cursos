/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano.amorim@srnimbus.com.br
  http://www.srnimbus.com.br
  http://blogfabiano.com
*/

USE SrCheck_BD
GO

-- MetaData --
IF OBJECT_ID('MemoryUsagePerDB', 'u') IS NULL
BEGIN
  -- DROP TABLE MemoryUsagePerDB
  CREATE TABLE [dbo].MemoryUsagePerDB
  ([Database_Name] [nvarchar] (20),
   [Buffered_Page_Count] [int] NULL,
   [Buffer_Pool_MB] [int] NULL,
   Free_Space_MB [int],
   Capture_Date DateTime)
END
GO

-- Quanto de memória cada banco esta usando
INSERT INTO MemoryUsagePerDB
SELECT LEFT(CASE database_id 
              WHEN 32767 THEN 'ResourceDb' 
              ELSE db_name(database_id) 
            END, 20) AS Database_Name,
        count(*) AS Buffered_Page_Count,
       (count(*) * 8) / 1024 as Buffer_Pool_MB,
       (SUM(CONVERT(float, free_space_in_bytes)) / 1024.) / 1024. AS Free_Space_MB,
       GetDate() AS capture_Date
 FROM sys.dm_os_buffer_descriptors
GROUP BY db_name(database_id) ,database_id
ORDER BY Buffered_Page_Count DESC
GO

SELECT * FROM MemoryUsagePerDB
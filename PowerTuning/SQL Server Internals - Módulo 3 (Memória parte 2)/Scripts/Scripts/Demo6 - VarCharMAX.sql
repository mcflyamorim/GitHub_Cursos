/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
-- set the max server memory to 5GB
EXEC sp_configure 'max server memory', 5120
RECONFIGURE
GO


IF OBJECT_ID('TestMemoryGrantMAX') IS NOT NULL
  DROP TABLE TestMemoryGrantMAX
GO
CREATE TABLE TestMemoryGrantMAX(ID  INT IDENTITY (1,1) PRIMARY KEY,
                                 Col1 VarChar(MAX) DEFAULT NEWID(),
                                 Col2 VarChar(MAX) DEFAULT NEWID(),
                                 Col3 VarChar(MAX) DEFAULT NEWID(),
                                 Col4 VarChar(MAX) DEFAULT NEWID(),
                                 Col5 VarChar(MAX) DEFAULT NEWID(),
                                 Col6 VarChar(MAX) DEFAULT NEWID(),
                                 Col7 VarChar(MAX) DEFAULT NEWID(),
                                 Col8 VarChar(MAX) DEFAULT NEWID(),
                                 Col9 VarChar(MAX) DEFAULT NEWID(),
                                 Col10 VarChar(MAX) DEFAULT NEWID())
GO

INSERT INTO TestMemoryGrantMAX 
SELECT TOP 10000 CHECKSUM(NEWID()), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID()
  FROM sysobjects a, sysobjects b, sysobjects c
GO


-- Memory Grant = 503936KB. 
-- Excessive grant warning...
SELECT *
  FROM TestMemoryGrantMAX
 ORDER BY Col4


-- Same table with correct varchar sizes
IF OBJECT_ID('TestMemoryGrant250') IS NOT NULL
  DROP TABLE TestMemoryGrant250
GO
CREATE TABLE TestMemoryGrant250(ID  INT IDENTITY (1,1) PRIMARY KEY,
                                Col1 VarChar(250) DEFAULT NEWID(),
                                Col2 VarChar(250) DEFAULT NEWID(),
                                Col3 VarChar(250) DEFAULT NEWID(),
                                Col4 VarChar(250) DEFAULT NEWID(),
                                Col5 VarChar(250) DEFAULT NEWID(),
                                Col6 VarChar(250) DEFAULT NEWID(),
                                Col7 VarChar(250) DEFAULT NEWID(),
                                Col8 VarChar(250) DEFAULT NEWID(),
                                Col9 VarChar(250) DEFAULT NEWID(),
                                Col10 VarChar(250) DEFAULT NEWID())
GO

INSERT INTO TestMemoryGrant250 
SELECT TOP 10000 CHECKSUM(NEWID()), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID(), NEWID()
  FROM sysobjects a, sysobjects b, sysobjects c
GO


-- MemoryGranted = 16688 KB = 16MB
SELECT * 
  FROM TestMemoryGrant250
 ORDER BY Col4
GO


-- SQL QueryStress

sp_whoisactive
GO

SELECT * FROM sys.dm_os_waiting_tasks 
where session_id >= 50
-- WAIT_TYPE = RESOURCE_SEMAPHORE 
-- "Occurs when a query memory request cannot be granted immediately due to other concurrent queries. 
-- High waits and wait times may indicate excessive number of concurrent queries, *or excessive memory request amounts*."
-- http://technet.microsoft.com/en-us/library/ms179984.aspx
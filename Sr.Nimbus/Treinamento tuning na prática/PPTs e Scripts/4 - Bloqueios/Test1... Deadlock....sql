USE Northwind
GO
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Col1 Int IDENTITY(1,1) NOT NULL PRIMARY KEY, Col2 Int, Col3 Char(7500) DEFAULT NEWID())
GO
INSERT INTO Tab1(Col2) VALUES (1), (2), (3), (4), (5)
GO
INSERT INTO Tab1
(
    Col2
)
SELECT TOP 1000 ABS(CHECKSUM(NEWID())) / 100000 FROM Orders a, Orders b, Orders c

UPDATE Tab1 SET Col2 = Col1
GO
CREATE INDEX ix1 ON Tab1(Col2)
GO


-- Session 1
USE Northwind
GO
BEGIN TRAN

-- Update to get lock on row Col1 = 5
UPDATE Tab1 SET Col3 = NEWID()
 WHERE Col1 = 5
GO

-- Session 2
-- Query to seek + lookup with prefetch enabled
-- Row 5 is blocked by session 1, so I'll WAIT
SELECT *
  FROM Tab1
 WHERE Col2 <= 50
OPTION (RECOMPILE, MAXDOP 1)


-- Run following query on session 1
-- Can I grab a X lock on row 1? ... 
-- I should right? As Session 2 is running under ReadCommitted isolation level... 
UPDATE Tab1 SET Col2 = 9999
 WHERE Col1 = 1
GO


ROLLBACK TRAN



-- To fix... 
/*
  Use NOLOCK, RCSI or disable Prefetch using TF8744...
*/





-- Session 3
-- Open another session to see the locks for the command on session 2
sp_lock 54 -- ID da Session 2
-- Notice that the KEY locks are there...
-- Normal behavior is to release the row lock after read the row...






SELECT session_id, 
       CASE transaction_isolation_level 
         WHEN 0 THEN 'Unspecified' 
         WHEN 1 THEN 'ReadUncommitted' 
         WHEN 2 THEN 'ReadCommitted' 
         WHEN 3 THEN 'Repeatable' 
         WHEN 4 THEN 'Serializable' 
         WHEN 5 THEN 'Snapshot' 
       END AS Isolation_Level 
  FROM sys.dm_exec_sessions 
 WHERE session_id = 53
GO

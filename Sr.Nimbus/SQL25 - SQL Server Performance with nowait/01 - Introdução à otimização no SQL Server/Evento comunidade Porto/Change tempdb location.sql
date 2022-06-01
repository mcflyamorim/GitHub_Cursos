/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-- SET TEMPDB on SSD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'C:\temp\datatempdb.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'C:\temp\datatemplog.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2014 && net start MSSQL$SQL2014'
GO
SELECT * FROM tempdb.dbo.sysfiles
GO


-- SET TEMPDB on HDD
USE master
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = tempdev, FILENAME = 'D:\temp\datatempdb.mdf')
GO
ALTER DATABASE TempDB MODIFY FILE
(NAME = templog, FILENAME = 'D:\temp\datatemplog.ldf')
GO
EXEC xp_cmdShell 'net stop MSSQL$SQL2014 && net start MSSQL$SQL2014'
GO

SELECT * FROM tempdb.dbo.sysfiles
GO
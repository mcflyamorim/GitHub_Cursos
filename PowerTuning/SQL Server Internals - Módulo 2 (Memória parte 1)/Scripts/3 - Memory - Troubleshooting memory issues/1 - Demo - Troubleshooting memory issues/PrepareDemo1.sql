ALTER DATABASE Northwind SET RECOVERY FULL
BACKUP DATABASE Northwind TO DISK = 'C:\temp\NorthwindFullBackup.BAK' WITH COMPRESSION, INIT
BACKUP LOG Northwind TO DISK = 'C:\temp\NorthwindLogBackup.BAK' WITH COMPRESSION, INIT

IF OBJECT_ID('st_Call_fn_dump_dblog') IS NOT NULL
  DROP PROC st_Call_fn_dump_dblog
/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/

USE Northwind

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1;

RECONFIGURE;
-- set the max server memory to 10GB
EXEC sp_configure 'max server memory', 10240
RECONFIGURE

-- turn on TFs for mini dump  
dbcc traceon(2546, -1) 

-- set DUMP TRIGGER for exception 802 
-- SQLState: 42000, Native Error: 8651, Severity: 17, State: 1, Line: 1 
-- [SQL Server]Could not perform the operation because the requested memory grant was not available in resource pool 'default' (2).  Rerun the query, reduce the query load, or check resource governor configuration setting.
dbcc dumptrigger('set', 8651) 

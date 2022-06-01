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
-- set the max server memory to 2GB
EXEC sp_configure 'max server memory', 2048
RECONFIGURE


/*
  Author: Fabiano Neves Amorim
  E-Mail: fabiano_amorim@bol.com.br
  http://blogfabiano.com | twitter: @mcflyamorim
  http://www.simple-talk.com/author/fabiano-amorim/
*/
USE [master]
ALTER DATABASE [Northwind] SET AUTO_CREATE_STATISTICS ON
USE Northwind
IF OBJECT_ID('Tab1') IS NOT NULL DROP TABLE Tab1
CREATE TABLE Tab1 (ID INT IDENTITY(1,1), Col1 VARCHAR(250) DEFAULT NEWID())
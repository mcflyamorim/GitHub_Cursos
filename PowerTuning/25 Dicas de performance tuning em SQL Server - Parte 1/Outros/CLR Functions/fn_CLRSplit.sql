/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Enabling CLR
sp_configure 'clr enabled', 1
GO
RECONFIGURE
GO

-- Publishing Assembly
IF EXISTS(SELECT * FROM sys.assemblies WHERE name = 'Assembly_SplitStringMulti')
BEGIN
  IF OBJECT_ID('fn_SplitStringMulti') IS NOT NULL
    DROP FUNCTION fn_SplitStringMulti

  DROP ASSEMBLY Assembly_SplitStringMulti
END
GO
CREATE ASSEMBLY Assembly_SplitStringMulti FROM 'D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL11 - TSQL Expert\Scripts\CLR Functions\SplitStringMulti\SplitStringMulti\bin\Debug\SplitStringMulti.dll' WITH PERMISSION_SET = SAFE
GO

CREATE FUNCTION fn_CLRSplit (@instr nvarchar(MAX), @delimiter nvarchar(4000))
RETURNS TABLE(output nvarchar(4000))
AS
EXTERNAL NAME Assembly_SplitStringMulti.[UserDefinedFunctions].SplitString_Multi
GO

SELECT * FROM dbo.fn_CLRSplit('1;2;3;4;', ';')
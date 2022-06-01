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
IF EXISTS(SELECT * FROM sys.assemblies WHERE name = 'Assembly_PADL')
BEGIN
  IF OBJECT_ID('fn_PADL') IS NOT NULL
    DROP FUNCTION fn_PADL

  DROP ASSEMBLY Assembly_PADL
END
GO
CREATE ASSEMBLY Assembly_PADL FROM 'D:\Fabiano\Trabalho\Sr.Nimbus\Cursos\SQL25 - SQL Server Performance with nowait\SQL25\Outros\CLR Functions\PADL\PADL\bin\Debug\PADL.dll' WITH PERMISSION_SET = SAFE
GO

CREATE FUNCTION fn_PADL(@cString NVarChar(4000), @nLen smallint, @cPadCharacter NVarChar(10) = ' ' )
RETURNS NVarChar(4000) AS 
EXTERNAL NAME Assembly_PADL.[UD_String_functions_Transact_SQL_CS].[Padl] 
GO

SELECT dbo.fn_PADL('Fab', 10, '0')
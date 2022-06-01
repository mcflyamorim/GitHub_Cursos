/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE NorthWind
GO
IF OBJECT_ID('fn_HexaToDBCCPAGE') IS NOT NULL
BEGIN
  DROP FUNCTION fn_HexaToDBCCPAGE
END
GO
CREATE FUNCTION dbo.fn_HexaToDBCCPAGE (@Hexa VarBinary(50))
RETURNS VarChar(50)
AS
/*
Revised by: Fabiano Neves Amorim
E-Mail: fabiano_amorim@bol.com.br
http://fabianosqlserver.spaces.live.com/
http://www.simple-talk.com/author/fabiano-amorim/

Use:
SELECT dbo.fn_HexaToDBCCPAGE(0x593B04000100)

*/
BEGIN
  DECLARE @First_4        VarChar(4),
          @Middle_4       VarChar(4),
          @Last_4         VarChar(4),
          @DBName           VarChar(200),
          @File           VarBinary(20),
          @Page           VarBinary(20),
          @Hexa_Str       VarChar(50),
          @SQL            NVarChar(200),
          @DBID_File_Page VarChar(50);
          
  SET @Hexa_Str = CONVERT(VarChar(50),  @Hexa, 1)

  SET @DBName = DB_Name()

  SET @First_4  = SubString(@Hexa_Str, 3, 4)
  SET @Middle_4 = SubString(@Hexa_Str, 7, 4)
  SET @Last_4   = SubString(@Hexa_Str, 11, 4)
  
  SET @First_4  = SubString(@First_4, 3, 2)  + SubString(@First_4, 1, 2)
  SET @Middle_4 = SubString(@Middle_4, 3, 2) + SubString(@Middle_4, 1, 2)
  SET @Last_4   = SubString(@Last_4, 3, 2)   + SubString(@Last_4, 1, 2)

  SELECT @Page = CONVERT(VarBinary(50), '0x' + @Middle_4 + @First_4, 1),
         @File =  CONVERT(VarBinary(50),'0x' + @Last_4, 1);

  SET @DBID_File_Page = 'DBCC PAGE (' + @DBName + ',' + CONVERT(VarChar, CONVERT(Int, @File)) + ',' + CONVERT(VarChar, CONVERT(Int, @Page)) + ',3)'
  
  RETURN @DBID_File_Page
END
GO
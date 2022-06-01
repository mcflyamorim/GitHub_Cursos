/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
  SET @V1 = ''
  SET @V2 = ''
  SET @V3 = ''
  SET @V4 = ''
  SET @V5 = ''
  SET @V6 = ''
  SET @V7 = ''
  SET @V8 = ''
  SET @V9 = ''
  SET @V10 = ''
 	SET @i = @i + 1                   
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

GO

DECLARE @i Int, @Test1 int, @Start datetime
DECLARE @V1 Char(6),
        @V2 Char(6),
        @V3 Char(6),
        @V4 Char(6),
        @V5 Char(6),
        @V6 Char(6),
        @V7 Char(6),
        @V8 Char(6),
        @V9 Char(6),
        @V10 Char(6);

SET @Test1 = 0
SET @i = 0
SET @Start = GetDate()
WHILE @i < 5000000
BEGIN
SELECT @V1 = '',
       @V2 = '',
       @V3 = '',
       @V4 = '',
       @V5 = '',
       @V6 = '',
       @V7 = '',
       @V8 = '',
       @V9 = '',
       @V10 = '',
       @i = @i + 1;
END                                
SET @Test1 = DATEDIFF(ms, @Start, GetDate())
SELECT @test1

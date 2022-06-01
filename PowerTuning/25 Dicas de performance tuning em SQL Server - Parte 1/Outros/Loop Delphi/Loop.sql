DECLARE @i Int = 0

WHILE @i < 10000000 -- 10 millions of executions
BEGIN
  SET @i += 1;
END
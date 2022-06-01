DECLARE @i Int = 0

WHILE @i < 10000000 -- 10 millions of executions
BEGIN
  SET @i += 1;
END

/*
  Time to perform 1 trillion of executions:
  SELECT (10000000 / 4.)
  SELECT (1000000000 / 2500000.) / 60 --
  Results: 6.666 Scaring number :-)...
*/
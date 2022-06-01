/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE tempdb
go
SELECT convert(bigint, a.object_id) AS poskey1, 
       convert(bigint, b.object_id) AS poskey2,
       a.column_id * 10 + b.column_id * 1000 AS transkey, 
       a.name + b.name AS somedata, newid() AS somemoredata
INTO   transtable
FROM   sys.columns a
CROSS  JOIN sys.columns b
go
ALTER TABLE transtable ALTER COLUMN poskey1   bigint NOT NULL
ALTER TABLE transtable ALTER COLUMN poskey2   bigint NOT NULL
ALTER TABLE transtable ALTER COLUMN transkey int NOT NULL 
go 
ALTER TABLE transtable 
   ADD CONSTRAINT pk PRIMARY KEY (poskey1, poskey2, transkey) 
go
CREATE TABLE #newtrans (ident    int              IDENTITY,
                        poskey1  bigint          NOT NULL, 
                        poskey2  bigint          NOT NULL, 
                        transkey int              NOT NULL,
                        somedata uniqueidentifier NOT NULL DEFAULT newid()
                        PRIMARY KEY (ident)
)

INSERT #newtrans (poskey1, poskey2, transkey)
   SELECT TOP 10 poskey1, poskey2, transkey + 2 
   FROM   transtable 
   ORDER  BY newid()

go
SELECT  t.poskey1, t.poskey2, t.transkey, t.somedata
FROM    transtable t
WHERE   EXISTS (SELECT *
                FROM   #newtrans n
                WHERE  t.poskey1   = n.poskey1
                  AND  t.poskey2   = n.poskey2
                  AND  t.transkey > n.transkey)

SELECT  DISTINCT t.poskey1, t.poskey2, t.transkey, t.somedata
FROM    transtable t
JOIN    #newtrans n ON t.poskey1   = n.poskey1
                  AND  t.poskey2   = n.poskey2
                  AND  t.transkey > n.transkey OPTION (QUERYTRACEON 9481)  -- Use old estimator

SELECT  DISTINCT t.poskey1, t.poskey2, t.transkey, t.somedata
FROM    transtable t
JOIN    #newtrans n ON t.poskey1   = n.poskey1
                  AND  t.poskey2   = n.poskey2
                  AND  t.transkey > n.transkey --OPTION (LOOP JOIN) 
go 

DROP TABLE #newtrans DROP TABLE transtable

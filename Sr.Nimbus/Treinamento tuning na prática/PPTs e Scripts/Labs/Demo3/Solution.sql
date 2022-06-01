--CREATE INDEX ix1 ON CustomersBig(CompanyName, Col1) 
--GO

DECLARE @Top INT = 100; SELECT TOP (@Top) * FROM CustomersBig ORDER BY CompanyName, Col1 OPTION (MAXDOP 1)
DECLARE @Top INT = 100; SELECT TOP (@Top) * FROM CustomersBig ORDER BY CompanyName, Col1 OPTION (MAXDOP 1, RECOMPILE)


SELECT TOP 100 * FROM CustomersBig ORDER BY CompanyName, Col1 OPTION (MAXDOP 1)
GO
SELECT TOP 101 * FROM CustomersBig ORDER BY CompanyName, Col1 OPTION (MAXDOP 1)
GO
SELECT c.*
  FROM (SELECT TOP 101 CustomerID FROM CustomersBig ORDER BY CompanyName, Col1) AS Tab1
 INNER JOIN CustomersBig c
    ON c.CustomerID = Tab1.CustomerID
 ORDER BY c.CompanyName, c.Col1 DESC OPTION (MAXDOP 1)
GO



-- OFFSET FETCH NEXT do SQL 2012
DECLARE @PageNumber AS INT, @RowspPage AS INT
SET @PageNumber = 3
SET @RowspPage = 50 

SELECT *
  FROM CustomersBig
ORDER BY CompanyName, Col1
OFFSET ((@PageNumber - 1) * @RowspPage) ROWS
FETCH NEXT @RowspPage ROWS ONLY
OPTION (MAXDOP 1, RECOMPILE);

USE TempDB
SET NOCOUNT ON;
GO

IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1 (Col1 Int)
GO

INSERT INTO Tab1 VALUES(5), (5), (3) , (1)
GO

-- LEAD
SELECT Col1, 
       LEAD(Col1) OVER(ORDER BY Col1) AS "LAG()"
  FROM Tab1
GO
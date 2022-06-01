USE Northwind
GO

IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VarChar(250), NEWID()) AS Col1,
       3 AS StatusID
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO

ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

IF OBJECT_ID('TabStatus') IS NOT NULL
  DROP TABLE TabStatus
GO
CREATE TABLE TabStatus (ColStatus VarCHAR(10) PRIMARY KEY,
                        Val VARCHAR(200))
GO
INSERT INTO TabStatus (ColStatus, Val) VALUES('A', 'Albert'), ('B', 'Bart'), ('C', 'Charles'), ('D', 'Dan'), ('E', 'Ed')
GO
BEGIN TRAN
GO
INSERT INTO TabStatus (ColStatus, Val)
SELECT SUBSTRING(CONVERT(VarChar(250), NEWID(), 1), 1, 10) ,ABS(CheckSUM(NEWID()) / 10000000)
GO 1000
COMMIT
GO

SELECT 
   OrdersBig.OrderID, 
   OrdersBig.CustomerID, 
   OrdersBig.Value, 
   OrdersBig.OrderDate, 
   ISNULL(
      (
         SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'A'
      ), '') + case CustomersBig.Col1  when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
         SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'B'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/'
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'   
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
         SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'C'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''), 
   ISNULL(
      (
        SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'D'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
        SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'E'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
        SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'F'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, ''),
   ISNULL(
      (
        SELECT TabStatus.Val
         FROM TabStatus
         WHERE TabStatus.ColStatus = 'G'
      ), '') + case CustomersBig.Col1 when 'RD' then 'a/' 
					when 'SD' then 'a/'
					when 'WD' then 'a/'
					when 'XD' then 'a/'  
					else '' end + ISNULL(OrdersBig.Col1, '')

FROM CustomersBig
join OrdersBig ON OrdersBig.CustomerID = CustomersBig.CustomerID
WHERE OrdersBig.Value BETWEEN 1 AND 1.3
OPTION (RECOMPILE)
GO





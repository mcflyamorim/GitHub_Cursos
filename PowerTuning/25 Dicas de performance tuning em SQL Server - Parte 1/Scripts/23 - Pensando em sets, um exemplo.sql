USE Northwind
GO

IF OBJECT_ID('CustomersTMP') IS NOT NULL
  DROP TABLE CustomersTMP 
GO
SELECT * 
  INTO CustomersTMP 
  FROM Customers
GO


-- Como melhorar esse código?
DECLARE @CustomerID INT, @City VARCHAR(200)
DECLARE C
 CURSOR FOR 
 SELECT CustomerID, City
   FROM CustomersTMP

OPEN C
FETCH NEXT FROM C INTO @CustomerID, @City
WHILE @@FETCH_STATUS = 0
BEGIN
  IF @City = 'London'
    UPDATE CustomersTMP SET Country = 'France 1'
     WHERE CustomerID = @CustomerID

   FETCH NEXT FROM C INTO @CustomerID, @City
END
CLOSE C
DEALLOCATE C
GO
















-- Pode ser assim? 
UPDATE CustomersTMP SET Country = 'France 1'
 WHERE City = 'London'
GO
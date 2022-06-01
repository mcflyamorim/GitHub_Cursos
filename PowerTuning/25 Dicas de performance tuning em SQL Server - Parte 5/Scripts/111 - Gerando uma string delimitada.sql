USE Northwind
GO
CREATE INDEX ixCustomerID ON OrdersBig (CustomerID)
GO

SELECT TOP 10
       CustomerID,
       ContactName,
       ISNULL(Tab1.Col, '') AS Col1
  FROM CustomersBig
 CROSS APPLY ((SELECT TOP 5 CONVERT(VarChar(30), OrderID) + ';' AS "text()"
                 FROM OrdersBig 
                WHERE OrdersBig.CustomerID = CustomersBig.CustomerID 
                  FOR XML PATH(''))) AS Tab1 (Col)
  ORDER BY Tab1.Col DESC
GO

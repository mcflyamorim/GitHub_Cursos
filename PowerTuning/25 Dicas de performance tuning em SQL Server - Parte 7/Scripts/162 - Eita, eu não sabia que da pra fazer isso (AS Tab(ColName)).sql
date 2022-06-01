USE Northwind
GO


SELECT Orders.OrderID, Tab1.*
  FROM Orders
 CROSS APPLY (SELECT MAX(CustomerID) FROM Customers) AS Tab1
GO


SELECT Orders.OrderID, Tab1.*
  FROM Orders
 CROSS APPLY (SELECT MAX(CustomerID) FROM Customers) AS Tab1(MaxCustomerID)
GO
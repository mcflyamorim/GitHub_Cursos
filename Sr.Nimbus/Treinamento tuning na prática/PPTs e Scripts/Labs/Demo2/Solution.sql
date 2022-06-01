DECLARE @stmt nvarchar(max);
DECLARE @params nvarchar(max);
EXEC sp_get_query_template N'SELECT Orders.OrderID, COUNT(DISTINCT Orders.CustomerID), SUM(Orders.Value) FROM Orders INNER JOIN Customers ON Customers.CustomerID = Orders.CustomerID INNER JOIN Order_Details ON Order_Details.OrderID = Orders.OrderID INNER JOIN Products ON Products.ProductID = Order_Details.ProductID WHERE Products.ProductName = ''8D207EEA-6B78-41F7-96FD-3B7561BF5C67'' GROUP BY Orders.OrderID',
	@stmt OUTPUT, @params OUTPUT;
	
EXEC sp_create_plan_guide 
	  N'TemplateGuide1', 
	  @stmt, 
	  N'TEMPLATE', 
	  NULL, 
	  @params, 
	  N'OPTION(PARAMETERIZATION FORCED)';
GO

----Drop the plan guide.  
--EXEC sp_control_plan_guide N'DROP', N'TemplateGuide1';  
--GO  
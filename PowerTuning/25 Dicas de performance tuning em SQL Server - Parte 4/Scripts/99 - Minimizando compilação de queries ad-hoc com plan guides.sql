USE AdventureWorks2017
GO

-- Query ad-hoc... gera compilação para cada execução

DECLARE  @Var  VarChar(250),  @SQL  VarChar(MAX)
SET  @Var  =  NEWID()
SET  @SQL  = 
'SELECT SalesOrderHeader.SalesPersonID,
       COUNT(DISTINCT SalesOrderHeader.CustomerID),  
       SUM(SalesOrderDetail.OrderQty)
  FROM Sales.SalesOrderHeader
 INNER JOIN Sales.SalesOrderDetail
    ON SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
 INNER JOIN Production.Product
    ON Product.ProductID = SalesOrderDetail.ProductID
 WHERE Product.Name = '  +  ''''  +  @Var  +  '''
 GROUP BY SalesOrderHeader.SalesPersonID'

EXEC (@SQL)
GO



USE [AdventureWorks2017]
GO

-- Criando guide plan com PARAMETERIZATION FORCED para resolver o problema...
DECLARE  @stmt  nvarchar(max);
DECLARE  @params  nvarchar(max);
EXEC  sp_get_query_template  
N'SELECT SalesOrderHeader.SalesPersonID,
       COUNT(DISTINCT SalesOrderHeader.CustomerID),  
       SUM(SalesOrderDetail.OrderQty)
  FROM Sales.SalesOrderHeader
 INNER JOIN Sales.SalesOrderDetail
    ON SalesOrderDetail.SalesOrderID = SalesOrderHeader.SalesOrderID
 INNER JOIN Production.Product
    ON Product.ProductID = SalesOrderDetail.ProductID
 WHERE Product.Name = ''3514C79D-12C2-4673-A5E3-8961F392B396''
 GROUP BY SalesOrderHeader.SalesPersonID',
 @stmt  OUTPUT,  @params  OUTPUT;

EXEC  sp_create_plan_guide
     N'TemplateGuide1', 
     @stmt, 
     N'TEMPLATE', 
     NULL, 
     @params, 
     N'OPTION(PARAMETERIZATION FORCED)';
GO


USE [AdventureWorks2017]
GO

EXEC sp_control_plan_guide @operation = N'DROP', @name = N'[TemplateGuide1]'
GO


/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/




USE NorthWind
GO

/*
  Assert
*/


-- Preparar ambiente... Criar tabelas com 1 milhão de linhas...
USE NorthWind
GO
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000 IDENTITY(Int, 1,1) AS OrderID,
       A.CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B
 CROSS JOIN Orders C
 CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO

IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000 
       IDENTITY(Int, 1,1) AS CustomerID,
       a.CityID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B
 CROSS JOIN Customers C
 CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO
UPDATE TOP (30) PERCENT CustomersBig SET CityID = NULL
GO
ALTER TABLE [dbo].[OrdersBig]  WITH CHECK ADD  CONSTRAINT [fk_OrdersBig_CustomersBig] FOREIGN KEY([CustomerID])
REFERENCES [dbo].[CustomersBig] ([CustomerID]) ON DELETE CASCADE ON UPDATE CASCADE
GO


/*
  Check Constraints
*/
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
GO
CREATE TABLE Tab1(ID Integer, Sexo CHAR(1)) 
GO 
ALTER TABLE TAB1 ADD CONSTRAINT ck_Sexo_M_F CHECK(Sexo IN('M','F')) 
GO

/*
  Se o Value retornado pela expressão do Assert
  CASE 
    WHEN [NorthWind].[dbo].[Tab1].[Sexo]<>'F' AND [NorthWind].[dbo].[Tab1].[Sexo]<>'M' THEN (0) 
    ELSE NULL
  END
*/
-- Assert validando Check Constraints
INSERT INTO Tab1(ID, Sexo) VALUES(1,'X')
GO


/*
  Foreign Keys Constraints
*/
ALTER TABLE Tab1 ADD ID_Sexos INT
ALTER TABLE Tab1 DROP CONSTRAINT ck_Sexo_M_F
ALTER TABLE Tab1 DROP COLUMN Sexo
GO 
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
CREATE TABLE Tab2(ID Integer PRIMARY KEY, Sexo CHAR(1)) 
GO 
INSERT INTO Tab2(ID, Sexo) VALUES(1, 'F')
INSERT INTO Tab2(ID, Sexo) VALUES(2, 'M')
INSERT INTO Tab2(ID, Sexo) VALUES(3, 'N')
GO 
ALTER TABLE Tab1 ADD CONSTRAINT fk_Tab2 FOREIGN KEY (ID_Sexos) REFERENCES Tab2(ID)
GO

/*
  Assert valida a expressão [Expr1007] que é retornado
  como Probe column do "Left Semi Join"
  No loop join se o Value passado no insert fizer join com 
  a tabela Tab2 então o Value do join será retornado,
  caso contrario ele irá retornar NULL
  Se ele for NULL é porque o Value não existe,
  neste caso a expressão do assert irá retornar "0"
  o que faz com que a exceção seja gerada.
  
  CASE 
    WHEN NOT [Pass1008] AND [Expr1007] IS NULL THEN (0) 
    ELSE NULL 
  END
*/
-- Assert validando Foreign Keys Constraints
INSERT INTO Tab1(ID, ID_Sexos) VALUES(1, 4)

-- Quando não utilizada a coluna com a foreign key o SQL 
-- não utiliza o Assert
INSERT INTO Tab1(ID) VALUES(1)

-- Quando especificado NULL o SQL não utiliza o Assert
INSERT INTO Tab1(ID, ID_Sexos) VALUES(1, NULL)

-- Porém quando passada uma variável o SQL não
-- sabe que o Value é NULL ele usa o Assert e faz
-- o join com a tabela relacionada
DECLARE @i Int
INSERT INTO Tab1(ID, ID_Sexos) VALUES(1, @i)
GO

/*
  Nota: Pergunta, compensa fazer uma validação e passar somente 
  a coluna que será utiliza no insert?
  Resposta: Depende, na maioria dos casos não compensa.
  
  Teste com o SQLQuery Stress(Adam Machanic)
  Número de Iterações: 500
  Número de Threads: 40
  
  -- Média 19.7 segundos
  INSERT INTO NorthWind.dbo.OrdersBig(CustomerID, OrderDate, Value)
  VALUES (1, GetDate(), 0)

  -- Média 15.1 segundos
  DECLARE @CustomerID Int
  IF @CustomerID IS NOT NULL
  BEGIN
    INSERT INTO NorthWind.dbo.OrdersBig(CustomerID, OrderDate, Value)
    VALUES (@CustomerID, GetDate(), 0)
  END
  ELSE 
  BEGIN
    INSERT INTO NorthWind.dbo.OrdersBig(CustomerID, OrderDate, Value)
    VALUES (NULL, GetDate(), 0)
  END


-- Outro teste no AdventureWorks2012

use AdventureWorks2012
GO
-- SELECT * FROM Sales.SalesOrderHeader

--ALTER TABLE Sales.SalesOrderHeader ALTER COLUMN ShipMethodID Int null
--ALTER TABLE Sales.SalesOrderHeader ALTER COLUMN BillToAddressID Int null
--ALTER TABLE Sales.SalesOrderHeader ALTER COLUMN ShipToAddressID Int null
--GO

BEGIN TRAN
DECLARE @SalesPersonID Int = NULL,
        @TerritoryID Int = NULL,
        @BillToAddressID Int = NULL,
        @ShipToAddressID Int = NULL,
        @ShipMethodID Int = NULL,
        @CreditCardID Int = NULL,
        @CurrencyRateID Int = NULL

insert into Sales.SalesOrderHeader
        ( RevisionNumber,
          OrderDate,
          DueDate,
          ShipDate,
          Status,
          OnlineOrderFlag,
          PurchaseOrderNumber,
          AccountNumber,
          CustomerID,
          SalesPersonID,
          TerritoryID,
          BillToAddressID,
          ShipToAddressID,
          ShipMethodID,
          CreditCardID,
          CreditCardApprovalCode,
          CurrencyRateID,
          SubTotal,
          TaxAmt,
          Freight,
          Comment,
          rowguid,
          ModifiedDate
        )
VALUES  ( 0, -- RevisionNumber - tinyint
          GETDATE(), -- OrderDate - datetime
          GETDATE(), -- DueDate - datetime
          GETDATE(), -- ShipDate - datetime
          0, -- Status - tinyint
          1, -- OnlineOrderFlag - Flag
          -99, -- PurchaseOrderNumber - OrderNumber
          NULL, -- AccountNumber - AccountNumber
          1, -- CustomerID - int
          @SalesPersonID, -- SalesPersonID - int
          @TerritoryID, -- TerritoryID - int
          @BillToAddressID, -- BillToAddressID - int
          @ShipToAddressID, -- ShipToAddressID - int
          @ShipMethodID, -- ShipMethodID - int
          @CreditCardID, -- CreditCardID - int
          '', -- CreditCardApprovalCode - varchar(15)
          @CurrencyRateID, -- CurrencyRateID - int
          999, -- SubTotal - money
          999, -- TaxAmt - money
          999, -- Freight - money
          N'', -- Comment - nvarchar(128)
          NEWID(), -- rowguid - uniqueidentifier
          GETDATE()  -- ModifiedDate - datetime
        )
ROLLBACK TRAN
GO


BEGIN TRAN
DECLARE @SalesPersonID Int = NULL,
        @TerritoryID Int = NULL,
        @BillToAddressID Int = NULL,
        @ShipToAddressID Int = NULL,
        @ShipMethodID Int = NULL,
        @CreditCardID Int = NULL,
        @CurrencyRateID Int = NULL

insert into Sales.SalesOrderHeader
        ( RevisionNumber,
          OrderDate,
          DueDate,
          ShipDate,
          Status,
          OnlineOrderFlag,
          PurchaseOrderNumber,
          AccountNumber,
          CustomerID,
          SalesPersonID,
          TerritoryID,
          BillToAddressID,
          ShipToAddressID,
          ShipMethodID,
          CreditCardID,
          CreditCardApprovalCode,
          CurrencyRateID,
          SubTotal,
          TaxAmt,
          Freight,
          Comment,
          rowguid,
          ModifiedDate
        )
VALUES  ( 0, -- RevisionNumber - tinyint
          GETDATE(), -- OrderDate - datetime
          GETDATE(), -- DueDate - datetime
          GETDATE(), -- ShipDate - datetime
          0, -- Status - tinyint
          1, -- OnlineOrderFlag - Flag
          -99, -- PurchaseOrderNumber - OrderNumber
          NULL, -- AccountNumber - AccountNumber
          1, -- CustomerID - int
          NULL, -- SalesPersonID - int
          NULL, -- TerritoryID - int
          NULL, -- BillToAddressID - int
          NULL, -- ShipToAddressID - int
          NULL, -- ShipMethodID - int
          NULL, -- CreditCardID - int
          '', -- CreditCardApprovalCode - varchar(15)
          NULL, -- CurrencyRateID - int
          999, -- SubTotal - money
          999, -- TaxAmt - money
          999, -- Freight - money
          N'', -- Comment - nvarchar(128)
          NEWID(), -- rowguid - uniqueidentifier
          GETDATE()  -- ModifiedDate - datetime
        )
--OPTION (RECOMPILE)
ROLLBACK TRAN
GO

*/

/*
  Operador de StreamAggregate faz o count e caso o
  resultador for maior que 1 então o assert retorna zero,
  ou seja, erro.
  
  CASE 
    WHEN [Expr1008]>(1) THEN (0) 
    ELSE NULL 
  END
*/
-- Assert validando Foreign Keys Constraints
SELECT (SELECT ContactName FROM Customers),
       *
  FROM Customers
/*
  Casos onde o QO identifica que não é necessário o Assert+StreamAggregate
*/
SELECT (SELECT TOP 1 ContactName FROM Customers),
       *
  FROM Customers
GO

SELECT (SELECT ContactName FROM Customers WHERE CustomerID = 1),
       *
  FROM Customers
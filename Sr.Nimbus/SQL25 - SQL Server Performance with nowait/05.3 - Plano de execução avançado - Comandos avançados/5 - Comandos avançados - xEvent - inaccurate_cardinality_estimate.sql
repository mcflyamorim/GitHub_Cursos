/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

USE Northwind
GO

-- Preparar ambiente... Criar tabelas com 1 milhão de linhas...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS OrderID,
       ABS(CheckSUM(NEWID()) / 10000000) AS CustomerID,
       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
  INTO OrdersBig
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY(OrderID)
GO
IF OBJECT_ID('CustomersBig') IS NOT NULL
  DROP TABLE CustomersBig
GO
SELECT TOP 1000000
       IDENTITY(Int, 1,1) AS CustomerID,
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS CompanyName, 
       SubString(CONVERT(VarChar(250),NEWID()),1,20) AS ContactName, 
       CONVERT(VarChar(250), NEWID()) AS Col1, 
       CONVERT(VarChar(250), NEWID()) AS Col2
  INTO CustomersBig
  FROM Customers A
 CROSS JOIN Customers B CROSS JOIN Customers C CROSS JOIN Customers D
GO
ALTER TABLE CustomersBig ADD CONSTRAINT xpk_CustomersBig PRIMARY KEY(CustomerID)
GO



-- Utilizar variáveis locais impede a estimativa utilizando histograma...
DECLARE @dt Date = '19850101'
SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate >= @dt
OPTION (MAXDOP 1)

-- Estima que será retornado 30% da tabela OrdersBig... porém retorna muito mais...
-- If the Event Session exists DROP it
IF EXISTS (SELECT 1 
             FROM sys.server_event_sessions 
            WHERE name = 'xEvent_inaccurate_cardinality_estimate')
BEGIN
  DROP EVENT SESSION xEvent_inaccurate_cardinality_estimate ON SERVER
END
GO

CREATE EVENT SESSION xEvent_inaccurate_cardinality_estimate 
    ON SERVER
   ADD EVENT sqlserver.inaccurate_cardinality_estimate (ACTION (sqlserver.plan_handle, sqlserver.sql_text))
   ADD TARGET package0.ring_buffer
  WITH (STARTUP_STATE=ON);
GO

-- Iniciar sessão
ALTER EVENT SESSION xEvent_inaccurate_cardinality_estimate
ON SERVER
STATE=START;
GO


-- Watch live data no SSMS

-- Utilizar variáveis locais impede a estimativa utilizando histograma...
-- Between estima que 9% da tabela será retornada... ou seja, 90 mil linhas...
DECLARE @dt1 Date = '19850101', 
        @dt2 Date = '20300101'

SELECT COUNT(*)
  FROM OrdersBig
 INNER JOIN CustomersBig
    ON OrdersBig.CustomerID = CustomersBig.CustomerID
 WHERE OrdersBig.OrderDate BETWEEN @dt1 AND @dt2
OPTION (MAXDOP 1)
GO



-- Ver o plano com o PlanHandle
SELECT * FROM sys.dm_exec_query_plan (0x06000500E7B6901900B6E8D50300000001000000000000000000000000000000000000000000000000000000);
GO

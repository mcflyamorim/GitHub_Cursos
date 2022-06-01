/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE Northwind
GO

-- Rodar apenas se necessário

-- Criar tablea de 20 milhoes para efetuar os testes
--IF OBJECT_ID('OrdersBig_v1') IS NOT NULL
--BEGIN
--  DROP TABLE OrdersBig_v1
--END
--GO
--SELECT TOP 20000000 IDENTITY(Int, 1,1) AS OrderID,
--       A.CustomerID,
--       CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)) AS OrderDate,
--       ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0) AS Value
--  INTO OrdersBig_v1
--  FROM Orders A
-- CROSS JOIN Orders B
-- CROSS JOIN Orders C
-- CROSS JOIN Orders D
--GO
--ALTER TABLE OrdersBig_v1 ADD CONSTRAINT xpk_OrdersBig_v1 PRIMARY KEY(OrderID)
--GO

-- Colocar tabela em cache
SELECT COUNT(*) FROM OrdersBig_v1
GO


IF OBJECT_ID('Tab_TMP') IS NOT NULL
  DROP TABLE Tab_TMP
GO
-- Operação de Table Insert rodando em paralelo
SET STATISTICS TIME ON
SELECT *
  INTO Tab_TMP
  FROM OrdersBig_v1
SET STATISTICS TIME OFF

-- Ver plano serial no SQL2012

/*
 -- SQL2014
 SQL Server Execution Times:
   CPU time = 27019 ms,  elapsed time = 15055 ms.

 -- SQL2012
 SQL Server Execution Times:
   CPU time = 17940 ms,  elapsed time = 19066 ms.
*/
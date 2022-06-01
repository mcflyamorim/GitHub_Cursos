USE Northwind
GO
-- Preparando demo...
IF OBJECT_ID('OrdersBig') IS NOT NULL
  DROP TABLE OrdersBig
GO
CREATE TABLE OrdersBig (OrderID int NOT NULL IDENTITY(1, 1),
                        CustomerID int NULL,
                        PaymentType CHAR(1),
                        InternalPayment INT NULL,
                        ExternalPayment INT NULL,
                        OrderDate date NULL,
                        Value numeric (18, 2) NOT NULL)
GO
INSERT INTO OrdersBig(CustomerID, OrderDate, Value)
SELECT TOP 100000
       ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000))),
       CONVERT(Date, GetDate() - ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000)))),
       ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5)))
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d
GO
ALTER TABLE OrdersBig ADD CONSTRAINT xpk_OrdersBig PRIMARY KEY CLUSTERED  (OrderID)
GO
ALTER TABLE OrdersBig ADD CountCol VarChar(20)
GO
UPDATE TOP (50) PERCENT OrdersBig SET CountCol = 'Count'
WHERE CountCol IS NULL
GO
UPDATE TOP (50) PERCENT OrdersBig SET CountCol = 'CountDistinct'
WHERE CountCol IS NULL
GO
UPDATE OrdersBig SET CountCol = 'CountDistinct_1'
WHERE CountCol IS NULL
GO
UPDATE TOP (80) PERCENT OrdersBig SET PaymentType = 'I'
WHERE PaymentType IS NULL
GO
UPDATE OrdersBig SET PaymentType = 'E'
WHERE PaymentType IS NULL
GO
UPDATE TOP (80) PERCENT OrdersBig SET InternalPayment = 
                                      ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000)))
WHERE InternalPayment IS NULL
GO
UPDATE OrdersBig SET ExternalPayment = ABS(CONVERT(Int, (CheckSUM(NEWID()) / 10000000)))
WHERE InternalPayment IS NULL
GO
IF OBJECT_ID('PaymentInfo') IS NOT NULL
  DROP TABLE PaymentInfo
GO
CREATE TABLE PaymentInfo (PaymentID INT IDENTITY(1,1) PRIMARY KEY, 
                          InternalPayment INT,
                          ExternalPayment INT)
GO
INSERT INTO PaymentInfo (InternalPayment)
SELECT DISTINCT InternalPayment
  FROM OrdersBig 
 WHERE InternalPayment IS NOT NULL
GO
INSERT INTO PaymentInfo (ExternalPayment)
SELECT DISTINCT ExternalPayment
  FROM OrdersBig 
 WHERE ExternalPayment IS NOT NULL
GO
CREATE INDEX ixExternalPayment ON PaymentInfo(ExternalPayment)
CREATE INDEX ixInternalPayment ON PaymentInfo(InternalPayment)
GO
CHECKPOINT
GO



-- Query endemoniada...
SELECT a.CustomerID,
       a.Value,
       PaymentInfo.PaymentID
  FROM OrdersBig AS a
  LEFT JOIN PaymentInfo
    ON CASE 
         WHEN a.PaymentType = 'I' THEN a.InternalPayment
         ELSE PaymentInfo.ExternalPayment
       END
       =  
       CASE 
         WHEN a.PaymentType = 'I' THEN PaymentInfo.InternalPayment
         ELSE a.ExternalPayment
       END
 ORDER BY CustomerID, Value
OPTION (MAXDOP 1)


-- Alternativa...

-- Jogar os dados para uma tabela temporária...
-- Não preencher PaymentID... ou seja, vamos remover o join pesado...
IF OBJECT_ID('tempdb.dbo.#TMP1') IS NOT NULL
  DROP TABLE #TMP1

SELECT CustomerID,
       Value,
       CONVERT(INT, NULL) AS PaymentID,
       PaymentType,
       InternalPayment,
       ExternalPayment
  INTO #TMP1
  FROM OrdersBig
OPTION (MAXDOP 1)

-- Agora criar índices para ajudar no join... índices filtrados... boa alternativa...
CREATE INDEX ixInternalPayment ON #TMP1 (InternalPayment) WHERE PaymentType = 'I'
CREATE INDEX ixExternalPayment ON #TMP1 (ExternalPayment) WHERE PaymentType = 'E'

-- Preencher os dados para PaymentType = 'I' 
UPDATE #TMP1 SET PaymentID = PaymentInfo.PaymentID
  FROM #TMP1
 INNER JOIN PaymentInfo
    ON PaymentInfo.InternalPayment = #TMP1.InternalPayment
 WHERE #TMP1.PaymentType = 'I' 

-- Preencher os dados para PaymentType = 'E' 
UPDATE #TMP1 SET PaymentID = PaymentInfo.PaymentID
  FROM #TMP1
 INNER JOIN PaymentInfo
    ON PaymentInfo.ExternalPayment = #TMP1.ExternalPayment
 WHERE #TMP1.PaymentType = 'E' 

-- Pronto...
SELECT CustomerID,
       Value,
       PaymentID 
  FROM #TMP1
 ORDER BY CustomerID, Value

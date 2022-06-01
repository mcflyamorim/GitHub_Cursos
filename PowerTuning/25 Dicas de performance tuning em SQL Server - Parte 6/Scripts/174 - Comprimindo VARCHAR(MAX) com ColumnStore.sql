/*
  Columstore e Compression:

  1 - Comprime os dados in-row, ou seja, se couber nos 8KB da página columnstore comprime...
  2 - Comprime também os dados of-row,  ou seja, que não cabe na página de 8kb, porém apenas dados com tamanho entre 8KB e 16MB
  2.1 - Logo, dados > 16MB, não são comprimidos...
*/

USE Northwind
GO
-- 22 segundos pra rodar...
IF OBJECT_ID('TestCompression') IS NOT NULL
  DROP TABLE TestCompression
GO
SELECT TOP 10000000
       IDENTITY(INT, 1,1) AS OrderID,
       ABS(CHECKSUM(NEWID()) / 10000000) AS CustomerID,
       ABS(CHECKSUM(NEWID()) / 10000000) AS EmployeeID,
       CONVERT(DATE, GETDATE() - (CHECKSUM(NEWID()) / 1000000)) AS OrderDate,
       ISNULL(ABS(CONVERT(NUMERIC(18,2), (CHECKSUM(NEWID()) / 1000000.5))),0) AS Value,
       CONVERT(VARCHAR(MAX), 'Alguma coisa aqui...' + CONVERT(VARCHAR(250), NEWID())) AS ColXML
  INTO TestCompression
  FROM Orders A
 CROSS JOIN Orders B CROSS JOIN Orders C CROSS JOIN Orders D
GO
CREATE CLUSTERED INDEX ix1 ON TestCompression (OrderID)
GO

sp_spaceused TestCompression -- SELECT 943312 / 1024. = 921.203125
GO

-- Como fica se aplicarmos compressão? 
ALTER INDEX ix1 ON TestCompression REBUILD WITH (DATA_COMPRESSION=PAGE)
GO
sp_spaceused TestCompression -- SELECT 616848 / 1024. = 602.390625
GO


-- E com o columnstore comprimindo inclusive os dados do VARCHAR MAX?
-- 19 segundos pra rodar...
CREATE CLUSTERED COLUMNSTORE INDEX ix1 ON TestCompression
WITH (DROP_EXISTING = ON);
GO
sp_spaceused TestCompression -- SELECT 371016 / 1024. = 362.320312
GO

-- WOW, de 921 pra 362mb...


-- Se quiser fazer um teste, da pra chamar a sp_estimate_data_compression_savings (opção pra columnstore só no SQL2019)
-- Demora 1 min e 10 segundos pra rodar

EXEC sys.sp_estimate_data_compression_savings
     @schema_name      = N'dbo',
     @object_name      = N'TestCompression',
     @index_id         = NULL,
     @partition_number = NULL, 
     @data_compression = N'NONE'; 
GO

EXEC sys.sp_estimate_data_compression_savings
     @schema_name      = N'dbo',
     @object_name      = N'TestCompression',
     @index_id         = NULL,
     @partition_number = NULL, 
     @data_compression = N'ROW'; 
GO

EXEC sys.sp_estimate_data_compression_savings
     @schema_name      = N'dbo',
     @object_name      = N'TestCompression',
     @index_id         = NULL,
     @partition_number = NULL, 
     @data_compression = N'PAGE'; 
GO

EXEC sys.sp_estimate_data_compression_savings
     @schema_name      = N'dbo',
     @object_name      = N'TestCompression',
     @index_id         = NULL,
     @partition_number = NULL, 
     @data_compression = N'COLUMNSTORE'; 
GO

EXEC sys.sp_estimate_data_compression_savings
     @schema_name      = N'dbo',
     @object_name      = N'TestCompression',
     @index_id         = NULL,
     @partition_number = NULL, 
     @data_compression = N'COLUMNSTORE_ARCHIVE'; 
GO

/*
  Fabiano Neves Amorim
  http://blogfabiano.com
  mailto:fabianonevesamorim@hotmail.com
*/

USE Northwind
GO

DROP TABLE IF EXISTS [Merchant]
DROP TABLE IF EXISTS [MerchantAssetDefault]
GO

CREATE TABLE [dbo].[Merchant]
(
  [Id] [bigint] NOT NULL IDENTITY(1, 1),
  [Name] VARCHAR(500) NOT NULL,
  [URL] VARCHAR(500) NOT NULL,
  [ConfigurationId] [bigint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Merchant] ADD CONSTRAINT [PK_Merchant] PRIMARY KEY CLUSTERED ([Id]) WITH (FILLFACTOR=80, IGNORE_DUP_KEY=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Merchant_ConfigurationId] ON [dbo].[Merchant] ([ConfigurationId]) 
WITH(IGNORE_DUP_KEY=ON)
ON [PRIMARY]
GO

CREATE TABLE [dbo].[MerchantAssetDefault]
(
  [Id] [int] NOT NULL IDENTITY(1, 1),
  [Url] VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
  [ConfigurationId] [bigint] NOT NULL
) ON [PRIMARY] 
GO
ALTER TABLE [dbo].[MerchantAssetDefault] ADD CONSTRAINT [PK_MerchantAssetDefault] PRIMARY KEY CLUSTERED ([Id]) WITH (FILLFACTOR=80) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_MerchantAssetDefault_ConfigurationId] 
ON [dbo].[MerchantAssetDefault] ([ConfigurationId])
INCLUDE(Url) 
ON [PRIMARY]
GO

INSERT INTO Merchant WITH(TABLOCK)
(
    Name,
    URL,
    ConfigurationId
)
SELECT TOP 10000 NEWID() AS Name, 
                'http:\\www.' + CONVERT(VARCHAR(200), NEWID()) AS URL, 
                 ABS(CHECKSUM(NEWID())/ 1000)  AS ConfigurationId
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d 
GO

INSERT INTO [MerchantAssetDefault] WITH(TABLOCK)
(
    [Url],
    [ConfigurationId]
)
SELECT TOP 10000 'http:\\www.' + CONVERT(VARCHAR(200), NEWID()) AS URL, 
                 ABS(CHECKSUM(NEWID())/ 1000) AS ConfigurationId
  FROM sysobjects a, sysobjects b, sysobjects c, sysobjects d 
GO




SET STATISTICS IO ON
GO
DECLARE @p__linq__0 BIGINT = 4923
SELECT [Project2].[Id] AS [Id],
       [Project2].[Url] AS [Url]
FROM
(
    SELECT [Extent1].[Id] AS [Id],
           [Extent1].[Url] AS [Url],
           (
               SELECT TOP (1)
                      [Extent2].[Id] AS [Id]
               FROM [dbo].[Merchant] AS [Extent2]
               WHERE [Extent1].[ConfigurationId] = [Extent2].[ConfigurationId]
           ) AS [C1]
    FROM [dbo].[MerchantAssetDefault] AS [Extent1]
) AS [Project2]
WHERE ([Project2].[C1] = @p__linq__0)
OPTION (RECOMPILE)
GO

SELECT TOP (1)
         [Extent2].[Id] AS [Id],  [Extent2].[ConfigurationId]
  FROM [dbo].[Merchant] AS [Extent2]
 WHERE [Id] = 4923
GO
SELECT * 
  FROM [dbo].[MerchantAssetDefault] AS [Extent1]
 WHERE Extent1.ConfigurationId = 1051890
GO

SELECT TOP (1)
       [Extent2].[Id] AS [Id]
FROM [dbo].[Merchant] AS [Extent2]
WHERE 1051890 = [Extent2].[ConfigurationId]
GO


DECLARE @p__linq__0 BIGINT = 4923
SELECT [Project2].[Id] AS [Id],
       [Project2].[Url] AS [Url]
FROM
(
    SELECT [Extent1].[Id] AS [Id],
           [Extent1].[Url] AS [Url],
           (
               SELECT --TOP (1)
                      [Extent2].[Id] AS [Id]
               FROM [dbo].[Merchant] AS [Extent2]
               WHERE [Extent1].[ConfigurationId] = [Extent2].[ConfigurationId]
           ) AS [C1]
    FROM [dbo].[MerchantAssetDefault] AS [Extent1]
) AS [Project2]
WHERE ([Project2].[C1] = @p__linq__0)
OPTION (RECOMPILE)
GO

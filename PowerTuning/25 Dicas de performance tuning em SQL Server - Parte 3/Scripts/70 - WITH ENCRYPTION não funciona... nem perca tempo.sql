USE Northwind
GO

IF OBJECT_ID('st_SuperProtegida') IS NOT NULL
  DROP PROC st_SuperProtegida
GO

CREATE PROC st_SuperProtegida
WITH ENCRYPTION
AS
BEGIN
  SELECT 'Deveja isso...'
END
GO

EXEC st_SuperProtegida
GO

-- Não consigo ver o texto...
sp_helptext st_SuperProtegida
GO

-- E como faz então? 
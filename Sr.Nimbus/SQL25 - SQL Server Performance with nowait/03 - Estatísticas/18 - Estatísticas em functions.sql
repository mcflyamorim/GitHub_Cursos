/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-------------------------------
-- Estatísticas em functions --
-------------------------------

USE Northwind
GO

IF OBJECT_ID('fn_Ultimo_Dia_Mes', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_Ultimo_Dia_Mes
GO
CREATE FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO

-- Estimou errado por causa da function...
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO


-- ALTER TABLE OrdersBig DROP COLUMN ComputedColumn1
ALTER TABLE OrdersBig ADD ComputedColumn1 AS dbo.fn_Ultimo_Dia_Mes(OrderDate)
GO

-- Não gera auto create statistics... continua estimando errado
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO

-- Recriando a function como SCHEMABINDING
IF OBJECT_ID('fn_Ultimo_Dia_Mes', 'FN') IS NOT NULL
  DROP FUNCTION dbo.fn_Ultimo_Dia_Mes
GO
CREATE FUNCTION dbo.fn_Ultimo_Dia_Mes(@Data DateTime)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
  SET @Data = DATEADD( mm , 1 , @Data );
  RETURN DATEADD(d , -DATEPART(d,@Data) , @Data  );
END
GO

-- Gera auto create statistics e estima corretamente
SELECT dbo.fn_Ultimo_Dia_Mes(OrderDate) AS UltimoDiaMes,
       COUNT(*) AS Qtde_Vendas_Ultima_Dia_Mes
  FROM OrdersBig
 GROUP BY dbo.fn_Ultimo_Dia_Mes(OrderDate)
 ORDER BY UltimoDiaMes
GO
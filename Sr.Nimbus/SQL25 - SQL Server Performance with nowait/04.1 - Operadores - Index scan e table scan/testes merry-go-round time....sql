/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/

-- Sem merry go round
SELECT ProductID,
       sys.fn_PhysLocFormatter (%%physloc%%) AS Physical_RID
  FROM TMP_ProductsBig WITH(NOLOCK)
GO
WAITFOR DELAY '00:00:01:000'
GO
SELECT ProductID,
       sys.fn_PhysLocFormatter (%%physloc%%) AS Physical_RID
  FROM TMP_ProductsBig WITH(NOLOCK)
GO

-- Com merry go round
SELECT ProductID,
       sys.fn_PhysLocFormatter (%%physloc%%) AS Physical_RID
  FROM TMP_ProductsBig WITH(NOLOCK)
GO
WAITFOR DELAY '00:00:00:500'
GO
SELECT ProductID,
       sys.fn_PhysLocFormatter (%%physloc%%) AS Physical_RID
  FROM TMP_ProductsBig WITH(NOLOCK)
GO
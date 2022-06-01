
/*
  Mascarando erros de corrupção no banco de dados
*/
-- Habilita o PAGE_VERIFY CHECKSUM
ALTER DATABASE NorthWind SET PAGE_VERIFY CHECKSUM WITH NO_WAIT
GO

IF OBJECT_ID('Tab_ErroNoCheckSum') IS NOT NULL
  DROP TABLE Tab_ErroNoCheckSum
GO
CREATE TABLE Tab_ErroNoCheckSum (Col1 VarChar(250))
GO
INSERT INTO Tab_ErroNoCheckSum(Col1) VALUES('XXX Fabiano XXX')
GO
SELECT * FROM Tab_ErroNoCheckSum
GO
ALTER INDEX ALL ON Tab_ErroNoCheckSum REBUILD
GO
CHECKPOINT
GO

/*
  Setar o banco para OFFLINE e corromper o checksum da tabela Tab_ErroNoCheckSum
  
  Localizar o caminho do arquivo mdf
  SELECT * FROM sysfiles
  C:\DBs\northwnd.mdf
*/


use master
GO
ALTER DATABASE NorthWind SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- Voltar o banco
ALTER DATABASE NorthWind SET ONLINE WITH NO_WAIT
GO

use NorthWind
GO
SELECT * FROM Tab_ErroNoCheckSum WITH(NOLOCK)
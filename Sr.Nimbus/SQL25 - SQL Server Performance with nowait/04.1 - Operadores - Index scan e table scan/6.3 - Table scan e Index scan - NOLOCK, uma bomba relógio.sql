/*
  SQL25 - SQL Server Performance with nowait
  http://www.srnimbus.com.br
*/



USE NorthWind
GO

/*
  Problema 1 - Leitura Suja
*/
-- Conexão 1
BEGIN TRAN

UPDATE Customers SET ContactName = 'Chico'
 WHERE CustomerID = 99

WAITFOR DELAY '00:00:15'
ROLLBACK TRAN
GO

-- Conexão 2
SELECT * 
  FROM Customers WITH(NOLOCK)
 WHERE CustomerID = 99


/*
  Problema 2 - Error 601
*/

-- Preparando o ambiente
IF OBJECT_ID('Tab1') IS NOT NULL
  DROP TABLE Tab1
IF OBJECT_ID('Tab2') IS NOT NULL
  DROP TABLE Tab2
GO
CREATE TABLE Tab1 (ID INT, Col1 Char(500) DEFAULT NEWID())
GO
INSERT Tab1(ID) VALUES(0), (1)
GO
CREATE TABLE Tab2 (ID INT PRIMARY KEY, Col1 Char(500) DEFAULT NEWID())
GO
INSERT Tab2(ID) VALUES(0), (1)
GO

-- Conexão 1
BEGIN TRAN
-- Obter lock na linha com o ID 0
UPDATE Tab2 SET ID = ID 
WHERE ID = 0

-- Conexão 2
SELECT * FROM Tab1 WITH (NOLOCK)
WHERE EXISTS (SELECT * 
                FROM Tab2 
               WHERE Tab1.ID = Tab2.ID)

-- Conexão 1
-- A conexão 2 já leu o ID 0 pois a tabela Tab1 esta com o WITH Nolock, 
-- e esta esperando para fazer o join com a Tab2 que esta bloqueada
-- pelo Update
DELETE Tab1 WHERE ID = 0
COMMIT TRAN
GO

/*
  Problema 3 - Mascarando erros de corrupção no banco de dados
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
  C:\Program Files\Microsoft SQL Server\MSSQL11.SQL2012\MSSQL\DATA\northwind.mdf
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
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- Configurar mirroring com discos desalinhados...
 -- ...\Scripts\Sector size – Overhead no IO pra sector size desalinhados e TF1800\Configurar mirroring com discos desalinhados.sql


-- Verificando o sector size do disco E:
EXEC xp_cmdShell 'fsutil fsinfo ntfsinfo E:'
GO
/*
Bytes Per Sector  :                512
Bytes Per Physical Sector :        512
*/
-- Verificando o sector size do disco C:
EXEC xp_cmdShell 'fsutil fsinfo ntfsinfo C:'
GO
/*
Bytes Per Sector  :                512
Bytes Per Physical Sector :        4096
*/


-- Escrever no SQL2017 que tem o Sector Size de 512 bytes
-- gera 2 I/Os no SQL2019 que tem sector size de 4096 bytes...
:CONNECT dellfabiano\SQL2017
GO

USE Test1
GO
BEGIN TRAN
DECLARE @i INT = 1
WHILE @i <= 100
BEGIN
  INSERT Tab1 (Col1) DEFAULT VALUES
  SET @i += 1;
END
COMMIT
GO 2
/*
7:56:15.2017544 PM	sqlservr.exe	11340	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 124,416, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0071682	13688
7:56:15.2092860 PM	sqlservr.exe	20048	ReadFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 122,880, Length: 16,384, I/O Flags: Non-cached, Priority: Normal	0.0014694	20908
7:56:15.2108255 PM	sqlservr.exe	20048	WriteFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 122,880, Length: 16,384, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0001097	20908
7:56:15.2911750 PM	sqlservr.exe	11340	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 135,680, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049310	13688
7:56:15.2965119 PM	sqlservr.exe	20048	ReadFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 135,168, Length: 12,288, I/O Flags: Non-cached, Priority: Normal	0.0001308	20908
7:56:15.2966772 PM	sqlservr.exe	20048	WriteFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 135,168, Length: 12,288, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0000603	20908
*/

-- Offset que precisa ser escrito é o 124,416
-- Mas esse número é multiplo do sector size ?

-- De 512 sim...
SELECT 124416 % 512.
GO

-- De 4KB não...
SELECT 124416 % 4096.
-- 1536
GO

-- Então o SQL precisa alinhar o I/O, pro Offset ser multiplo do sector size...
SELECT 124416 + 1536.
-- 125952 é o próximo offset multiplo de 4KB
GO

-- SQL tem que ficar ajustando o offset...


-- Depois de habilitar o TF1800 no SQL2017(instância com o sector size de 512) o SQL passa a usar um sector size de 4KB pra 
-- alinhar com a replica... 
-- No error log vamos ver isso:
-- The tail of the log for database Test1 is being rewritten to match the new sector size of 4096 bytes.  3584 bytes at offset 229888 in file E:\Test1_log.ldf will be written.


-- E os I/Os agora estão alinhados... Sucesso...
--8:15:08.8537624 PM	sqlservr.exe	19136	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 290,816, Length: 12,288, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0042421	13808
--8:15:08.8584780 PM	sqlservr.exe	20048	WriteFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 290,816, Length: 12,288, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0000940	20908

-- Massss ao custo de precisar de mais espaço pro Log, já que um simples insert que 
-- antes cabia em um sector size de 512 bytes, agora vai ser gravado num sector size de 4KB
:CONNECT dellfabiano\SQL2017
GO
USE Test1
GO
BEGIN TRAN
INSERT Tab1 (Col1) DEFAULT VALUES
COMMIT
GO
--8:17:49.7376292 PM	sqlservr.exe	19136	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 307,200, Length: 4,096, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017528	13808
--8:17:49.7397284 PM	sqlservr.exe	20048	WriteFile	C:\DBs\Test1_1.ldf	SUCCESS	Offset: 307,200, Length: 4,096, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0001241	20908
--GO


-- Clean up
-- Remover o T1800 do Startup do SQL2017
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- Configurar mirroring com discos alinhados
-- ...\Scripts\Sector size – Overhead no IO pra sector size desalinhados e TF1800\Configurar mirroring com discos alinhados.sql



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
7:53:15.3142992 PM	sqlservr.exe	11340	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 442,368, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0083779	13688
7:53:15.3231487 PM	sqlservr.exe	20048	WriteFile	E:\Test1_1_2.ldf	SUCCESS	Offset: 442,368, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0098132	15136
7:53:15.4684036 PM	sqlservr.exe	11340	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 453,632, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0107066	13688
7:53:15.4796052 PM	sqlservr.exe	20048	WriteFile	E:\Test1_1_2.ldf	SUCCESS	Offset: 453,632, Length: 11,264, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0091747	15136
*/


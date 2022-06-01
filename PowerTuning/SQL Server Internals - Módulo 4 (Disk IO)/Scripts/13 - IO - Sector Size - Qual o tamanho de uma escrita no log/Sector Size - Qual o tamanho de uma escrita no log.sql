----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------


USE [master]
GO
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
end
GO

-- Criar banco de 10MB no pendrive (E:\) com IFI
-- 7 segundos pra rodar
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'E:\Test1.mdf' , SIZE = 50MB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'E:\Test1_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

USE Test1
GO

-- Criando tabela com linha BEM pequena
DROP TABLE IF EXISTS Tab1
CREATE TABLE Tab1 (Col1 BIT DEFAULT 0)
GO

-- Verificando o sector size do disco E:
EXEC xp_cmdShell 'fsutil fsinfo ntfsinfo E:'
GO
/*
NTFS Volume Serial Number :        0xc42ce3112ce2fcf4
NTFS Version      :                3.1
LFS Version       :                1.1
Total Sectors     :                7,571,583  (3.6 GB)
Total Clusters    :                  946,447  (3.6 GB)
Free Clusters     :                  929,608  (3.5 GB)
Total Reserved Clusters :              1,024  (4.0 MB)
Reserved For Storage Reserve :             0  (0.0 KB)
Bytes Per Sector  :                512
Bytes Per Physical Sector :        512
Bytes Per Cluster :                4096
Bytes Per FileRecord Segment    :  4096
Clusters Per FileRecord Segment :  1
Mft Valid Data Length :            1.00 MB
Mft Start Lcn  :                   0x0000000000040000
Mft2 Start Lcn :                   0x0000000000000002
Mft Zone Start :                   0x0000000000040000
Mft Zone End   :                   0x000000000004c820
MFT Zone Size  :                   200.13 MB
Max Device Trim Extent Count :     0
Max Device Trim Byte Count :       0
Max Volume Trim Extent Count :     62
Max Volume Trim Byte Count :       0x40000000
Resource Manager Identifier :      29E5DF1C-CA84-11EA-812B-D43B044386CB
*/

-- Quando eu fizer o commit SQL vai enviar o I/O e esperar a 
-- confirmação do hardening

CHECKPOINT
GO
BEGIN TRAN

INSERT Tab1 (Col1) DEFAULT VALUES

-- Qual o tamanho do log gerado?
SELECT database_transaction_log_bytes_used
  FROM sys.dm_tran_database_transactions
 WHERE database_id = DB_ID('Test1');

COMMIT
GO

-- Ver o que foi gerado no Log
SELECT * FROM ::fn_dblog(null, null)
--LOP_BEGIN_XACT
--LOP_INSERT_ROWS
--LOP_COMMIT_XACT
GO

-- Mas qual foi o tamanho do I/O de escrita no Log? 
-- Já que a escrita precisa estar alinhada com o Sector Size, foi de 512 bytes?


-- Vamos pegar o tamanho via ProcessMonitor
-- Abrir ...\Outros\ProcessMonitor\Procmon64.exe e aplicar filtro pra pegar
-- apenas I/O do processo sqlservr.exe

BEGIN TRAN
INSERT Tab1 (Col1) DEFAULT VALUES
COMMIT
GO 10
/*
7:01:06.7654666 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 194,048, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017417	12432
7:01:06.7710572 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 194,560, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032865	4192
7:01:06.7768781 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 195,072, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017384	4192
7:01:06.7805950 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 195,584, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032592	12432
7:01:06.7852262 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 196,096, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018032	4192
7:01:06.7897096 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 196,608, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033075	12432
7:01:06.7941224 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 197,120, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017868	4192
7:01:06.7969788 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 197,632, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032809	12432
7:01:06.8013653 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 198,144, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018301	4192
7:01:06.8044808 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 198,656, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033796	12432
*/

-- E e eu fizer o commit somente depois que eu inserir varias linhas no log,
-- vou ver um I/O maior?
BEGIN TRAN
DECLARE @i INT = 1
WHILE @i <= 2000
BEGIN
  INSERT Tab1 (Col1) DEFAULT VALUES
  SET @i += 1;
END
COMMIT
GO
/*
7:08:56.1711530 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,147,840, Length: 61,440, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0158175	4192
7:08:56.3217116 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,209,280, Length: 61,440, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0165828	12432
7:08:56.3272700 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,270,720, Length: 61,440, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0268911	4192
7:08:56.3294548 PM	sqlservr.exe	4276	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,332,160, Length: 31,744, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0357249	12432
*/

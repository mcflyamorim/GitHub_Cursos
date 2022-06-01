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

-- Mas e seu eu rodar várias threads ao mesmo tempo, e todas elas fizeram pequenos I/Os? 
-- O SQL pode agrupar os commits pra gerar I/Os maiores... 
-- Group Commit - Enterprise Only feature... 
-- Abrir ...\\Scripts\Sector Size - Qual o tamanho de uma escrita no log - GroupCommit\Perfmon.msc 
-- pra ver o contador MSSQL$SQL2019:Databases -> Group Commit Time/sec

-- Rodar insert no SQLQueryStress com 200 threads e 5 iterations

-- I/Os reportados no Process Monitor são maiores...
/*
2:48:17.7832525 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,949,696, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017087	29556
2:48:17.7949041 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,950,208, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033483	29556
2:48:17.7997260 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,952,768, Length: 3,072, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017974	11376
2:48:17.8046301 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,955,840, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0039830	29556
2:48:17.8097367 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,957,888, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033093	29556
2:48:17.8142809 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,960,448, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017614	29556
2:48:17.8171086 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,963,008, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034472	29556
2:48:17.8180448 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,965,568, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0065543	11376
2:48:17.8323856 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,967,616, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033435	29556
2:48:17.8718109 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,969,152, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017499	11376
2:48:17.8903753 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,969,664, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033980	29556
2:48:17.9217850 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,971,200, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017749	29556
2:48:17.9327837 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,971,712, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034299	29556
2:48:17.9615977 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,972,224, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018343	29556
2:48:17.9695599 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,973,760, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0040061	11376
2:48:17.9851315 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,974,272, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032928	29556
2:48:17.9961573 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,975,296, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017439	11376
2:48:18.0106160 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,975,808, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033606	29556
2:48:18.0244674 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,977,344, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017452	29556
2:48:18.0441878 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,977,856, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033839	11376
2:48:18.0548483 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,978,880, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017781	29556
2:48:18.0880444 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,979,392, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0070908	29556
2:48:18.1005294 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,980,416, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0054681	29556
2:48:18.1114600 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,982,976, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017278	29556
2:48:18.1265286 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,984,000, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032434	11376
2:48:18.1373951 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,985,536, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017715	29556
2:48:18.1490927 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,986,560, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033032	29556
2:48:18.1690570 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,989,120, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0054311	29556
2:48:18.1700008 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,991,168, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0076718	29556
2:48:18.1811053 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,993,728, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017645	29556
2:48:18.1836277 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,994,240, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032734	11376
2:48:18.2091501 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,994,752, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017706	29556
2:48:18.2097421 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,995,776, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0044919	11376
2:48:18.2202821 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,997,824, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018452	11376
2:48:18.2302080 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,998,336, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0025868	29556
2:48:18.2485308 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 1,998,848, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033259	29556
2:48:18.2534871 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,000,384, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017183	11376
2:48:18.2728029 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,000,896, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033017	29556
2:48:18.3012507 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,001,408, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017262	11376
2:48:18.3050507 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,001,920, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032841	11376
2:48:18.3207382 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,002,432, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017392	29556
2:48:18.3354187 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,002,944, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033397	29556
2:48:18.3356708 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,003,968, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048450	29556
2:48:18.3767562 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,006,016, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0070443	11376
2:48:18.3817422 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,007,552, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0037210	29556
2:48:18.3966097 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,009,600, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033142	11376
2:48:18.4069370 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,011,136, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017906	29556
2:48:18.4158381 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,013,184, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033942	11376
2:48:18.4279345 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,013,696, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0040297	29556
2:48:18.4361895 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,015,744, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032326	11376
2:48:18.4398710 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,016,256, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017144	11376
2:48:18.4518722 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,016,768, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0080038	29556
2:48:18.4719931 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,017,792, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0031548	29556
2:48:18.4959819 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,018,304, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017513	11376
2:48:18.5041492 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,018,816, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032628	29556
2:48:18.5205197 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,019,328, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017650	11376
2:48:18.5312182 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,020,864, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033686	11376
2:48:18.5432439 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,021,376, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018162	29556
2:48:18.5535927 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,022,400, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034310	11376
2:48:18.5663215 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,022,912, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0054501	29556
2:48:18.5766726 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,024,960, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033299	11376
2:48:18.5963272 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,025,472, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017560	11376
2:48:18.6011270 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,025,984, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033920	29556
2:48:18.6210719 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,026,496, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017374	11376
2:48:18.6356615 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,027,008, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033789	11376
2:48:18.6830642 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,028,032, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017879	29556
2:48:18.6936771 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,029,056, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034070	11376
2:48:18.6954852 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,030,080, Length: 3,072, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0055991	29556
2:48:18.7066880 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,033,152, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033315	29556
2:48:18.7300012 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,033,664, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017650	11376
2:48:18.7340379 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,034,176, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033578	29556
2:48:18.7424205 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,034,688, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017660	11376
2:48:18.7537013 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,037,248, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033835	29556
2:48:18.7749387 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,037,760, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018231	29556
2:48:18.7856510 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,038,784, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034694	11376
2:48:18.7906348 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,039,296, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0040337	11376
2:48:18.8107114 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,039,808, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016608	29556
2:48:18.8153536 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,041,344, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033193	11376
2:48:18.8280905 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,041,856, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017140	11376
2:48:18.8367087 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,042,368, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033087	11376
2:48:18.8502103 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,042,880, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017447	29556
2:48:18.8582582 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,044,416, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0080533	29556
2:48:18.8712280 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,044,928, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032677	11376
2:48:18.8826640 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,046,464, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018352	11376
2:48:18.8955830 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,046,976, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033611	11376
2:48:18.9228690 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,047,488, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018917	29556
2:48:18.9371149 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,048,000, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017150	11376
2:48:18.9413858 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,049,024, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032547	29556
2:48:18.9573583 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,049,536, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017220	29556
2:48:18.9610873 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,051,584, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032920	29556
2:48:18.9773959 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,052,096, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017663	29556
2:48:18.9926621 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,052,608, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033518	29556
2:48:19.0028024 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,053,632, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017954	29556
2:48:19.0152775 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,054,656, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033455	11376
2:48:19.0390062 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,055,168, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018472	11376
2:48:19.0512873 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,055,680, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0063362	29556
2:48:19.0581155 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,058,240, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017113	29556
2:48:19.0814732 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,058,752, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032601	11376
2:48:19.0977148 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,059,264, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017613	29556
2:48:19.1124817 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,060,288, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032983	11376
2:48:19.1242432 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,061,824, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018178	11376
2:48:19.1418011 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,063,360, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033850	29556
2:48:19.1564620 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,063,872, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033737	29556
2:48:19.1718206 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,065,408, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032391	11376
2:48:19.1972072 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,066,944, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017322	29556
2:48:19.2075183 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,067,456, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032946	29556
2:48:19.2254819 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,068,992, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017580	11376
2:48:19.2353609 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,069,504, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0063013	29556
2:48:19.2444614 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,076,160, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033318	29556
2:48:19.2553099 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,082,816, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032553	11376
2:48:19.2824376 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,084,864, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017685	29556
2:48:19.3013733 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,085,888, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0080615	29556
2:48:19.3123335 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,086,912, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033150	11376
2:48:19.3327800 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,088,448, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0040135	11376
2:48:19.3450585 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,088,960, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016740	11376
2:48:19.3607571 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,089,472, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032823	11376
2:48:19.3737526 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,091,008, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017434	29556
2:48:19.3775112 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,093,568, Length: 7,168, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0056554	11376
2:48:19.3876545 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,100,736, Length: 5,632, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0053919	29556
2:48:19.3940615 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,106,368, Length: 7,680, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0055232	29556
2:48:19.4052686 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,114,048, Length: 5,632, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017496	11376
2:48:19.4211605 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,119,680, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0040110	11376
2:48:19.4304653 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,121,728, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033059	29556
2:48:19.4415267 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,128,384, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018426	29556
2:48:19.4525899 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,129,408, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0056056	11376
2:48:19.4640918 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,131,968, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017634	29556
2:48:19.4783616 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,134,016, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033890	11376
2:48:19.4833356 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,135,552, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018082	11376
2:48:19.4875777 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,136,064, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033945	29556
2:48:19.4979214 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,136,576, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018449	29556
2:48:19.5080153 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,137,600, Length: 4,608, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0069126	29556
2:48:19.5197519 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,142,208, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017944	11376
2:48:19.5455228 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,143,232, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033789	11376
2:48:19.5495106 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,143,744, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018304	29556
2:48:19.5660309 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,144,256, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033858	11376
2:48:19.5735499 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,144,768, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018353	29556
2:48:19.5821026 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,145,280, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033941	11376
2:48:19.5976264 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,145,792, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0026275	29556
2:48:19.6105975 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,146,304, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016905	29556
2:48:19.6390328 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,146,816, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032590	29556
2:48:19.6481841 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,148,352, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017334	11376
2:48:19.6646974 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,148,864, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032761	11376
2:48:19.6813328 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,149,376, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017452	11376
2:48:19.6851706 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,149,888, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0080406	29556
2:48:19.6967216 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,150,400, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032344	29556
2:48:19.7404169 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,150,912, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017682	29556
2:48:19.7708664 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,151,424, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033007	11376
2:48:19.7902373 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,151,936, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017994	29556
2:48:19.8021946 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,152,448, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034263	11376
2:48:19.8108539 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,152,960, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018291	29556
2:48:19.8542885 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,153,472, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034618	11376
2:48:19.8770232 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,153,984, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0054498	29556
2:48:19.8883340 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,155,008, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032513	11376
2:48:19.9204230 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,155,520, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017210	11376
2:48:19.9248172 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,156,032, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032407	29556
2:48:19.9293130 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,156,544, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017307	11376
2:48:19.9428853 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,157,056, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033852	11376
2:48:19.9574390 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,157,568, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017436	11376
2:48:19.9693431 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,158,592, Length: 3,072, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034174	11376
2:48:19.9813324 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,161,664, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0146052	29556
2:48:19.9931617 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,164,224, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0044457	29556
2:48:20.0059232 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,165,248, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032374	29556
2:48:20.0099425 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,166,784, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017570	29556
2:48:20.0264800 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,167,296, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033318	29556
2:48:20.0382220 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,168,832, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018590	29556
2:48:20.0426275 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,169,856, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033859	29556
2:48:20.0631376 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,170,368, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049007	11376
2:48:20.0712606 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,171,392, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017333	11376
2:48:20.0854956 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,171,904, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032681	29556
2:48:20.0965563 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,172,928, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017317	29556
2:48:20.1115424 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,174,464, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032896	29556
2:48:20.1260534 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,174,976, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018157	11376
2:48:20.1413198 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,176,512, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033205	29556
2:48:20.2070849 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,177,536, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018231	29556
2:48:20.2111683 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,178,048, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033738	11376
2:48:20.2265779 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,178,560, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049029	11376
2:48:20.2437519 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,179,584, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016956	11376
2:48:20.2546328 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,180,096, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032377	29556
2:48:20.2671193 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,181,632, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017281	29556
2:48:20.2757506 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,182,144, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032686	11376
2:48:20.2798136 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,182,656, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017631	11376
2:48:20.3059953 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,183,168, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033071	29556
2:48:20.3186453 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,184,704, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018721	29556
2:48:20.3310649 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,185,728, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033889	11376
2:48:20.3460748 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,187,264, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016892	11376
2:48:20.3618364 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,188,800, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032665	11376
2:48:20.3672950 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,189,312, Length: 7,680, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048589	11376
2:48:20.3711955 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,196,992, Length: 7,680, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0057740	29556
2:48:20.3760262 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,204,672, Length: 7,680, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0057621	11376
2:48:20.3873792 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,212,352, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017187	29556
2:48:20.4417332 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,214,400, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032571	29556
2:48:20.4592267 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,214,912, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017375	11376
2:48:20.4696650 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,216,960, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033267	11376
2:48:20.4817604 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,217,984, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018528	11376
2:48:20.4937025 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,218,496, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034014	29556
2:48:20.5080349 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,220,032, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016652	11376
2:48:20.5167898 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,220,544, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032212	11376
2:48:20.5257946 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,221,056, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017189	11376
2:48:20.5431742 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,221,568, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0031961	29556
2:48:20.5537277 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,222,592, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017411	11376
2:48:20.5647216 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,223,616, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032706	29556
2:48:20.5792837 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,225,152, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017970	11376
2:48:20.5910941 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,226,176, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033589	11376
2:48:20.5954542 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,227,712, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0019105	29556
2:48:20.6139522 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,228,224, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032469	11376
2:48:20.6635194 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,229,248, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017210	11376
2:48:20.7142848 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,229,760, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032288	11376
2:48:20.7180273 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,230,272, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017136	11376
2:48:20.7307830 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,230,784, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032493	11376
2:48:20.7414528 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,231,808, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017507	29556
2:48:20.7519329 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,232,832, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032694	11376
2:48:20.7666799 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,233,856, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018120	11376
2:48:20.7799818 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,234,880, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033809	29556
2:48:20.7856908 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,236,416, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0016727	11376
2:48:20.8077054 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,236,928, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032284	11376
2:48:20.8115947 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,237,952, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017321	29556
2:48:20.8260905 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,238,464, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032356	11376
2:48:20.8368553 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,240,512, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017634	29556
2:48:20.8488655 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,241,024, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033025	11376
2:48:20.8617280 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,242,560, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018304	11376
2:48:20.8727828 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,244,096, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0034268	29556
2:48:20.8820363 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,244,608, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017009	29556
2:48:20.8901116 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,245,120, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032324	11376
2:48:20.9060205 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,245,632, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017206	11376
2:48:20.9225376 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,246,656, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032472	29556
2:48:20.9354716 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,248,192, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017646	11376
2:48:20.9441869 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,249,728, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033274	11376
2:48:20.9533992 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,250,240, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018012	11376
2:48:20.9665371 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,250,752, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033982	11376
2:48:20.9780498 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,252,800, Length: 2,048, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017032	11376
2:48:20.9811734 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,254,848, Length: 7,168, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048283	29556
2:48:20.9835632 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,262,016, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0057039	29556
2:48:20.9875997 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,268,672, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0065477	11376
2:48:20.9981127 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,275,328, Length: 4,096, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049143	29556
2:48:21.0356571 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,279,424, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017276	11376
2:48:21.0563877 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,279,936, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032281	11376
2:48:21.0646926 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,280,448, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017315	11376
2:48:21.0700751 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,280,960, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032261	29556
2:48:21.0840917 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,281,472, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018157	29556
2:48:21.1024394 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,281,984, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032934	29556
2:48:21.1083971 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,282,496, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018092	11376
2:48:21.1358090 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,283,008, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033702	11376
2:48:21.1460539 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,284,032, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018977	11376
2:48:21.1505293 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,285,568, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032011	29556
2:48:21.1551613 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,286,080, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017100	11376
2:48:21.1718298 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,286,592, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032245	11376
2:48:21.1850050 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,288,128, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017277	29556
2:48:21.1982231 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,288,640, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032680	11376
2:48:21.2021965 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,291,200, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018366	11376
2:48:21.2209927 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,291,712, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033299	11376
2:48:21.2323984 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,292,736, Length: 1,024, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0018826	11376
2:48:21.2428977 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,293,760, Length: 2,560, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032438	29556
2:48:21.2569894 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,296,320, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017316	11376
2:48:21.2658631 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,297,856, Length: 512, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0032922	11376
2:48:21.2838506 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,298,368, Length: 4,096, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048066	11376
2:48:21.2949116 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,302,464, Length: 3,584, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017580	29556
2:48:21.2977862 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,306,048, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048984	29556
2:48:21.3086649 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,312,704, Length: 4,096, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033238	29556
2:48:21.3169488 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,316,800, Length: 7,168, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048795	29556
2:48:21.3266203 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,323,968, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049420	11376
2:48:21.3307372 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,330,624, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0056086	29556
2:48:21.3393394 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,337,280, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0049107	11376
2:48:21.3507634 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,343,936, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017106	11376
2:48:21.3610237 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,345,472, Length: 3,584, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0033342	11376
2:48:21.3720028 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,349,056, Length: 6,656, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048874	29556
2:48:21.3828089 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,355,712, Length: 4,608, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0048543	11376
2:48:21.3939173 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,360,320, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017203	29556
2:48:21.4063828 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,361,856, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0031955	29556
2:48:21.4179222 PM	sqlservr.exe	26296	WriteFile	E:\Test1_log.ldf	SUCCESS	Offset: 2,363,392, Length: 1,536, I/O Flags: Non-cached, Write Through, Priority: Normal	0.0017821	29556
*/

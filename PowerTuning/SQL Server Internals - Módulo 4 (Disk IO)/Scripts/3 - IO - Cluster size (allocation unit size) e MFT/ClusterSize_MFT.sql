----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------



-- Quick tip... pra evitar o problema que mencionei no slide
---- de fragmentação e limitação de espaço no segment file record
---- formatar disco pra usar large file record segments...

-- Por padrão, Bytes Per FileRecord Segment    :  1024 
/*
C:\WINDOWS\system32>fsutil fsinfo ntfsinfo E:
NTFS Volume Serial Number :        0xc84e40b84e40a154
NTFS Version      :                3.1
LFS Version       :                1.1
Total Sectors     :                7,571,583  (3.6 GB)
Total Clusters    :                  946,447  (3.6 GB)
Free Clusters     :                  942,839  (3.6 GB)
Total Reserved Clusters :              1,024  (4.0 MB)
Reserved For Storage Reserve :             0  (0.0 KB)
Bytes Per Sector  :                512
Bytes Per Physical Sector :        512
Bytes Per Cluster :                4096
Bytes Per FileRecord Segment    :  1024
Clusters Per FileRecord Segment :  0
Mft Valid Data Length :            256.00 KB
Mft Start Lcn  :                   0x0000000000040000
Mft2 Start Lcn :                   0x0000000000000002
Mft Zone Start :                   0x0000000000040040
Mft Zone End   :                   0x000000000004c840
MFT Zone Size  :                   200.00 MB
Max Device Trim Extent Count :     0
Max Device Trim Byte Count :       0
Max Volume Trim Extent Count :     62
Max Volume Trim Byte Count :       0x40000000
Resource Manager Identifier :      7CC25378-C826-11EA-8127-D43B044386CB


C:\WINDOWS\system32>format e: /V:Pendrive /FS:NTFS /L /A:64k /Q
Insert new disk for drive E:
and press ENTER when ready...
The type of the file system is NTFS.
QuickFormatting 3.6 GB
Creating file system structures.
Format complete.
       3.6 GB total disk space.
       3.6 GB are available.

-- Depois de formatar com /L, Bytes Per FileRecord Segment    :  4096 
C:\WINDOWS\system32>fsutil fsinfo ntfsinfo E:
NTFS Volume Serial Number :        0x20f2346df23448f4
NTFS Version      :                3.1
LFS Version       :                1.1
Total Sectors     :                7,571,583  (3.6 GB)
Total Clusters    :                  946,447  (3.6 GB)
Free Clusters     :                  942,664  (3.6 GB)
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
Resource Manager Identifier :      29E5DBE0-CA84-11EA-812B-D43B044386CB
*/



-- 1 - Formatar disco E:\ (pendrive)
-- Usar o default de 4KB como cluster size
-- NFTS

-- 2 - Criar 1 arquivo txt com 5 bytes no disco E:\
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (5 -1))" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO

-- Qual o tamanho do arquivo? 5 bytes ou 4096 que é o mínimo de um cluster ?
-- Confirmando o tamanho do arquivo em bytes
EXEC xp_cmdShell 'Dir E:\' -- EXEC xp_cmdShell 'more "E:\Test.txt"'
GO
/*
 Volume in drive E is Pendrive
 Volume Serial Number is FE19-3DD3
 Directory of E:\
07/20/2020  03:40 PM                 5 Test.txt
               1 File(s)              5 bytes
               0 Dir(s)   3,857,747,968 bytes free
*/

-- No dir ele mostra 5 bytes, mas e o "size on disk"? Vai mostrar 4KB?
-- Clicar com botão do lado direito do arquivo e veja o "Size on Disk"... 
-- Size on disk = 0 bytes... 

-- Ué, 0 bytes, como pode? 

-- Se o arquivo for pequeno ele (aprox. até 1KB) ele vai ficar armazenado direto na MFT...


-- Apagar arquivo com Del
EXEC xp_cmdShell 'Del E:\Test.txt' -- EXEC xp_cmdShell 'more "E:\Test.txt"'
GO

-- Confirmando se arquivo foi removido...
EXEC xp_cmdShell 'Dir E:\' -- EXEC xp_cmdShell 'more "E:\Test.txt"'
GO
/*
 Volume in drive E is Pendrive
 Volume Serial Number is 8C15-81A3
 Directory of E:\
File Not Found
*/

-- Informação do arquivo continua na MFT
-- Foi marcado como "apagado", mas os dados continuam no disco...
-- Vamos ver com a Get-ForensicFileRecord...
EXEC xp_cmdShell 'powershell -command "& {&Get-ForensicFileRecord -VolumeName E: | Select FullName, Name, RealSize, AllocatedSize, SequenceNumber, RecordNumber, Deleted | Where {($_.Name -like ''Test.txt'')}}";'
GO
/*
FullName       : E:\Test.txt
Name           : Test.txt
RealSize       : 304
AllocatedSize  : 1024
SequenceNumber : 3
RecordNumber   : 39
Deleted        : True
*/


-- Criar arquivo novamente...
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (5 -1))" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO
-- Agora sim apagando "de verdade" com o SDelete64 da SysInternals... 
EXEC xp_cmdShell 'SDelete64 E:\Test.txt' 
GO
/*
SDelete v2.02 - Secure file delete
Copyright (C) 1999-2018 Mark Russinovich
Sysinternals - www.sysinternals.com
SDelete is set for 1 pass.
E:\Test.txt...deleted.
Files deleted: 1
*/

-- E agora saiu da MFT?
-- Olha que safado... o SDelete reescreve algum outro lixo (arquivo zzz) por cima... 
-- esse é o "apagar" dele... make sense...
EXEC xp_cmdShell 'powershell -command "& {&Get-ForensicFileRecord -VolumeName E: | Select FullName, Name, RealSize, AllocatedSize, SequenceNumber, RecordNumber, Deleted | Where {($_.Name -like ''*ZZZ*'')}}";'
GO

-- Ainda temos 720 bytes disponíveis no File Record... 
-- Ou seja, da pra criar um arquivo ainda maior e caber la dentro...
-- RealSize       =  304
-- AllocatedSize  = 1024
-- SELECT 1024 - 304 -- = 720


-- Criar arquivo com 700 bytes... 
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (700 -1))" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO

-- Continua no File Record... 
-- Ver "Size on Disk"....


-- Vamos formatar o disco pra usar um "Large File Segment"

-- Rodar no cmd prompt... 
-- format e: /V:Pendrive /FS:NTFS /L /Q

-- Criar arquivo com 2048 bytes... 
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (2048 -1))" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO

-- Como ficou na MFT ? 
-- Mesmo com os 2048 bytes, o arquivo cabe no File Record... agora ele tem 4KB de tamanho...
-- Continuo vendo 0 bytes no "size on disk"
EXEC xp_cmdShell 'powershell -command "& {&Get-ForensicFileRecord -VolumeName E: | Select FullName, Name, RealSize, AllocatedSize, SequenceNumber, RecordNumber, Deleted | Where {($_.Name -like ''*Test*'')}}";'
GO


-- Scripts uteis....
/*
Get-ForensicFileRecordIndex -Path E:\Test.txt
Get-ForensicFileRecord -VolumeName E: -Index 38694 | Select FullName, Name, RealSize, AllocatedSize, SequenceNumber, RecordNumber, Deleted

Get-ForensicFileRecord -Path E:\Test.txt | Select *
Get-ForensicFileRecord -VolumeName E: | Select * | Where {($_.Name -like 'Test.txt')}
*/
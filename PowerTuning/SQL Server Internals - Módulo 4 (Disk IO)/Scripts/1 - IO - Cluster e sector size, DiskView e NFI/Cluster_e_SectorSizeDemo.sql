----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
/*
  Treinamento SQL Server Internals Parte 4 - Disk I/O
  Fabiano Neves Amorim - fabianonevesamorim@hotmail.com
  http://blogfabiano.com
*/
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

-- 1 - Formatar disco E:\ (pendrive)
-- Usar o default de 4KB como cluster size
-- NFTS


-- 2 - Criar um arquivo txt com 64KB no disco E:\
-- Exportanto o arquivo... Utilizando 65536 -1 pq o desgraçado do bcp envia um caracter como 
-- RowTerminator... e não sei como fazer pra ignorar ele... daí to falando que o 
-- row terminator é X (-r \X)... Daí fecha os 65536 bytes no arquivo...
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (65536 -1))" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO

-- Confirmando o tamanho do arquivo em bytes
EXEC xp_cmdShell 'Dir E:\' -- EXEC xp_cmdShell 'more "E:\Test.txt"'
GO
/*
 Volume in drive E is Disk1
 Volume Serial Number is 4E40-A154
NULL
 Directory of E:\
NULL
07/17/2020  03:40 PM            65,536 Test.txt
               1 File(s)         65,536 bytes
               0 Dir(s)   3,857,678,336 bytes free
NULL
*/

-- Considerando que o arquivo tem 65536 bytes, quantos disk clusters ele vai usar? 
-- SELECT 65536 / 4096. -- = 16

-- 3 - Windos + R -> DiskView.exe e ver em quantos "disk clusters" o arquivo utiliza e qual o range/posição onde ele está armazenado
-- DiskView mostrou o seguinte:
-- File Clusters = 0 - 15
-- Disk Clusters = 1419 - 1434

-- Só pra confundir, nesse caso, Sector 0 é um serctor, ou seja, 0 <> de nada...
-- Então a conta é, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 e 15 = 16 clusters...
-- Mesma coisa pro Disk Clusters... o arquivo ta usando os clusters 
-- 1419, 1420, 1421, 1422, 1423, 1424, 1425, 1426, 1427, 1428, 1429, 1430, 1431, 1432, 1433 e 1434 = 16 clusters


-- Se eu ponhar +1 byte no arquivo, ele vai ficar com tamanho de 65537 e vai precisar de mais um cluster...
-- Tamanho total do arquivo vai ser de 17 clusters, ou seja, SELECT 17 * 4096 = 69632 (68KB)

-- Criando arquivo com 64KB + 1 byte
EXEC xp_cmdShell 'bcp "SELECT REPLICATE(CONVERT(VARCHAR(MAX), ''X''), (65536 -1) + 1)" queryout "E:\Test.txt" -r \X -c -T -S "dellfabiano\sql2019"'
GO
-- Confirmando o tmanho do arquivo em bytes
EXEC xp_cmdShell 'Dir E:\' -- EXEC xp_cmdShell 'more "E:\Test.txt"'
GO
/*
 Volume in drive E is Disk1
 Volume Serial Number is 4E40-A154
NULL
 Directory of E:\
NULL
07/17/2020  03:45 PM            65,537 Test.txt
               1 File(s)         65,537 bytes
               0 Dir(s)   3,857,674,240 bytes free
NULL
*/

-- Ué, mas ele ta mostrando 65,537 bytes, não era pra mostrar os 69,632 ? 65,537 bytes + 4096 bytes de um novo Cluster...
-- É, clica com botão do lado direito do arquivo e veja o "Size on Disk"... 
-- Lá está, os 64KB + 4KB = 68KB (69,632 bytes)


-- E quantos sectors o arquivo ta usando? ... 
-- Lembre-se esse é um nível abaixo do cluster... 
----- o arquivo é armazenado em sectors e um cluster tem N sectors.
-- Vamos fazer umas contas aqui, 
-- Arquivo Test.txt tem 69632 bytes
-- Cluster size = 4KB (4096 bytes)
-- Sector size = 512 bytes
-- SELECT 69632 / 4096. = 17.0 Clusters
-- Cada Cluster tem quantos sectors mesmo? 
-- SELECT 4096 / 512. = 1 cluster tem 8.0 sectors
-- Se o arquivo tem 17 clusters, quantos sectors temos? 
-- SELECT 17 * 8. = 136

-- Repare que isso só funciona porque ta tudo alinhado...
-- Se quando eu adicionei + 1 byte no arquivo, o SQL de fato tivesse ficado com o tamanho 
-- que ele mostra no comando "dir", ou seja, 65,537 ia dar 
-- ruim porque esse número não é multiplo do sector size ... 
-- SELECT 65537 / 512. = 128.001953


-- Confirmando quantos sectors tem no arquivo utilizando o nfi.exe
EXEC xp_cmdShell 'nfi e:\Test.txt'
GO
/*
NTFS File Sector Information Utility. 
Copyright (C) Microsoft Corporation 1999. All rights reserved. 
 
\Test.txt 
    $STANDARD_INFORMATION (resident) 
    $FILE_NAME (resident) 
    $OBJECT_ID (resident) 
    $DATA (nonresident) 
        logical sectors 11480-11615 (0x2cd8-0x2d5f) 
NULL
*/
-- Novamente, a conta é, de 11480 até 11615
-- Fazendo um loop pra ficar mais fácil de contar... :-) ...
DECLARE @i INT = 0, @de INT = 11480, @ate INT = 11615
WHILE @de <= @ate
BEGIN
  SET @i = @i + 1;
  SET @de = @de + 1;
END
SELECT @i -- = 136
GO

-- Só por curiosidade, olha como um arquivo de banco fica zuado... 
-- Fragmentação né...
/*
Microsoft Windows [Version 10.0.18363.900]
(c) 2019 Microsoft Corporation. All rights reserved.

C:\WINDOWS\system32>nfi d:\DBs\AdventureWorks2017.mdf
NTFS File Sector Information Utility.
Copyright (C) Microsoft Corporation 1999. All rights reserved.

\DBs\AdventureWorks2017.mdf
    $STANDARD_INFORMATION (resident)
    $FILE_NAME (resident)
    $DATA (nonresident)
        logical sectors 2587039712-2587973599 (0x9a3317e0-0x9a4157df)
        logical sectors 2588216008-2588478151 (0x9a450ac8-0x9a490ac7)
        logical sectors 2588740296-2588871367 (0x9a4d0ac8-0x9a4f0ac7)
        logical sectors 2589002440-2590182087 (0x9a510ac8-0x9a630ac7)
        logical sectors 2590313160-2591152095 (0x9a650ac8-0x9a71d7df)
        logical sectors 2657741832-2665684719 (0x9e69ec08-0x9ee31eef)
*/



-- Scripts uteis... caso eu queira gerar arquivos maiores

-- Criar texto com 64KB
SELECT CHAR(13)+CHAR(10) + REPLICATE(CONVERT(VARCHAR(MAX), 'X'), 65536) + CHAR(13)+CHAR(10) AS Col1
FOR XML RAW, ELEMENTS
GO
-- Criar texto com 128KB
SELECT CHAR(13)+CHAR(10) + REPLICATE(CONVERT(VARCHAR(MAX), 'X'), 131072) + CHAR(13)+CHAR(10) AS Col1
FOR XML RAW, ELEMENTS
GO
-- Criar texto com 1MB 
SELECT CHAR(13)+CHAR(10) + REPLICATE(CONVERT(VARCHAR(MAX), 'X'), 1048576) + CHAR(13)+CHAR(10) AS Col1
FOR XML RAW, ELEMENTS
GO
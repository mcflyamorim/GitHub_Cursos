USE [master]
GO

-- Criar banco de teste
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
END
GO
CREATE DATABASE [Test1]
 ON  PRIMARY 
( NAME = N'Test1', FILENAME = N'C:\DBs\Test1.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024MB )
 LOG ON 
( NAME = N'Test1_log', FILENAME = N'C:\DBs\Test1_log.ldf' , SIZE = 100MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

-- 5 segundos pra rodar
USE Test1
GO
DROP TABLE IF EXISTS Table1
SELECT TOP 200000  
       IDENTITY(BigInt, 1, 1) AS Col1, 
       ISNULL(CONVERT(VarChar(250), NEWID()), '') AS Col2,
       ISNULL(CONVERT(VarChar(7000), REPLICATE('x', 5000)), '') AS Col3
  INTO Table1
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS
GO

-- Oh não, esse banco ta muito grande... 
-- Vamos comprimir pra salvar espaço...
-- 2148.00 MB
sp_helpdb Test1
GO



USE master
GO
-- Pegar o path do arquivo
SELECT filename FROM Test1.dbo.sysfiles WHERE fileid = 1
GO
ALTER DATABASE Test1 SET OFFLINE WITH ROLLBACK IMMEDIATE
GO

-- Vamos habilitar compressão nativa do NTFS no arquivo...
-- Sucesso... Tamanho do arquivo ficou MUITO menor...
-- "Size on disk" = 196MB... 
EXEC xp_cmdShell 'Compact /C C:\DBs\Test1.mdf'
GO
/*
  Compressing files in C:\DBs\
  Test1.mdf           2147483648 : 205762560 = 10.4 to 1 [OK]
  1 files within 1 directories were compressed.
  2,147,483,648 total bytes of data are stored in 205,762,560 bytes.
  The compression ratio is 10.4 to 1.
*/


-- Agora vamos voltar o banco pra online
ALTER DATABASE Test1 SET ONLINE
GO
/*
Msg 5118, Level 16, State 1, Line 67
The file "C:\DBs\Test1.mdf" is compressed but does not reside 
in a read-only database or filegroup. The file must be decompressed.

Msg 5181, Level 16, State 5, Line 67
Could not restart database "Test1". Reverting to the previous status.
Msg 5069, Level 16, State 1, Line 67
ALTER DATABASE statement failed.
*/

-- O que? Como assim não pode? ...

-- "The file must be decompressed" --

-- Ninguém manda nimin...

/*
  1 - Voltar banco pra offline

  ALTER DATABASE Test1 SET OFFLINE WITH ROLLBACK IMMEDIATE

  2 - Attachar windbg no processo do SQL

  3 - Fazer unassemble da function que faz o startup do FCB (sqlmin!FCB::Startup)
  
  uf sqlmin!FCB::Startup

  0:071> uf sqlmin!FCB::Startup
  Matched: 00007ffc`6bf156d0 sqlmin!FCB::Startup (<no parameter info>)
  Matched: 00007ffc`6bf15c00 sqlmin!FCB::Startup (<no parameter info>)
  Ambiguous symbol error at 'sqlmin!FCB::Startup'

  Ok, vamos ver os "uf" dos dois endereços de memória...
  Destaque para o seguinte trecho do código:
  sqlmin!FCB::Startup+0x196:
  00007ffc`6bf15d96 488dbb304b0000  lea     rdi,[rbx+4B30h]
  00007ffc`6bf15d9d 488bcf          mov     rcx,rdi
  00007ffc`6bf15da0 e84bdaffff      call    sqlmin!IsCompressedByNT (00007ffc`6bf137f0)
  00007ffc`6bf15da5 00c0            add     al,al
  00007ffc`6bf15da7 7437            je      sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch


  Podemos ver que temos o call pra function que vai validar se o 
  arquivo esta usando compression... sqlmin!IsCompressedByNT ... 

  Vamos colocar um breakpoint no endereço de memória anterior ao call da function... 
  que esta fazendo o mov dos dados da register rcx pra rdi...

  Minha intenção é parar antes que o compression seja validado e
  alterar o endereço de memória pra fazer o SQL achar que o arquivo 
  não está utilizando compression e subir o banco...

  bp 00007ffc`6bf15d96
  g

  Agora que o SQL ta de volta no ar... vamos tentar rodar o comando pra
  fazer o set db online

  ALTER DATABASE Test1 SET ONLINE
  GO

  O Windbg deve parar no bp em 00007ffc`6bf15d96...
  Repare que ele de fato parou na thread que esta tentando
  fazer o StartUp do banco... sqlmin!DBMgr::StartupDB...

  Breakpoint 0 hit
  sqlmin!FCB::Startup+0x196:
  00007ffc`6bf15d96 488dbb304b0000  lea     rdi,[rbx+4B30h]
  0:061> k
   # Child-SP          RetAddr           Call Site
  00 00000083`00ff6d90 00007ffc`6bf14fad sqlmin!FCB::Startup+0x196
  01 00000083`00ff6e00 00007ffc`6bee80e5 sqlmin!FCB::StartPrimaryFile+0xad
  02 00000083`00ff6e80 00007ffc`6bebdcfb sqlmin!DBTABLE::Startup+0x605
  03 00000083`00ff7e30 00007ffc`6bb206af sqlmin!DBMgr::StartupDB+0x8af
  04 00000083`00ff8d10 00007ffc`6bb2089d sqlmin!DBOpAgent::StartDBFrag+0xdf
  05 00000083`00ff8d90 00007ffc`6bed8967 sqlmin!DBOpAgent::StartupDB+0xcd
  06 00000083`00ff8dd0 00007ffc`6942ef5e sqlmin!DBMgr::ChangeDBState+0x16b7
  07 00000083`00ff9a00 00007ffc`6942785a sqllang!CStmtAlterDB::ChangeStateOption+0x2d0e
  08 00000083`00ffbdc0 00007ffc`68827488 sqllang!CStmtAlterDB::XretExecute+0x12da
  09 00000083`00ffc570 00007ffc`68826ec8 sqllang!CMsqlExecContext::ExecuteStmts<1,1>+0x8f8
  0a 00000083`00ffd110 00007ffc`68826513 sqllang!CMsqlExecContext::FExecute+0x946
  0b 00000083`00ffe0f0 00007ffc`6883031d sqllang!CSQLSource::Execute+0xb9c
  0c 00000083`00ffe3f0 00007ffc`68811a55 sqllang!process_request+0xcdd
  0d 00000083`00ffeaf0 00007ffc`68811833 sqllang!process_commands_internal+0x4b7
  0e 00000083`00ffec20 00007ffc`708d9b33 sqllang!process_messages+0x1f3
  0f 00000083`00ffee00 00007ffc`708da48d sqldk!SOS_Task::Param::Execute+0x232
  10 00000083`00fff400 00007ffc`708da295 sqldk!SOS_Scheduler::RunTask+0xb5
  11 00000083`00fff470 00007ffc`708f7020 sqldk!SOS_Scheduler::ProcessTasks+0x39d
  12 00000083`00fff590 00007ffc`708f7b2b sqldk!SchedulerManager::WorkerEntryPoint+0x2a1
  13 00000083`00fff660 00007ffc`708f7931 sqldk!SystemThreadDispatcher::ProcessWorker+0x402
  14 00000083`00fff960 00007ffd`06817bd4 sqldk!SchedulerManager::ThreadEntryPoint+0x3d8
  15 00000083`00fffa50 00007ffd`0774ce51 KERNEL32!BaseThreadInitThunk+0x14
  16 00000083`00fffa80 00000000`00000000 ntdll!RtlUserThreadStart+0x21

  Vamos seguir com o próximo comando a ser executado...

  0:061> p
  sqlmin!FCB::Startup+0x19d:
  00007ffc`6bf15d9d 488bcf          mov     rcx,rdi

  Esse é o comando que vai fazer o mov, dos dados nas registradoras...
  Vamos dar mais um p (step over) pra ver o que vai ser executado...

  0:061> p
  sqlmin!FCB::Startup+0x1a0:
  00007ffc`6bf15da0 e84bdaffff      call    sqlmin!IsCompressedByNT (00007ffc`6bf137f0)

  Opa, agora ele vai chamar a sqlmin!IsCompressedByNT... Mas antes de ele continuar
  vamos ver o que foi gravado na registradora rdi...

  0:061> dW @rdi
  00000243`bbcfcb70  0043 003a 005c 0044 0042 0073 005c 0054  C.:.\.D.B.s.\.T.
  00000243`bbcfcb80  0065 0073 0074 0031 002e 006d 0064 0066  e.s.t.1...m.d.f.
  00000243`bbcfcb90  0000 0000 04b4 0000 cfc0 b233 0243 0000  ..........3.C...
  00000243`bbcfcba0  0000 0000 04b1 0000 cf80 b233 0243 0000  ..........3.C...
  00000243`bbcfcbb0  0000 0000 04b1 0000 cf40 b233 0243 0000  ........@.3.C...
  00000243`bbcfcbc0  0000 0000 04b5 0000 cf00 b233 0243 0000  ..........3.C...
  00000243`bbcfcbd0  0000 0000 04a6 0000 cec0 b233 0243 0000  ..........3.C...
  00000243`bbcfcbe0  0000 0000 04b8 0000 ce80 b233 0243 0000  ..........3.C...

  Opa... Olha o path pro arquivo mdf ai...
  Pra alterar o dado dessa area de memória, vamos no menu view->memory do windbg
  em Virtual, coloca @rdi pra ele mostrar os dados desse endereço... 

  A string "C:\Test1.mdf" em hexa é "43 3a 5c 54 65 73 74 31 2e 6d 64 66"...
  Vamos alterar o 1, que é 0x31 em hexa... vamos trocar pra 32 :-) ... 
  ou seja, a string vai ficar ""C:\Test2.mdf"...

  Depois que fizer a alteração... é só fechar a janela de Memory e dar um go no windbg
  O resultado da IsCompressedByNT, vai ser false, pois o arquivo que ele vai validar
  não existe... :-)... na teoria, vamos conseguir seguir com o "set online" no banco...

  bc * 
  g

  Se tudo deu certo... o banco está online :-) ... 


  Pra referência... segue o resultado do unassemble da function sqlmin!DBMgr::StartupDB
  uf 00007ffc`6bf156d0; uf 00007ffc`6bf15c00;

  0:071> uf 00007ffc`6bf156d0; uf 00007ffc`6bf15c00;
  sqlmin!FCB::Startup:
  00007ffc`6bf156d0 488bc4          mov     rax,rsp
  00007ffc`6bf156d3 55              push    rbp
  00007ffc`6bf156d4 488da838ffffff  lea     rbp,[rax-0C8h]
  00007ffc`6bf156db 4881ecc0010000  sub     rsp,1C0h
  00007ffc`6bf156e2 48c7442420feffffff mov   qword ptr [rsp+20h],0FFFFFFFFFFFFFFFEh
  00007ffc`6bf156eb 48895810        mov     qword ptr [rax+10h],rbx
  00007ffc`6bf156ef 48897818        mov     qword ptr [rax+18h],rdi
  00007ffc`6bf156f3 488b054e532501  mov     rax,qword ptr [sqlmin!_security_cookie (00007ffc`6d16aa48)]
  00007ffc`6bf156fa 4833c4          xor     rax,rsp
  00007ffc`6bf156fd 488985b0000000  mov     qword ptr [rbp+0B0h],rax
  00007ffc`6bf15704 488bda          mov     rbx,rdx
  00007ffc`6bf15707 488bf9          mov     rdi,rcx
  00007ffc`6bf1570a 0fb64c2430      movzx   ecx,byte ptr [rsp+30h]
  00007ffc`6bf1570f 80e1fe          and     cl,0FEh
  00007ffc`6bf15712 884c2430        mov     byte ptr [rsp+30h],cl
  00007ffc`6bf15716 0fb6c1          movzx   eax,cl
  00007ffc`6bf15719 24fd            and     al,0FDh
  00007ffc`6bf1571b 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf1571f 0fb6c1          movzx   eax,cl
  00007ffc`6bf15722 24f9            and     al,0F9h
  00007ffc`6bf15724 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf15728 0fb6c1          movzx   eax,cl
  00007ffc`6bf1572b 24f1            and     al,0F1h
  00007ffc`6bf1572d 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf15731 0fb6c1          movzx   eax,cl
  00007ffc`6bf15734 24e1            and     al,0E1h
  00007ffc`6bf15736 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf1573a 0fb6c1          movzx   eax,cl
  00007ffc`6bf1573d 24c1            and     al,0C1h
  00007ffc`6bf1573f 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf15743 0fb6c1          movzx   eax,cl
  00007ffc`6bf15746 2481            and     al,81h
  00007ffc`6bf15748 88442430        mov     byte ptr [rsp+30h],al
  00007ffc`6bf1574c 80e101          and     cl,1
  00007ffc`6bf1574f 884c2430        mov     byte ptr [rsp+30h],cl
  00007ffc`6bf15753 0fb64c2431      movzx   ecx,byte ptr [rsp+31h]
  00007ffc`6bf15758 80e1fe          and     cl,0FEh
  00007ffc`6bf1575b 884c2431        mov     byte ptr [rsp+31h],cl
  00007ffc`6bf1575f 0fb6c1          movzx   eax,cl
  00007ffc`6bf15762 24fd            and     al,0FDh
  00007ffc`6bf15764 88442431        mov     byte ptr [rsp+31h],al
  00007ffc`6bf15768 0fb6c1          movzx   eax,cl
  00007ffc`6bf1576b 24f9            and     al,0F9h
  00007ffc`6bf1576d 88442431        mov     byte ptr [rsp+31h],al
  00007ffc`6bf15771 80e1f1          and     cl,0F1h
  00007ffc`6bf15774 884c2431        mov     byte ptr [rsp+31h],cl
  00007ffc`6bf15778 80c910          or      cl,10h
  00007ffc`6bf1577b 884c2431        mov     byte ptr [rsp+31h],cl
  00007ffc`6bf1577f 0fb6c1          movzx   eax,cl
  00007ffc`6bf15782 24df            and     al,0DFh
  00007ffc`6bf15784 88442431        mov     byte ptr [rsp+31h],al
  00007ffc`6bf15788 0fb6c1          movzx   eax,cl
  00007ffc`6bf1578b 249f            and     al,9Fh
  00007ffc`6bf1578d 88442431        mov     byte ptr [rsp+31h],al
  00007ffc`6bf15791 80e11f          and     cl,1Fh
  00007ffc`6bf15794 884c2431        mov     byte ptr [rsp+31h],cl
  00007ffc`6bf15798 0fb64c2432      movzx   ecx,byte ptr [rsp+32h]
  00007ffc`6bf1579d 80e1fe          and     cl,0FEh
  00007ffc`6bf157a0 884c2432        mov     byte ptr [rsp+32h],cl
  00007ffc`6bf157a4 0fb6c1          movzx   eax,cl
  00007ffc`6bf157a7 24fd            and     al,0FDh
  00007ffc`6bf157a9 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157ad 0fb6c1          movzx   eax,cl
  00007ffc`6bf157b0 24f9            and     al,0F9h
  00007ffc`6bf157b2 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157b6 0fb6c1          movzx   eax,cl
  00007ffc`6bf157b9 24f1            and     al,0F1h
  00007ffc`6bf157bb 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157bf 0fb6c1          movzx   eax,cl
  00007ffc`6bf157c2 24e1            and     al,0E1h
  00007ffc`6bf157c4 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157c8 0fb6c1          movzx   eax,cl
  00007ffc`6bf157cb 24c1            and     al,0C1h
  00007ffc`6bf157cd 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157d1 0fb6c1          movzx   eax,cl
  00007ffc`6bf157d4 2481            and     al,81h
  00007ffc`6bf157d6 88442432        mov     byte ptr [rsp+32h],al
  00007ffc`6bf157da 80e101          and     cl,1
  00007ffc`6bf157dd 884c2432        mov     byte ptr [rsp+32h],cl
  00007ffc`6bf157e1 0fb64c2433      movzx   ecx,byte ptr [rsp+33h]
  00007ffc`6bf157e6 80e1fe          and     cl,0FEh
  00007ffc`6bf157e9 884c2433        mov     byte ptr [rsp+33h],cl
  00007ffc`6bf157ed 0fb6c1          movzx   eax,cl
  00007ffc`6bf157f0 24fd            and     al,0FDh
  00007ffc`6bf157f2 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf157f6 0fb6c1          movzx   eax,cl
  00007ffc`6bf157f9 24f9            and     al,0F9h
  00007ffc`6bf157fb 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf157ff 0fb6c1          movzx   eax,cl
  00007ffc`6bf15802 24f1            and     al,0F1h
  00007ffc`6bf15804 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf15808 0fb6c1          movzx   eax,cl
  00007ffc`6bf1580b 24e1            and     al,0E1h
  00007ffc`6bf1580d 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf15811 0fb6c1          movzx   eax,cl
  00007ffc`6bf15814 24c1            and     al,0C1h
  00007ffc`6bf15816 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf1581a 0fb6c1          movzx   eax,cl
  00007ffc`6bf1581d 2481            and     al,81h
  00007ffc`6bf1581f 88442433        mov     byte ptr [rsp+33h],al
  00007ffc`6bf15823 80e101          and     cl,1
  00007ffc`6bf15826 884c2433        mov     byte ptr [rsp+33h],cl
  00007ffc`6bf1582a 80642434fe      and     byte ptr [rsp+34h],0FEh
  00007ffc`6bf1582f 33c9            xor     ecx,ecx
  00007ffc`6bf15831 894c2438        mov     dword ptr [rsp+38h],ecx
  00007ffc`6bf15835 b8ffff0000      mov     eax,0FFFFh
  00007ffc`6bf1583a 668944243c      mov     word ptr [rsp+3Ch],ax
  00007ffc`6bf1583f 48894c2440      mov     qword ptr [rsp+40h],rcx
  00007ffc`6bf15844 c744244802000000 mov     dword ptr [rsp+48h],2
  00007ffc`6bf1584c 0f57c0          xorps   xmm0,xmm0
  00007ffc`6bf1584f 660f7f442450    movdqa  xmmword ptr [rsp+50h],xmm0
  00007ffc`6bf15855 0f57c9          xorps   xmm1,xmm1
  00007ffc`6bf15858 660f7f4c2460    movdqa  xmmword ptr [rsp+60h],xmm1
  00007ffc`6bf1585e 4889442470      mov     qword ptr [rsp+70h],rax
  00007ffc`6bf15863 48894c2478      mov     qword ptr [rsp+78h],rcx
  00007ffc`6bf15868 660f7f4580      movdqa  xmmword ptr [rbp-80h],xmm0
  00007ffc`6bf1586d 806590fe        and     byte ptr [rbp-70h],0FEh
  00007ffc`6bf15871 33d2            xor     edx,edx
  00007ffc`6bf15873 41b810010000    mov     r8d,110h
  00007ffc`6bf15879 488d4d98        lea     rcx,[rbp-68h]
  00007ffc`6bf1587d e841c1ebfe      call    sqlmin!memset (00007ffc`6add19c3)
  00007ffc`6bf15882 90              nop
  00007ffc`6bf15883 4c8bc3          mov     r8,rbx
  00007ffc`6bf15886 488d542430      lea     rdx,[rsp+30h]
  00007ffc`6bf1588b 488bcf          mov     rcx,rdi
  00007ffc`6bf1588e e86d030000      call    sqlmin!FCB::Startup (00007ffc`6bf15c00)
  00007ffc`6bf15893 90              nop
  00007ffc`6bf15894 f644243110      test    byte ptr [rsp+31h],10h
  00007ffc`6bf15899 740e            je      sqlmin!FCB::Startup+0x1d9 (00007ffc`6bf158a9)  Branch

  sqlmin!FCB::Startup+0x1cb:
  00007ffc`6bf1589b 488b4d80        mov     rcx,qword ptr [rbp-80h]
  00007ffc`6bf1589f 4885c9          test    rcx,rcx
  00007ffc`6bf158a2 7405            je      sqlmin!FCB::Startup+0x1d9 (00007ffc`6bf158a9)  Branch

  sqlmin!FCB::Startup+0x1d4:
  00007ffc`6bf158a4 e8a7071aff      call    sqlmin!RemapFileEntry::`scalar deleting destructor' (00007ffc`6b0b6050)

  sqlmin!FCB::Startup+0x1d9:
  00007ffc`6bf158a9 488b8db0000000  mov     rcx,qword ptr [rbp+0B0h]
  00007ffc`6bf158b0 4833cc          xor     rcx,rsp
  00007ffc`6bf158b3 e8e8c0ebfe      call    sqlmin!_security_check_cookie (00007ffc`6add19a0)
  00007ffc`6bf158b8 4c8d9c24c0010000 lea     r11,[rsp+1C0h]
  00007ffc`6bf158c0 498b5b18        mov     rbx,qword ptr [r11+18h]
  00007ffc`6bf158c4 498b7b20        mov     rdi,qword ptr [r11+20h]
  00007ffc`6bf158c8 498be3          mov     rsp,r11
  00007ffc`6bf158cb 5d              pop     rbp
  00007ffc`6bf158cc c3              ret
  sqlmin!FCB::Startup:
  00007ffc`6bf15c00 fff5            push    rbp
  00007ffc`6bf15c02 56              push    rsi
  00007ffc`6bf15c03 57              push    rdi
  00007ffc`6bf15c04 4883ec50        sub     rsp,50h
  00007ffc`6bf15c08 48c7442430feffffff mov   qword ptr [rsp+30h],0FFFFFFFFFFFFFFFEh
  00007ffc`6bf15c11 48899c2488000000 mov     qword ptr [rsp+88h],rbx
  00007ffc`6bf15c19 498be8          mov     rbp,r8
  00007ffc`6bf15c1c 488bf2          mov     rsi,rdx
  00007ffc`6bf15c1f 488bd9          mov     rbx,rcx
  00007ffc`6bf15c22 0fb602          movzx   eax,byte ptr [rdx]
  00007ffc`6bf15c25 448b495c        mov     r9d,dword ptr [rcx+5Ch]
  00007ffc`6bf15c29 41c1e908        shr     r9d,8
  00007ffc`6bf15c2d 440ac8          or      r9b,al
  00007ffc`6bf15c30 4432c8          xor     r9b,al
  00007ffc`6bf15c33 4180e101        and     r9b,1
  00007ffc`6bf15c37 4432c8          xor     r9b,al
  00007ffc`6bf15c3a 44880a          mov     byte ptr [rdx],r9b
  00007ffc`6bf15c3d 488b01          mov     rax,qword ptr [rcx]
  00007ffc`6bf15c40 ff9090010000    call    qword ptr [rax+190h]
  00007ffc`6bf15c46 84c0            test    al,al
  00007ffc`6bf15c48 7410            je      sqlmin!FCB::Startup+0x5a (00007ffc`6bf15c5a)  Branch

  sqlmin!FCB::Startup+0x4a:
  00007ffc`6bf15c4a 4c8bc3          mov     r8,rbx
  00007ffc`6bf15c4d 0fb75320        movzx   edx,word ptr [rbx+20h]
  00007ffc`6bf15c51 0fb74b58        movzx   ecx,word ptr [rbx+58h]
  00007ffc`6bf15c55 e8e60b2300      call    sqlmin!RBPEX::NotifyFileStartup (00007ffc`6c146840)

  sqlmin!FCB::Startup+0x5a:
  00007ffc`6bf15c5a 488bd6          mov     rdx,rsi
  00007ffc`6bf15c5d 488bcb          mov     rcx,rbx
  00007ffc`6bf15c60 e87bfcffff      call    sqlmin!FCB::OpenForStartup (00007ffc`6bf158e0)
  00007ffc`6bf15c65 0f104500        movups  xmm0,xmmword ptr [rbp]
  00007ffc`6bf15c69 0f118380000000  movups  xmmword ptr [rbx+80h],xmm0
  00007ffc`6bf15c70 488b03          mov     rax,qword ptr [rbx]
  00007ffc`6bf15c73 488bcb          mov     rcx,rbx
  00007ffc`6bf15c76 ff5030          call    qword ptr [rax+30h]
  00007ffc`6bf15c79 85c0            test    eax,eax
  00007ffc`6bf15c7b 7520            jne     sqlmin!FCB::Startup+0x9d (00007ffc`6bf15c9d)  Branch

  sqlmin!FCB::Startup+0x7d:
  00007ffc`6bf15c7d b935140000      mov     ecx,1435h
  00007ffc`6bf15c82 e859849100      call    sqlmin!scierrlog (00007ffc`6c82e0e0)
  00007ffc`6bf15c87 ba49000000      mov     edx,49h
  00007ffc`6bf15c8c 8d4aea          lea     ecx,[rdx-16h]
  00007ffc`6bf15c8f 448d4ab9        lea     r9d,[rdx-47h]
  00007ffc`6bf15c93 448d42c7        lea     r8d,[rdx-39h]
  00007ffc`6bf15c97 ff15db9fa700    call    qword ptr [sqlmin!_imp_?ex_raiseYAHHHHHZZ (00007ffc`6c98fc78)]

  sqlmin!FCB::Startup+0x9d:
  00007ffc`6bf15c9d 488b051499a700  mov     rax,qword ptr [sqlmin!_imp_?sm_invariantTscAvailableBase_PublicGlobals (00007ffc`6c98f5b8)]
  00007ffc`6bf15ca4 833800          cmp     dword ptr [rax],0
  00007ffc`6bf15ca7 7412            je      sqlmin!FCB::Startup+0xbb (00007ffc`6bf15cbb)  Branch

  sqlmin!FCB::Startup+0xa9:
  00007ffc`6bf15ca9 488d4c2478      lea     rcx,[rsp+78h]
  00007ffc`6bf15cae ff15f479a700    call    qword ptr [sqlmin!_imp_QueryPerformanceCounter (00007ffc`6c98d6a8)]
  00007ffc`6bf15cb4 488b7c2478      mov     rdi,qword ptr [rsp+78h]
  00007ffc`6bf15cb9 eb08            jmp     sqlmin!FCB::Startup+0xc3 (00007ffc`6bf15cc3)  Branch

  sqlmin!FCB::Startup+0xbb:
  00007ffc`6bf15cbb 488b3c250800fe7f mov     rdi,qword ptr [SharedUserData+0x8 (00000000`7ffe0008)]

  sqlmin!FCB::Startup+0xc3:
  00007ffc`6bf15cc3 48897c2438      mov     qword ptr [rsp+38h],rdi
  00007ffc`6bf15cc8 c744244001000000 mov     dword ptr [rsp+40h],1
  00007ffc`6bf15cd0 4889742448      mov     qword ptr [rsp+48h],rsi
  00007ffc`6bf15cd5 8b4608          mov     eax,dword ptr [rsi+8]
  00007ffc`6bf15cd8 83e802          sub     eax,2
  00007ffc`6bf15cdb 83f801          cmp     eax,1
  00007ffc`6bf15cde 770a            ja      sqlmin!FCB::Startup+0xea (00007ffc`6bf15cea)  Branch

  sqlmin!FCB::Startup+0xe0:
  00007ffc`6bf15ce0 f6435c40        test    byte ptr [rbx+5Ch],40h
  00007ffc`6bf15ce4 7404            je      sqlmin!FCB::Startup+0xea (00007ffc`6bf15cea)  Branch

  sqlmin!FCB::Startup+0xe6:
  00007ffc`6bf15ce6 33d2            xor     edx,edx
  00007ffc`6bf15ce8 eb05            jmp     sqlmin!FCB::Startup+0xef (00007ffc`6bf15cef)  Branch

  sqlmin!FCB::Startup+0xea:
  00007ffc`6bf15cea ba01000000      mov     edx,1

  sqlmin!FCB::Startup+0xef:
  00007ffc`6bf15cef 488bcb          mov     rcx,rbx
  00007ffc`6bf15cf2 e819430100      call    sqlmin!FCB::RefreshHeaderFields (00007ffc`6bf2a010)
  00007ffc`6bf15cf7 90              nop
  00007ffc`6bf15cf8 488b05b998a700  mov     rax,qword ptr [sqlmin!_imp_?sm_invariantTscAvailableBase_PublicGlobals (00007ffc`6c98f5b8)]
  00007ffc`6bf15cff 833800          cmp     dword ptr [rax],0
  00007ffc`6bf15d02 7418            je      sqlmin!FCB::Startup+0x11c (00007ffc`6bf15d1c)  Branch

  sqlmin!FCB::Startup+0x104:
  00007ffc`6bf15d04 488d8c2480000000 lea     rcx,[rsp+80h]
  00007ffc`6bf15d0c ff159679a700    call    qword ptr [sqlmin!_imp_QueryPerformanceCounter (00007ffc`6c98d6a8)]
  00007ffc`6bf15d12 488b842480000000 mov     rax,qword ptr [rsp+80h]
  00007ffc`6bf15d1a eb0d            jmp     sqlmin!FCB::Startup+0x129 (00007ffc`6bf15d29)  Branch

  sqlmin!FCB::Startup+0x11c:
  00007ffc`6bf15d1c 488b04250800fe7f mov     rax,qword ptr [SharedUserData+0x8 (00000000`7ffe0008)]
  00007ffc`6bf15d24 488b7c2438      mov     rdi,qword ptr [rsp+38h]

  sqlmin!FCB::Startup+0x129:
  00007ffc`6bf15d29 483bc7          cmp     rax,rdi
  00007ffc`6bf15d2c 7205            jb      sqlmin!FCB::Startup+0x133 (00007ffc`6bf15d33)  Branch

  sqlmin!FCB::Startup+0x12e:
  00007ffc`6bf15d2e 482bc7          sub     rax,rdi
  00007ffc`6bf15d31 eb02            jmp     sqlmin!FCB::Startup+0x135 (00007ffc`6bf15d35)  Branch

  sqlmin!FCB::Startup+0x133:
  00007ffc`6bf15d33 33c0            xor     eax,eax

  sqlmin!FCB::Startup+0x135:
  00007ffc`6bf15d35 48014670        add     qword ptr [rsi+70h],rax
  00007ffc`6bf15d39 f60601          test    byte ptr [rsi],1
  00007ffc`6bf15d3c 753a            jne     sqlmin!FCB::Startup+0x178 (00007ffc`6bf15d78)  Branch

  sqlmin!FCB::Startup+0x13e:
  00007ffc`6bf15d3e 488b8380000000  mov     rax,qword ptr [rbx+80h]
  00007ffc`6bf15d45 483b4500        cmp     rax,qword ptr [rbp]
  00007ffc`6bf15d49 750d            jne     sqlmin!FCB::Startup+0x158 (00007ffc`6bf15d58)  Branch

  sqlmin!FCB::Startup+0x14b:
  00007ffc`6bf15d4b 488b8388000000  mov     rax,qword ptr [rbx+88h]
  00007ffc`6bf15d52 483b4508        cmp     rax,qword ptr [rbp+8]
  00007ffc`6bf15d56 7420            je      sqlmin!FCB::Startup+0x178 (00007ffc`6bf15d78)  Branch

  sqlmin!FCB::Startup+0x158:
  00007ffc`6bf15d58 b935140000      mov     ecx,1435h
  00007ffc`6bf15d5d e87e839100      call    sqlmin!scierrlog (00007ffc`6c82e0e0)
  00007ffc`6bf15d62 ba49000000      mov     edx,49h
  00007ffc`6bf15d67 8d4aea          lea     ecx,[rdx-16h]
  00007ffc`6bf15d6a 448d4ab8        lea     r9d,[rdx-48h]
  00007ffc`6bf15d6e 448d42c7        lea     r8d,[rdx-39h]
  00007ffc`6bf15d72 ff15009fa700    call    qword ptr [sqlmin!_imp_?ex_raiseYAHHHHHZZ (00007ffc`6c98fc78)]

  sqlmin!FCB::Startup+0x178:
  00007ffc`6bf15d78 8b435c          mov     eax,dword ptr [rbx+5Ch]
  00007ffc`6bf15d7b 0fbae00c        bt      eax,0Ch
  00007ffc`6bf15d7f 725f            jb      sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x181:
  00007ffc`6bf15d81 807e0100        cmp     byte ptr [rsi+1],0
  00007ffc`6bf15d85 7c59            jl      sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x187:
  00007ffc`6bf15d87 0fbae01d        bt      eax,1Dh
  00007ffc`6bf15d8b 7253            jb      sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x18d:
  00007ffc`6bf15d8d 83bb544e000000  cmp     dword ptr [rbx+4E54h],0
  00007ffc`6bf15d94 754a            jne     sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x196:
  00007ffc`6bf15d96 488dbb304b0000  lea     rdi,[rbx+4B30h]
  00007ffc`6bf15d9d 488bcf          mov     rcx,rdi
  00007ffc`6bf15da0 e84bdaffff      call    sqlmin!IsCompressedByNT (00007ffc`6bf137f0)
  00007ffc`6bf15da5 00c0            add     al,al
  00007ffc`6bf15da7 7437            je      sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x1a9:
  00007ffc`6bf15da9 833d08bf240100  cmp     dword ptr [sqlmin!ResourceStr+0x38b8 (00007ffc`6d161cb8)],0
  00007ffc`6bf15db0 7526            jne     sqlmin!FCB::Startup+0x1d8 (00007ffc`6bf15dd8)  Branch

  sqlmin!FCB::Startup+0x1b2:
  00007ffc`6bf15db2 833d03bf240100  cmp     dword ptr [sqlmin!ResourceStr+0x38bc (00007ffc`6d161cbc)],0
  00007ffc`6bf15db9 751d            jne     sqlmin!FCB::Startup+0x1d8 (00007ffc`6bf15dd8)  Branch

  sqlmin!FCB::Startup+0x1bb:
  00007ffc`6bf15dbb 48897c2420      mov     qword ptr [rsp+20h],rdi
  00007ffc`6bf15dc0 ba12000000      mov     edx,12h
  00007ffc`6bf15dc5 8d4a21          lea     ecx,[rdx+21h]
  00007ffc`6bf15dc8 448d4aef        lea     r9d,[rdx-11h]
  00007ffc`6bf15dcc 448d42fe        lea     r8d,[rdx-2]
  00007ffc`6bf15dd0 ff15a29ea700    call    qword ptr [sqlmin!_imp_?ex_raiseYAHHHHHZZ (00007ffc`6c98fc78)]
  00007ffc`6bf15dd6 eb08            jmp     sqlmin!FCB::Startup+0x1e0 (00007ffc`6bf15de0)  Branch

  sqlmin!FCB::Startup+0x1d8:
  00007ffc`6bf15dd8 488bcb          mov     rcx,rbx
  00007ffc`6bf15ddb e8d02a0200      call    sqlmin!FCB::UncompressFile (00007ffc`6bf388b0)

  sqlmin!FCB::Startup+0x1e0:
  00007ffc`6bf15de0 83bbb007000000  cmp     dword ptr [rbx+7B0h],0
  00007ffc`6bf15de7 760a            jbe     sqlmin!FCB::Startup+0x1f3 (00007ffc`6bf15df3)  Branch

  sqlmin!FCB::Startup+0x1e9:
  00007ffc`6bf15de9 c7834402000000100000 mov dword ptr [rbx+244h],1000h

  sqlmin!FCB::Startup+0x1f3:
  00007ffc`6bf15df3 ba01000000      mov     edx,1
  00007ffc`6bf15df8 488bcb          mov     rcx,rbx
  00007ffc`6bf15dfb e880000000      call    sqlmin!FCB::CheckSectorSizes (00007ffc`6bf15e80)
  00007ffc`6bf15e00 804b7401        or      byte ptr [rbx+74h],1
  00007ffc`6bf15e04 33c0            xor     eax,eax
  00007ffc`6bf15e06 4889442470      mov     qword ptr [rsp+70h],rax
  00007ffc`6bf15e0b 488b0d5695a700  mov     rcx,qword ptr [sqlmin!_imp_?SOS_OS_OsInfo (00007ffc`6c98f368)]
  00007ffc`6bf15e12 ff15689ea700    call    qword ptr [sqlmin!_imp_?IsXPlatInstanceOsInfoQEBA?B_NXZ (00007ffc`6c98fc80)]
  00007ffc`6bf15e18 84c0            test    al,al
  00007ffc`6bf15e1a 744e            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x21c:
  00007ffc`6bf15e1c 488b03          mov     rax,qword ptr [rbx]
  00007ffc`6bf15e1f 488bcb          mov     rcx,rbx
  00007ffc`6bf15e22 ff9080000000    call    qword ptr [rax+80h]
  00007ffc`6bf15e28 85c0            test    eax,eax
  00007ffc`6bf15e2a 743e            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x22c:
  00007ffc`6bf15e2c f605bb45250102  test    byte ptr [sqlmin!g_rgUlTraceFlags+0x6e (00007ffc`6d16a3ee)],2
  00007ffc`6bf15e33 7435            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x235:
  00007ffc`6bf15e35 807b5000        cmp     byte ptr [rbx+50h],0
  00007ffc`6bf15e39 742f            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x23b:
  00007ffc`6bf15e3b 8b8398500000    mov     eax,dword ptr [rbx+5098h]
  00007ffc`6bf15e41 85c0            test    eax,eax
  00007ffc`6bf15e43 7525            jne     sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x245:
  00007ffc`6bf15e45 488d542470      lea     rdx,[rsp+70h]
  00007ffc`6bf15e4a 488b4b18        mov     rcx,qword ptr [rbx+18h]
  00007ffc`6bf15e4e ff152473a700    call    qword ptr [sqlmin!_imp_GetFileSizeEx (00007ffc`6c98d178)]
  00007ffc`6bf15e54 85c0            test    eax,eax
  00007ffc`6bf15e56 7412            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x258:
  00007ffc`6bf15e58 488b542470      mov     rdx,qword ptr [rsp+70h]
  00007ffc`6bf15e5d 4885d2          test    rdx,rdx
  00007ffc`6bf15e60 7408            je      sqlmin!FCB::Startup+0x26a (00007ffc`6bf15e6a)  Branch

  sqlmin!FCB::Startup+0x262:
  00007ffc`6bf15e62 488bcb          mov     rcx,rbx
  00007ffc`6bf15e65 e8f666ffff      call    sqlmin!FCB::StartPmemPrefaulter (00007ffc`6bf0c560)

  sqlmin!FCB::Startup+0x26a:
  00007ffc`6bf15e6a 488b9c2488000000 mov     rbx,qword ptr [rsp+88h]
  00007ffc`6bf15e72 4883c450        add     rsp,50h
  00007ffc`6bf15e76 5f              pop     rdi
  00007ffc`6bf15e77 5e              pop     rsi
  00007ffc`6bf15e78 5d              pop     rbp
  00007ffc`6bf15e79 c3              ret

*/ 

USE Test1
GO

-- Vamos tentar ler os dados da tabela Table1
-- Será que vai dar pau?
SELECT TOP 1000 * FROM Table1
GO

-- Vamos inserir mais 500 mil linhas pra ver como q fica... 
INSERT INTO Table1 WITH(TABLOCK) (Col2, Col3)
SELECT TOP 500000
       ISNULL(CONVERT(VarChar(250), NEWID()), '') AS Col2,
       ISNULL(CONVERT(VarChar(7000), REPLICATE('x', 5000)), '') AS Col3
  FROM sysobjects A
 CROSS JOIN sysobjects B
 CROSS JOIN sysobjects C
 CROSS JOIN sysobjects D
GO
-- Depois que rodar, ver errorlog... algum problema incomum? ...



CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
-- Foi?
SELECT COUNT(*) FROM Table1
GO


-- Wow... so far so good... 

-- Mas e os I/Os... tão sendo sync?
-- Com a palavra o saudoso Ken Henderson:
/*
"One circumstance in which Windows never honors an 
async I/O request is when the file it's reading or 
writing is compressed.  When calling ReadFile or WriteFile 
against a compressed file, Windows always runs the 
operation synchronously, regardless of whether the 
caller requested an async I/O operation.  
That's right:  compressing a file disables an 
app's ability to read or write it asynchronously."
*/

CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO


-- Vamos comparar a performance com uma tabela com os mesmo dados 
-- mas num banco (Test3) que não ta usando compression


-- Criar banco de teste
USE master
GO
IF exists (select * from sysdatabases where name='Test3')
BEGIN
  ALTER DATABASE Test3 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test3
END
GO
CREATE DATABASE Test3
 ON  PRIMARY 
( NAME = N'Test3', FILENAME = N'C:\DBs\Test3.mdf' , SIZE = 1024MB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024MB )
 LOG ON 
( NAME = N'Test3_log', FILENAME = N'C:\DBs\Test3_log.ldf' , SIZE = 1MB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO


USE Test3
GO
-- Criando tabela no Northwind
DROP TABLE IF EXISTS Test3.dbo.Table1
SELECT *
  INTO Test3.dbo.Table1
  FROM Test1.dbo.Table1
GO

-- Qual a diferença de tamanho dos arquivos de banco? 
-- Ué, mesma coisa?
sp_helpdb Test3
GO
sp_helpdb Test1 -- Mas o "size on disk" é só 510MB :-) ... SUCESSO!
GO


-- E a performance dos I/Os?
USE Test1
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT COUNT(*) 
  FROM Test1.dbo.Table1
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
GO
USE Test3
GO
CHECKPOINT; DBCC DROPCLEANBUFFERS;
GO
SET STATISTICS IO, TIME ON
SELECT COUNT(*) 
  FROM Test3.dbo.Table1
OPTION (MAXDOP 1)
SET STATISTICS IO, TIME OFF
GO


-- Agora vamos apagar o banco ... pra ver o que acontece... :-)
USE master
GO
if exists (select * from sysdatabases where name='Test1')
BEGIN
  ALTER DATABASE Test1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE
		DROP DATABASE Test1
END
GO


/*

https://support.microsoft.com/en-us/help/897284/diagnostics-in-sql-server-help-detect-stalled-and-stuck-i-o-operations
Microsoft does not support Microsoft SQL Server 7.0 or Microsoft 
SQL Server 2000 data files and log files on compressed drives. 
NTFS compression is not safe for SQL Server because NTFS 
compression breaks Write Ahead Logging (WAL) protocol. 
NTFS compression also requires increased processing 
for each I/O operation. Compression creates "one at a time" like 
behavior that causes severe performance issues to occur.

https://support.microsoft.com/en-us/help/231347/description-of-support-for-sql-server-databases-on-compressed-volumes
More Information
Although it is physically possible to add SQL Server databases on compressed volumes, 
we do not recommend this, and we do not support it. The underlying 
reasons for this include the following:
Performance

  Databases on compressed volumes may cause significant performance overhead. 
  The amount will vary, depending on the volume of I/O and on the ratio of reads to writes. 
  However, over 500 percent degradation was observed under some conditions.
  Database recovery

  Reliable transactional recovery of the database requires sector-aligned writes, 
  and compressed volumes do not support this scenario. A second issue concerns 
  internal recovery space management. SQL Server internally reserves preallocated 
  space in database files for rollbacks. It is possible on compressed volumes to 
  receive an "Out of Space" error on preallocated files, and this interferes 
  with successful recovery.


  Alguns outros posts:

  https://docs.microsoft.com/en-us/archive/blogs/sanchan/sql-server-2005-and-compressed-drives-what-you-should-know
  https://docs.microsoft.com/en-us/archive/blogs/khen1234/why-you-shouldnt-compress-sql-server-data-and-log-files

*/
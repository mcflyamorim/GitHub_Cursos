Clear-Host

# Starting demo... 
Write-Output "Preparing demo..."

$VerbosePreference = 'SilentlyContinue'
. "$PSScriptRoot\Invoke-SQLCmd2.ps1"

$computername = $env:computername
$ServerInstance = "$computername\SQL2017"

$user = "sa"
$password = '@bc12345'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepareDemo1.sql" -QueryTimeout 600 | Out-Null

$tsql = 'IF OBJECT_ID(''tempdb.dbo.#tmp1'') IS NOT NULL DROP TABLE #TMP1; SELECT TOP(10000) a.* INTO #TMP1 FROM sysobjects a, sysobjects b, sysobjects c;';

Write-Output "Starting demo..."

$tmpCommand = "cmd.exe /C C:\RMLUtils\ostress.exe -Usa -P@bc12345 -S$ServerInstance -n50 -r50 -dNorthwind -Q""$tsql"" -q" 
$command = @"
$tmpCommand
"@

Invoke-Expression -Command:$command

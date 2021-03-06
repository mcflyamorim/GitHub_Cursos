Clear-Host

# Starting demo... 
Write-Output "Preparing demo..."

$VerbosePreference = 'SilentlyContinue'
$computername = $env:computername
$ServerInstance = "$computername\SQL2017"

$user = "sa"
$password = '@bc12345'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepareDemo1.sql" -Database Northwind -QueryTimeout 600 | Out-Null
Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -Query "BEGIN TRAN; UPDATE TestTab1 SET Col1 = 10 WHERE ID = 10000;--ROLLBACK;" -Database Northwind -QueryTimeout 600 | Out-Null

$tsql = 'SELECT * FROM TestTab1 WHERE ID = 10000'
#$tsql = 'SELECT 1 WHERE 1=0'

Write-Output "Starting demo..."

$tmpCommand = "cmd.exe /C C:\RMLUtils\ostress.exe -Usa -P$password -S$ServerInstance -n3000 -r5 -dNorthwind -Q""$tsql"" -q" 
$command = @"
$tmpCommand
"@

Invoke-Expression -Command:$command

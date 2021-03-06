Clear-Host

# Starting demo... 
Write-Output "Preparing demo..."

$VerbosePreference = 'SilentlyContinue'
$computername = $env:computername
$ServerInstance = "$computername\SQL2008R2"

$user = "sa"
$password = '@bc12345'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepareDemo1.sql" -Database Northwind -QueryTimeout 600 | Out-Null
Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepareDemo2.sql" -Database Northwind -QueryTimeout 600 | Out-Null

$tsql = 'Exec st_Call_fn_dump_dblog'

Write-Output "Starting demo..."

$tmpCommand = "cmd.exe /C C:\RMLUtils\ostress.exe -Usa -P$password -S$ServerInstance -n100 -r1000 -dNorthwind -Q""$tsql"" -q" 
$command = @"
$tmpCommand
"@

Invoke-Expression -Command:$command

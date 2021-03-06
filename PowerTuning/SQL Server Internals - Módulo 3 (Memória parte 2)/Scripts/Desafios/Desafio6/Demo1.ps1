Clear-Host

Write-Output "Iniciando execução do desafio 1"
$VerbosePreference = 'SilentlyContinue'


$computername = $env:computername
$ServerInstance = "$computername\SQL2017"

$user = "sa"
$password = '@bc123456789'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepararDesafio6.sql" -QueryTimeout 600 | Out-Null

$tsql = 'SELECT TOP 100 * FROM Desafio6.dbo.ProductsBig ORDER BY ProductName DESC;'

$tmpCommand = "cmd.exe /C C:\RMLUtils\ostress.exe -Usa -P@bc123456789 -S$ServerInstance -n500 -r50 -Q""$tsql"" -q" 
$command = @"
$tmpCommand
"@

Invoke-Expression -Command:$command

pause
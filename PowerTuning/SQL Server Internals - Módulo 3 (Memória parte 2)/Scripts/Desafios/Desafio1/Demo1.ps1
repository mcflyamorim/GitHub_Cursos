Clear-Host

Write-Output "Iniciando execução do desafio 1"
$VerbosePreference = 'SilentlyContinue'

$computername = $env:computername
$ServerInstance = "$computername\SQL201432bit"

$user = "sa"
$password = '@bc12345'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -InputFile "$PSScriptRoot\PrepararDesafio1.sql" -QueryTimeout 600 | Out-Null

$tsql = "SELECT TOP 200 * 
           FROM Desafio1.dbo.OrdersBig 
		  ORDER BY Value DESC
		 OPTION (MAXDOP 1)"

$i = 1
DO
{
  $i
  $i++
  Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -Query $tsql | Out-Null
  Write-Output "Pode começa que ta tudo dano certo..."
} While ($i -le 100)

Write-Output "Termino da execução do desafio 1"
Pause
Clear-Host

$VerbosePreference = 'SilentlyContinue'
$computername = $env:computername
$ServerInstance = "172.17.23.145\SQL2017"

$user = "sa"
$password = '@bc12345'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 

Write-Output "Starting demo..."

while (1 -eq 1) 
{
	try 
	{
		Invoke-Sqlcmd2 -ServerInstance $ServerInstance -Credential $cred -Query "SELECT 'Palmeiras não tem mundial!' WHERE EncryptByPassPhrase('','') <> '' " -Database Master -ErrorAction Stop | Out-Null
		$vGetDate = Get-Date -Format G
		Write-Output "$vGetDate : Command ran successfully..."
		Start-Sleep 1

	} 
	catch 
	{
		$ErrorMessage = $_.Exception.Message
		$FailedItem = $_.Exception.ItemName
		$vGetDate = Get-Date -Format G
		Write-Output "$vGetDate : Ops, something is not working... call Fabiano: $ErrorMessage"
	}
}

Write-Output "Finished demo..."

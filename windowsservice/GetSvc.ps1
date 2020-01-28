#########################################################################################################
#   Script: GetSvc.ps1
#   Version: 1.0
#   Created: enzobercasio
#   Description: Script to get current window service status
##########################################################################################################

[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True,Position=0,ParameterSetName="ComputerName")]
		[String]$ComputerName,
		[Parameter(Mandatory=$True,Position=1)]
		[String]$Service
	)

	Try{

		$user = "domain\serveruser"
		$password = "password"


		$secstr = New-Object -TypeName System.Security.SecureString
		$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
		$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $secstr

		$Remote = New-PSSEssion -computer $ComputerName -credential $Cred -ErrorAction Stop
		$Date = Get-Date

		"CURRENT SERVICE STATUS ($Date): "

		if($Service -eq "ssh")
		{
			invoke-command -session $Remote -scriptblock{$services =  Get-service}
			invoke-command -session $Remote -Scriptblock{$services | where-object{$_.Name -eq 'SSHTectiaServer'}} | format-table -property PSComputerName, Name, Status | out-string
		}
		elseif ($Service -eq "iis")
		{
			invoke-command -session $Remote -scriptblock{$services =  Get-service}
			invoke-command -session $Remote -Scriptblock{$services | where-object{$_.Name -eq 'W3SVC'}} | format-table -property PSComputerName, Name, Status | out-string
		}
		else
		{
			"Type correct service (ssh, iis)"
		}

		remove-pssession $Remote

	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		"WARNING! Remote connection to server " + $ComputerName + " failed."
		""
 		"ERROR MESSAGE: "
		$ErrorMessage
	}

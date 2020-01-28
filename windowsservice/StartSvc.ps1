#########################################################################################################
#   Script: StartSvc.ps1
#   Version: 1.0
#   Created: enzobercasio
#   Description: Script to start window service
##########################################################################################################

[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True,Position=0,ParameterSetName="ComputerName")]
		[String]$ComputerName,
		[Parameter(Mandatory=$True,Position=1)]
		[String]$Service,
		[Parameter(Mandatory=$True,Position=2)]
		[String]$Username,
		[Parameter(Mandatory=$True,Position=3)]
		[String]$Password

	)

	Try{

		$user = "domain\" + $Username


		$secstr = New-Object -TypeName System.Security.SecureString
		$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
		$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $secstr

		$Remote = New-PSSEssion -computer $ComputerName -credential $Cred -ErrorAction Stop
		$Date = Get-Date

		"SERVICE START COMMAND INITIATED ($Date): "
		if($Service -eq "ssh")
		{
			invoke-command -session $Remote -scriptblock{$services =  Get-service}
			invoke-command -session $Remote -Scriptblock{$services | where-object{$_.Name -eq 'SSHTectiaServer'} | start-service -pass} | format-table -property PSComputerName, Name, Status  | out-string
		}
		elseif ($Service -eq "iis")
		{
			invoke-command -session $Remote -scriptblock{$services =  Get-service}
			invoke-command -session $Remote -Scriptblock{$services | where-object{$_.Name -eq 'W3SVC'} | start-service -pass} | format-table -property PSComputerName, Name, Status | out-string
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

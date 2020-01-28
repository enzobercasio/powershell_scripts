#########################################################################################################
#   Script: INSERT_WINDASHBOARD.PS1
#   Version: 1.0
#   Created: enzobercasio
#   Description: Insert Windows System resources from flatfile.
##########################################################################################################


#SET VARIABLES

#SMTP Details
$users = "contact@enzobercasio.com"# List of users to email your report to (separate by comma)
$fromemail = "server@enzobercasio.com"
$server = "xx.xx.xx.xx" #enter your own SMTP server DNS name / IP address here


#server list per environment
$serverlistpath= 'D:\Scripts\npdashboard'
$fplist = "$serverlistpath\FILEPOLL.txt"

#Logs
$logdir = "F:\windashboard"

$logfilename = "$logdir\windashboard_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".log"
$transcriptname = "$logdir\windashboardtranscript_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".txt"



start-transcript -path $transcriptname -noclobber
"Starting windashboard on " + (Get-Date) + "." >> $logfilename
# Siebel Environments
$env = @("Production","Testing")

	#SET ASSEMBLY
	[reflection.assembly]::loadwithpartialname('System.Data.OracleClient')
	#OPEN ORACLE DB CONNECTION
	$conn = New-Object System.Data.OracleClient.OracleConnection
	$conn.ConnectionString = "Data Source=Database;uid=userid;pwd=password;"
	$conn.open()

	$cmd = New-Object System.Data.OracleClient.OracleCommand
	$cmd.connection = $conn


try {

foreach ($list in $env)
{

	#START OF INSERT TO  - CPU
	foreach ($ds in get-content "$serverlistpath\$list.txt")
	{
		$d = Get-Date
		write-host "$d : cpu of $ds"
		$sys = Get-WmiObject -ComputerName $ds Win32_ComputerSystem
		$os= Get-WmiObject -ComputerName $ds Win32_OperatingSystem

		$proc =get-counter -computername $ds -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1
		#$cpu=($proc.readings -split ("`r`n"))[-1]
		$cpu=($proc.readings -split (":`n"))[-1]
		$cpu

		foreach ($drive in $sys) {
		$cmd.commandtext = "INSERT INTO WIN_CPU_USAGE (environment, servername, cpu_usage) VALUES('{0}','{1}','{2}')" -f $list, $drive.__SERVER, $cpu
		$cmd.executenonquery()
		}
	}
	#END OF INSERT TO  - CPU

	#START OF INSERT TO - SERVICE
	foreach ($ds in get-content "$serverlistpath\$list.txt")
	{
		$d = Get-Date
		write-host "$d : service of $ds"
		$ser = Get-WmiObject -Class Win32_Service -ComputerName $ds | Where {($_.Name -like 'siebsrvr_*')}

		$cmd.commandtext = "INSERT INTO WIN_SERVICE (environment, servername, service, state) VALUES('{0}', '{1}','{2}','{3}')" -f $list, $ser.__SERVER,$ser.name,$ser.state
		$cmd.executenonquery()
	}
	#END OF INSERT TO - SERVICE

	#START OF INSERT TO  - DISKSPACE
	foreach ($ds in get-content "$serverlistpath\$list.txt")
	{
		$d = Get-Date
		write-host "$d : disk space of $ds"
		$disk = Get-WmiObject -ComputerName $ds Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3}

		foreach ($drive in $disk) {
		$cmd.commandtext = "INSERT INTO WIN_DISKSPACE (environment, servername, name, disksize, freespace) VALUES('{0}','{1}', '{2}', '{3}', '{4}')" -f $list, $drive.__SERVER, $drive.name, $drive.size, $drive.freespace
		$cmd.executenonquery()
		}
	}
	#END OF INSERT TO  - DISKSPACE

	#START OF INSERT TO - MEMORY
	foreach ($ds in get-content "$serverlistpath\$list.txt")
	{
		$d = Get-Date
		write-host "$d : memory of $ds"
		$mem = Get-Process -ComputerName $ds | Sort WS -Descending #| Select-Object -First 10
		foreach ($memory in $mem) {
		$cmd.commandtext = "INSERT INTO WIN_MEMORY_USAGE(environment, servername, processname, pid, ws_memory) VALUES('{0}','{1}', '{2}', '{3}', '{4}')" -f $list, $ds, $memory.processname, $memory.ID, $memory.WS
		$cmd.executenonquery()
		}
	}
	#END OF INSERT TO  - MEMORY
	#START OF INSERT TO - MEMORY
	#foreach ($ds in get-content "$serverlistpath\$list.txt")
	#{
	#	$d = Get-Date
	#	write-host "$d : memoryall of $ds"
	#	$memall = gwmi -Class win32_operatingsystem -computername $ds | Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}
	#	$memall.MemoryUsage

	#	$cmd.commandtext = "INSERT INTO WIN_MEMORYALL_USAGE(environment, servername, memory) VALUES('{0}','{1}', '{2}')" -f $list, $ds, $memall.MemoryUsage
	#	$cmd.executenonquery()

	#}

}

foreach($item in (get-content $fplist))
{	$val = $item.split(";")
	$server = $val[1]
	$env = $val[0]

	#INSERT FOR  POLLER SERVICE
	$fp = Get-WmiObject -Class Win32_Service -ComputerName $server | Where {($_.Name -like '*Poller*')}

	foreach ($PollerService in $fp) {
	$cmd.commandtext = "INSERT INTO WIN_SERVICE (environment, servername, service, state) VALUES('{0}', '{1}','{2}','{3}')" -f $env, $PollerService.__SERVER,$PollerService.name,$PollerService.state
	$cmd.executenonquery()
	}

	#INSERT FOR  POLLER SERVICE
}

}
catch
{

	$ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    send-mailmessage -from $fromemail -to $users -subject "ALERT: Non-Prod Server Connection Failed" -priority High -smtpServer $server -Body "Non-Prod Server Connectivity Failure. The error message was ' $ErrorMessage ' on $list environment for server $ds"

	Break
}

	#CLOSE DB CONNECTION
	$conn.close()

	"Ending windashboard on " + (Get-Date) + "." >> $logfilename
	stop-transcript

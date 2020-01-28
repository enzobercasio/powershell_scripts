#########################################################################################################
#   Script: KILLSESSIONS.PS1
#   Version: 1.0
#   Created: LSBERCASIO
#   Description: Kills Siebel Sessions from User List text file.
##########################################################################################################

[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory=$True,Position=1)]
		[String]$user,
		[Parameter(Mandatory=$True,Position=2)]
		[String]$password
	)

#SET VARIABLES

#SMTP Details
$users = "contact@enzobercasio.com" # List of users to email your report to (separate by comma)
$fromemail = "server@enzobercasio.com"
$server = "xx.xx.xx.xx" #enter your own SMTP server DNS name / IP address here

#server list per environment
$serverlistpath= 'D:\killsessions'
#Logs
$logdir = "D:\killsessions"
$logfilename = "$logdir\killsessions_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".log"
$transcriptname = "$logdir\killsessionstranscript_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".txt"

start-transcript -path $transcriptname -noclobber

"Generating list session commands " + (Get-Date) + "." >> $logfilename

"set header false" | out-file -filepath D:\killsessions\listtasklogin.txt
"set footer false" | out-file -filepath D:\killsessions\listtasklogin.txt -Append
"spool D:\killsessions\listtaskloginoutput.txt" | out-file -filepath D:\killsessions\listtasklogin.txt -Append

	foreach ($ds in get-content "$serverlistpath\idlist.txt")
	{

		$c1 = "list active session for login "
		$c2 = " show TK_TASKID"
		$line = $c1 + $ds + $c2
		write-host $line
		$line | out-file -filepath D:\killsessions\listtasklogin.txt -Append
	}
"spool off" | out-file -filepath D:\killsessions\listtasklogin.txt -Append
"exit" | out-file -filepath D:\killsessions\listtasklogin.txt -Append

"Generated list session commands " + (Get-Date) + "." >> $logfilename


$gw = "gtwserver"
#$user = "useradmin"
#$password = "adminpassword"
$enterprise = "SIEBEL_ENT"

"Querying task ids to kill " + (Get-Date) + "." >> $logfilename
E:\Siebel\ses\siebsrvr\BIN\srvrmgr.exe /g $gw /e $enterprise /u $user /p $password /i D:\killsessions\listtasklogin.txt /o D:\killsessions\listtasklogintranscript.txt


@(Get-Content D:\killsessions\listtaskloginoutput.txt ) -replace '\D+','' | ? {$_.trim() -ne "" }  | Out-File D:\killsessions\listtaskid.txt

"Generating kill session commands " + (Get-Date) + "." >> $logfilename

"set header false" | out-file -filepath D:\killsessions\killtask.txt
"set footer false" | out-file -filepath D:\killsessions\killtask.txt -Append
"spool D:\killsessions\killtaskoutput.txt" | out-file -filepath D:\killsessions\killtask.txt -Append

	foreach ($ds in get-content "D:\killsessions\listtaskid.txt")
	{

		$c1 = "stop task "
		$c2 = " for server GUI_%"
		$line = $c1 + $ds + $c2
		write-host $line
		$line | out-file -filepath D:\killsessions\killtask.txt -Append
	}
"spool off" | out-file -filepath D:\killsessions\killtask.txt -Append
"exit" | out-file -filepath D:\killsessions\killtask.txt -Append

"Generated kill session commands " + (Get-Date) + "." >> $logfilename

"Terminating open sessions for the users " + (Get-Date) + "." >> $logfilename
E:\Siebel\ses\siebsrvr\BIN\srvrmgr.exe /g $gw /e $enterprise /u $user /p $password /i D:\killsessions\killtask.txt /o D:\killsessions\listtasklogintranscript.txt


stop-transcript

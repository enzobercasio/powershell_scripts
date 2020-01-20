##########################################################################################################
#   Script: LogParser Check
#   Version: 1.0
#   Created: LSBERCASIO
#   Description: Probes  Logs for error. Reads logs from directory and searches for a string pattern. 
# 		Sends an email when the pattern is found. 
# 		Additional script is also added to archive old logs to a separate directory.
##########################################################################################################

#SMTP Details 
$users = "contact@enzobercasio.com" # List of users to email your report to (separate by comma)
$fromemail = "alert@enzobercasio.com"
$server = "xx.xx.xx.xx" #enter your own SMTP server DNS name / IP address here

#Set execution policy for CurrentUser
Set-ExecutionPolicy RemoteSigned -scope CurrentUser

#Set Variables
#Edit per server implementation
#------------------------------------------------------------------------------------------------------------------
$Date=Get-Date
$ServerHost="server01"
$LogToSearch="\\$ServerHost\g$\log\application*.log"
$FileName= "$ServerHost{0}{1:d2}{2:d2}-{3:d2}{4:d2}" -f $date.year,$date.month,$date.day,$date.hour,$date.minute
$OutputFile="G:\LogParser\$FileName.txt"
$StringTosearch="unable to connect to server"
$HTMLOutFile="G:\LogParser\$ServerHost.html"
$LogArchive= "$ServerHost{0}{1:d2}{2:d2}-{3:d2}" -f $date.year,$date.month,$date.day,$date.hour
#------------------------------------------------------------------------------------------------------------------

#Probing Logs for stringtosearch (returns TRUE if found something)
$WithError=get-content $LogToSearch | select-string "$StringToSearch" -quiet

#Probing SRBroker Logs for stringtosearch and output to file.
get-content $LogToSearch | select-string "$StringToSearch" | out-file $Outputfile

#Clean up blank lines from Output File
(get-content $OutputFile) | where {$_ -ne ""} | out-file $OutputFile

$A = (get-content $OutputFile | measure-object)
$ServerCnt = $A.count


#Assemble the HTML for our body of the email report.
$HTMLmessage = @"
<font color=""black"" face=""Arial, Verdana"" size=""3"">
<u><b>Unable to Connect to Server error: $ServerHost</b></u>
<BR>&nbsp;<BR>
Unable to connect to server error found. Please check component.
<BR>&nbsp;<BR>
<style type=""text/css"">body{font: .8em ""Lucida Grande"", Tahoma, Arial, Helvetica, sans-serif;}
ol{margin:0;padding: 0 1.5em;}
table{;border-collapse:collapse;width:1000px;border:5px solid #900;}
thead{}
thead th{padding:1em 1em .5em;border-bottom:1px dotted #FFF;font-size:120%;text-align:left;}
thead tr{}
td{padding:.5em 1em;}
tfoot{}
tfoot td{padding-bottom:1.5em;}
tfoot tr{}
#middle{background-color:#900;}
</style>
<body BGCOLOR=""black"">

</body>
"@ 

$HTMLmessage | out-file $HTMLOutFile
#Send email alert if any one of the Logs have the error
if($ServerCnt -ge 1) 
{
    send-mailmessage -from $fromemail -to $users -subject "ALERT: Unable to connect to server error Error in $ServerHost" -attachments $OutputFile -BodyAsHTML -body $HTMLmessage  -priority High -smtpServer $server                  
}

 
#Archive Log files updated older than 1 hour to another folder
#-------------------------------------------------------------
$Source = "\\$ServerHost\g$\archive\log"
$Destination = "\\$ServerHost\g$\archive\log\$LogArchive"

$Past = (Get-Date).AddDays(-1/24)
$List = dir $Source | Where {$_.LastWriteTime -lt $Past -and $_.extension -eq ".log"}

new-item -path $Destination -type directory -ea SilentlyContinue

foreach($file in $list){
move-item -Path $file.FullName -destination $Destination 
}
#-------------------------------------------------------------



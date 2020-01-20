##########################################################################
#Script: ADUserReset.ps1
#Description: Powershell script to reset existing AD user's password. Flatfile Input is User Id and email address, delimited by semi-colon. 
#             To run .\ADUserReset.ps1 <flatfile> <Directory>
#             The program will auto-generate the password and reset the ad user in domain.
#             Upon successful reset, the user will be notified via email with the user id and the password created. 
#Created By: LSBERCASIO
#Version 1.0
###########################################################################
param($list, $env)

#Log files
$logfilename = "D:\Scripts_Working_Area\AdUserCreate\Logs\aduserreset_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".txt"
#Transcript
$transcriptname = "D:\Scripts_Working_Area\AdUserCreate\Logs\adresettranscript_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".txt"
$genericpasswd = "Starhub_123"

"Starting transcript..."
start-transcript -path $transcriptname -noclobber

#Set execution policy for CurrentUser
#Set-ExecutionPolicy RemoteSigned -scope CurrentUser

#SMTP Details 
$fromemail = "donotreply@starhub.com"
#$bccmail = "lorenzosanchez.bercasio@starhub.com"
$bccmail = "lorenzosanchez.bercasio@starhub.com", "jayar.e.gementiza@starhub.com"
$server = "10.90.65.187" #enter your own SMTP server DNS name / IP address here

#shout out the parameter values provided.
"Environment is " + $env
"Input File is " + $list 

"Adding QUEST AD Management to this session..."
add-pssnapin quest.activeroles.admanagement

#Test if input file exists
$fileexists = Test-Path $list 

"Input File exists? : " + $fileexists

if ($fileexists -eq $False)
{ 
    "Warning: Input file does not exist. Make sure you provide the correct path and file."
    stop-transcript
    exit
}
elseif ($fileexists -eq $True)
{
    #File exist so continue creation
if($env -eq "PRODUCTION")
{ 
    $ADBaseDN = "OU=PPR,OU=Users,OU=Organization,DC=Domain,DC=PROD"
}
elseif($env -eq "TEST")
{
    $ADBaseDN = "OU=TEST,OU=Users,OU=Organization,DC=Domain,DC=TEST"
}
else
{
    "Warning: Environment selection are PRODUCTION and TEST only. Please re-run using the correct input value."
    stop-transcript
    exit
}
#Parse input file 
foreach($item in (get-content $list))
{	
	$val = $item.split(";")
	$ADUser= $val[0]
	$ADeMail=$val[1]


"Starting AD user reset on " + (Get-Date) + " on " + $ADBaseDN + " for " + $ADUser + "." 
	
"Checking if Account exists..."
$testuserexist = Get-QADUser -searchroot $ADBaseDN -samaccountname $ADUser
	if ($testuserexist)
	{
					   
			#Start of auto password generation
			"Auto generating password for " + $ADUser + "."			
			$ADPassword = $NULL
			$Newpassword1=$NULL 
			$Newpassword2=$NULL

			FOREACH ($Counter in 1..4) 
			{ 
				$Newpassword1=$Newpassword1+([CHAR]((GET-RANDOM 26)+65)) 
			}

			FOREACH ($Counter in 1..100) 
			{ 
				$Newpassword2=$Newpassword2+(GET-RANDOM 4) 
			}
			if($env -eq "TEST")
			{ 
				$ADPassword = $genericpasswd
			}
			else
			{
				$ADPassword = $Newpassword1 + "a_!" + $Newpassword2
			}
				"Password generated is " + $ADPassword + "."
			#End of auto password generation

    "The Account exists " + $samaccountname
	 Get-QADUser -searchroot $ADBaseDN -name $ADUser | Set-QADUser -UserPassword $ADPassword
	#Get-QADUser $look
	"User Reset:" + $ADUser + ";" + $ADPassword + ";" +  $ADBaseDN  >> $logfilename

#Assemble the HTML for our body of the email report.
$HTMLmessage = @"
<font color=""black"" face=""Arial, Verdana"" size=""3"">
<u><b>AD User Password Reset for $ADUSer</b></u>
<BR>&nbsp;<BR>
Your AD User account has been reset.
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
<table border="1">
  <tr>
    <th>User Id</th>
    <th>New Password</th>
	</tr>
  <tr>
    <td>$ADUser</td>
    <td>$ADPassword</td>
  </tr>
</table>
</body>
"@ 

  "Sending new credentials to user..."
  send-mailmessage -from $fromemail -to $ADemail -bcc $bccmail -subject "AD User Password Reset for $ADUser" -BodyAsHTML -body $HTMLmessage  -priority Low -smtpServer $server

    }
	Else
	{
		"Warning: the Account does not exist " + $samaccountname
	}

}
}
#Stop transcript 
stop-transcript
 
#end of script: lsbercasio




#########################################################################################################
#   Script: ERROR LOG FAILEDLOGIN
#   Version: 1.0
#   Created: LSBERCASIO
#   Description: Checks on error on ERROR_LOG table using oracle client assembly to connect to the Oracle DB.
##########################################################################################################

	#Set up Mail configs

	$users = "contact@enzobercasio.com"
	$fromemail = "server@enzobercasio.com"
	$server = "xx.xx.xx.xx" #enter your own SMTP server DNS name / IP address here

	#Logs
	$logdir = "F:\LoginFailedCheck"
	$logfilename = "$logdir\LoginFailedCheck_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".log"
	$transcriptname = "$logdir\LoginFailedCheck_transcript_" + (get-date).tostring("yyyy_MM_dd_HHmm") + ".txt"
	$errorlist =  "$logdir\errordetail.txt"
	$datetime = Get-Date -format "ddMMyyyy HHmmss"
	start-transcript -path $transcriptname -noclobber

	"---------------------------cx_err_log ERROR CHECK START---------------------------" >> $logfilename
	### try to load assembly, fail otherwise ###
	$Assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient")

	if ( $Assembly ) {
		Write-Host "System.Data.OracleClient Loaded!"
		"System.Data.OracleClient Loaded!" >> $logfilename
	}
	else {
		Write-Host "System.Data.OracleClient could not be loaded! Exiting..."
		"System.Data.OracleClient could not be loaded! Exiting..." >> $logfilename
		Exit 1
	}

	# connect to Production database
	$OracleConnectionString  = "Data Source=Database;uid=user;pwd=password"
  $OracleConnection = New-Object System.Data.OracleClient.OracleConnection($OracleConnectionString );

	write-host "Connecting to database..."
	"Connecting to database..." >>$logfilename
	$OracleConnection.Open()

	try {

	write-host "Successfully connected to database."
	"Successfully connected to database." >> $logfilename
    ### sql query command ###
	$OracleSQLQuery = "select count(*) from err_log where err_msg LIKE '%Login failed attempting to connect to%' and created > sysdate - 5/1440"
	echo $OracleSQLQuery >> $logfilename

    ### create object ###
    $SelectCommand = New-Object System.Data.OracleClient.OracleCommand;
    $SelectCommand.Connection = $OracleConnection
    $SelectCommand.CommandText = $OracleSQLQuery
    $SelectCommand.CommandType = [System.Data.CommandType]::Text

	write-host "Querying Error in err_log..."
	"Querying Error in err_log..." >> $logfilename
	$Reader = $SelectCommand.ExecuteReader()
	# get the count of error on cx_err_log
	while ($Reader.Read()) {
         $errcount = $Reader.GetValue($1)
    }
	write-host "Error Count: " $errcount
	"Error Count: $errcount"  >> $logfilename
	}
		catch {

			Write-Host "Error while retrieving data!"
			"Error while retrieving data!" >> $logfilename
		}

	write-host "Closing database connection...."
	"Closing database connection...." >> $logfilename
	# close database connection
    $OracleConnection.Close()


	if ($errcount -gt 0)
	{
		write-host "ERROR on err_log"
		"ERROR on err_log" >> $logfilename

		write-host "Connecting to production database..."
		"Connecting to production database..." >>$logfilename
		$OracleConnection.Open()

			### create object ###
			$SelectCommand = New-Object System.Data.OracleClient.OracleCommand;
			$SelectCommand.Connection = $OracleConnection
			#$SelectCommand.CommandText = $OracleSQLQueryDetail
			$SelectCommand.CommandType = [System.Data.CommandType]::Text
			$Reader = $SelectCommand.ExecuteReader()

			write-host "Querying Detail Error in err_log..."
			"Querying Detail Error in err_log..." >> $logfilename
			# Write out the result set structure
			for ($i=0;$i -lt $Reader.FieldCount;$i++) {
				Write-Host  $Reader.GetName($i) $Reader.GetDataTypeName($i)
			}


		write-host "Closing database connection...."
		"Closing database connection...." >> $logfilename
		$OracleConnection.Close()

#Assemble the HTML for our body of the email report.
$HTMLmessage1 = @"
<font color=""black"" face=""Arial, Verdana"" size=""3"">
<u><b>ALERT! $errcount Errors on err_log</b></u>
<BR>&nbsp;<BR>
There are $errcount Login Failed errors in err_log table.
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

				write-host "Sending email to team..."
				"Sending email to team..."	>> $logfilename
				send-mailmessage -from $fromemail -to $users -subject "ALERT: Login Failed Error on err_log $Date : $errcount" -BodyAsHTML -body $HTMLmessage1 -attachments $errorlist -priority High -smtpServer $server
				write-host "err_log Failed Check Completed."
				"err_log Failed Check Completed."	>> $logfilename
	}
		else
		{
				write-host "No error found. Doing nothing..."
				"No error found. Doing nothing..." >> $logfilename
				write-host "err_log Failed Check Completed."
				"err_log Failed Check Completed." >> $logfilename
		}


	"---------------------------err_log ERROR CHECK END---------------------------" >> $logfilename

	stop-transcript
	###END OF PROGRAM

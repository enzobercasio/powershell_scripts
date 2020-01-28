#########################################################################################################
#   Script:  APACHE LOG ARCHIVE COPY
#   Version: 1.0
#   Created: enzobercasio
#   Description: Apache log archive copy to backup server
#########################################################################################################
#
## Get Today's Date
$today = Get-Date -Format yyyyMMdd

#Start Transcript

Start-transcript D:\ApacheArchive\ApacheLogCopy_$today.log

## Set servers
$Servers = "server1", "server2"

write-host " APACHE LOG COPY"

## Set time frame
$datetoday = (Get-Date).AddHours(-6)
write-host "Today is $datetoday"
#$date = (Get-Date).AddDays(-1)
$date = $datetoday.AddDays(-1)
write-host "Yesterday is $date"

write-host "Deleting all log files in Log_Copy folder in Backup Server"
remove-item -path \\backupserver\g$\ApacheArchive\apache_web\access*.*
write-host "Completed deleting all log files in Log_Copy folder in Backup Server"


foreach ($server in $servers){
    ## Get list of files to copy
    $source = "\\$server\g$\APACHE_WEB\archive\"
    write-host "Log copy from Server $Server Started."
    ## Set Destination Folder
    $destination = "\\backupserver\g$\ApacheArchive\apache_web\"
    write-host "From $source to $destination."


    $files = Get-ChildItem $source | Where-Object {$_.LastWriteTime -gt $date -and $_.LastWriteTime -le $datetoday -and $_.Name -like "access*"}


    ## Move and Rename the files
    foreach ($file in $files){
    Copy-Item $source$file $destination
    write-host "Copying $file to Archive folder..."
    #$y = ($file.name).split(".")
    #$new_file_name = $y[0]+"."+$y[1]+"_"+$server+"."+$y[2]
    #write-host "Renaming $file in Archive folder..."
    #Rename-Item $destination$file $destination$new_file_name
    #write-host "$file renamed to $new_file_name"
    }

    write-host "Log copy from Server $server Completed."

}

Stop-transcript

###############################################End of Script##########################################

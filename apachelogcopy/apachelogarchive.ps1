#########################################################################################################
#   Script:  APACHE LOG ARCHIVE
#   Version: 1.0
#   Created: enzobercasio
#   Description: Apache log archiving in windows
#########################################################################################################
#
## Get Today's Date
$today = Get-Date -Format yyyyMMdd

#Start Transcript

Start-transcript D:\ApacheArchive\ApacheArchive_$today.log

## Set servers
$Servers = "server1", "server2"

write-host " APACHE LOG ARCHIVE"

## Set time frame
$datetoday = (Get-Date).AddHours(-6)
write-host "Today is $datetoday"
#$date = (Get-Date).AddDays(-1)
$date = $datetoday.AddDays(-1)
write-host "Yesterday is $date"


foreach ($server in $servers){
    ## Get list of files to Move
    $source = "\\$server\g$\APACHE_WEB\logs\"
    write-host "Back up from Server $Server Started."
    ## Set Destination Folder
    $destination = "\\$server\g$\APACHE_WEB\archive\"
    write-host "From $source to $destination."

    $files = Get-ChildItem $source | Where-Object {$_.LastWriteTime -gt $date -and $_.LastWriteTime -le $datetoday -and $_.Name -like "access*"}


    ## Move and Rename the files
    foreach ($file in $files){
    Copy-Item $source$file $destination
    write-host "Copying $file to Archive folder..."
    $y = ($file.name).split(".")
    $new_file_name = $y[0]+"."+$y[1]+"_"+$server+"."+$y[2]
    write-host "Renaming $file in Archive folder..."
    Rename-Item $destination$file $destination$new_file_name
    write-host "$file renamed to $new_file_name"
    }

    write-host "Back up from Server $server Completed."

    write-host "Start deleting apache archived logs older than 7 days."
    Get-ChildItem $destination | Where-Object {$_.LastWriteTime -le $date.AddDays(-6) -and $_.Name -like "access*"} | remove-item
    write-host "Completed deleting apache archived logs older than 7 days."
}

Stop-transcript

###############################################End of Script##########################################

#########################################################################################################
#   Script: recurse-replace.ps1	
#   Version: 1.0
#   Created: LSBERCASIO
#   Description: Recursively go through files inside a directory and replace the strings based on criteria 
##########################################################################################################

$exclude = @( "*.exe*") # exclude files extensions
$files = Get-ChildItem -Path "G:\test_dir" -Recurse -exclude $exclude # change -Path with your directory path 

foreach ($file in $files){
	$find = "my_old_name" # the string to find
	$replace = "my_new_name" # the string to replace
	$content = Get-Content $($file.FullName) -Raw
	$content -replace $find,$replace | Out-File $($file.FullName) 
}



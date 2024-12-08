# Define the output file path
$outputFilePath = "$env:USERPROFILE\Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"

# Create the folder if it doesn't exist
$folderPath = Split-Path $outputFilePath
if (!(Test-Path -Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath | Out-Null
}

while ($True) {
    # Send the F15 keypress
    $wshell = New-Object -ComObject wscript.shell
    $wshell.sendkeys("{F15}")
    
    # Get the current timestamp in day-month-year and 24-hour format
    $timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    
    # Construct the log entry
    $logEntry = "Key press F15 @ $timestamp"
    
    # Append the log entry to the file
    Add-Content -Path $outputFilePath -Value $logEntry

    # Wait for 870 seconds before repeating
    Start-Sleep -Seconds 870
}
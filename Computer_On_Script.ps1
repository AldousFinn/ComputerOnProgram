# Define paths
$outputFilePath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath = Split-Path $outputFilePath
$scriptPath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"
$githubRawUrl = "https://raw.githubusercontent.com/AldousFinn/ComputerOnScript/main/Computer_On_Script.ps1"

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Output "Checking for updates..."
        
        # Fetch remote script content
        $remoteScriptContent = (Invoke-WebRequest -Uri $githubRawUrl -UseBasicParsing -ErrorAction Stop).Content
        
        # Read local script content
        $localScriptContent = Get-Content -Path $scriptPath -Raw -ErrorAction Stop

        # Normalize content for comparison
        $normalizedRemote = ($remoteScriptContent.Trim() -replace '\s+', '')
        $normalizedLocal = ($localScriptContent.Trim() -replace '\s+', '')

        if ($normalizedRemote -ne $normalizedLocal) {
            Write-Output "Update required!"
            
            # Save the new script content
            $tempScriptPath = "$scriptPath.tmp"
            $remoteScriptContent | Set-Content -Path $tempScriptPath -Force
            Write-Output "Temporary updated script saved. Restarting for update..."
            
            # Restart the script using the updated version
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$tempScriptPath`"" -NoNewWindow
            Write-Output "New PowerShell process started. Waiting to exit current process..."
            Start-Sleep -Seconds 2
            Exit
        } else {
            Write-Output "No updates found. Running the current version."
        }
    } catch {
        Write-Output "Failed to check for updates: $_"
    }
}

# Function: Main functionality of the script
Function Main {
    # Create the folder if it doesn't exist
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

        # Wait for 870 seconds before repeating the code.
        # Huxley was here.
        Start-Sleep -Seconds 870
    }
}

# Run update check and then the main function
Check-ForUpdates
Main

# Define paths
$outputFilePath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath = Split-Path $outputFilePath
$scriptPath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"
$tempScriptPath = "$scriptPath.temp"
$githubRawUrl = "https://raw.githubusercontent.com/AldousFinn/ComputerOnScript/main/Computer_On_Script.ps1"

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        # Download the latest script from GitHub
        $latestScript = Invoke-WebRequest -Uri $githubRawUrl -UseBasicParsing -ErrorAction Stop
        
        # Read the current script's content
        $currentScript = Get-Content -Path $scriptPath -Raw

        # Compare scripts; if different, update
        if ($latestScript.Content -ne $currentScript) {
            Write-Output "Update found. Preparing to update the script..."
            
            # Save the new script to a temporary file
            $latestScript.Content | Set-Content -Path $tempScriptPath -Force
            Write-Output "Temporary updated script saved. Restarting for update..."

            # Move the new script over the old one
            Move-Item -Force "$tempScriptPath" "$scriptPath"

            # Start the updated script in a new PowerShell session
            $newProcess = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -PassThru -NoNewWindow

            # Wait for the new process to be fully started (add sleep for reliability)
            Start-Sleep -Seconds 3

            # Exit the current session after restarting
            Write-Output "Exiting current session after restarting the script..."
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
        #Huxley wuz here again!
        Start-Sleep -Seconds 870
    }
}

# Run update check and then the main function
Check-ForUpdates
Main

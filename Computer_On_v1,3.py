import os
import win32com.client

# Paths for your script and log files
powershell_script_path = r"C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"
log_file_folder = r"C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Log_Files"
startup_folder = os.path.expandvars(r"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup")
shortcut_name = "Computer_On_Script.lnk"

# PowerShell script content
powershell_script_content = r"""
# Define paths
$outputFilePath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath = Split-Path $outputFilePath
$scriptPath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"
$githubRawUrl = "https://raw.githubusercontent.com/AldousFinn/ComputerOnScript/main/Computer_On_Script.ps1"

# Function: Write log with timestamp
Function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    $logMessage = "[$timestamp] $Message"
    Write-Output $logMessage
    Add-Content -Path $outputFilePath -Value $logMessage
}

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Log "Checking for updates..."
        
        # Download the latest script from GitHub with TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $latestScript = (Invoke-WebRequest -Uri $githubRawUrl -UseBasicParsing -ErrorAction Stop).Content
        
        # Read the current script's content and normalize line endings
        $currentScript = (Get-Content -Path $scriptPath -Raw).Replace("`r`n", "`n")
        $latestScript = $latestScript.Replace("`r`n", "`n")
        
        # Compare scripts; if different, update
        if ($latestScript -ne $currentScript) {
            Write-Log "Update found! Initiating update process..."
            Update-Script -NewContent $latestScript
        } else {
            Write-Log "No updates found. Running the current version."
        }
    } catch {
        Write-Log "Failed to check for updates: $($_.Exception.Message)"
    }
}

# Function to download the latest script and restart
Function Update-Script {
    param([string]$NewContent)
    
    try {
        $tempScriptPath = "$scriptPath.tmp"
        $backupScriptPath = "$scriptPath.backup"
        
        # Create backup of current script
        Copy-Item -Path $scriptPath -Destination $backupScriptPath -Force
        Write-Log "Created backup at: $backupScriptPath"
        
        # Save the new script content
        $NewContent | Set-Content -Path $tempScriptPath -Force
        Write-Log "Saved new script content to temporary file"
        
        # Verify the temporary file exists and has content
        if (!(Test-Path -Path $tempScriptPath) -or !(Get-Content -Path $tempScriptPath)) {
            throw "Temporary script file is missing or empty"
        }
        
        # Replace the original script
        Move-Item -Path $tempScriptPath -Destination $scriptPath -Force
        Write-Log "Successfully updated script file"
        
        # Start a new PowerShell process with the updated script
        Write-Log "Restarting script with updated version..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -NoNewWindow
        
        # Exit the current session
        Exit
    } catch {
        Write-Log "Failed to update script: $($_.Exception.Message)"
        if (Test-Path -Path $backupScriptPath) {
            Write-Log "Restoring from backup..."
            Move-Item -Path $backupScriptPath -Destination $scriptPath -Force
        }
    }
}

# Function: Main functionality of the script
Function Main {
    try {
        # Create the folder if it doesn't exist
        if (!(Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
            Write-Log "Created output directory: $folderPath"
        }
        
        Write-Log "Starting main loop..."
        while ($True) {
            # Send the F15 keypress
            $wshell = New-Object -ComObject wscript.shell
            $wshell.sendkeys("{F15}")
            
            # Log the keypress
            Write-Log "Key press F15 sent"
            
            # Check for updates every 10 cycles (approximately every 2.5 hours)
            if ($counter % 10 -eq 0) {
                Check-ForUpdates
            }
            $counter++
            
            # Wait for 870 seconds before repeating
            Start-Sleep -Seconds 870
        }
    } catch {
        Write-Log "Error in main loop: $($_.Exception.Message)"
        # Wait a bit before restarting to prevent rapid restart loops
        Start-Sleep -Seconds 30
        Main
    }
}

# Initialize counter
$counter = 0

# Create log file if it doesn't exist
if (!(Test-Path -Path $outputFilePath)) {
    New-Item -ItemType File -Path $outputFilePath -Force | Out-Null
}

# Run update check and then the main function
Write-Log "Script started"
Check-ForUpdates
Main
"""

def create_folders_and_files():
    """Create necessary folders and write the PowerShell script."""
    os.makedirs(log_file_folder, exist_ok=True)
    os.makedirs(os.path.dirname(powershell_script_path), exist_ok=True)
    
    # Write the PowerShell script
    with open(powershell_script_path, "w") as ps_file:
        ps_file.write(powershell_script_content.strip())

def create_shortcut():
    """Create a shortcut in the Startup folder."""
    shortcut_path = os.path.join(startup_folder, shortcut_name)
    
    shell = win32com.client.Dispatch("WScript.Shell")
    shortcut = shell.CreateShortcut(shortcut_path)
    shortcut.TargetPath = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    shortcut.Arguments = f'-WindowStyle Hidden -ExecutionPolicy Bypass -File "{powershell_script_path}"'
    shortcut.WorkingDirectory = os.path.dirname(powershell_script_path)
    shortcut.IconLocation = r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    shortcut.Save()

def main():
    print("Setting up the environment for your PowerShell script...")
    create_folders_and_files()
    create_shortcut()
    print("Setup complete. Your script is ready to run on startup.")

if __name__ == "__main__":
    main()

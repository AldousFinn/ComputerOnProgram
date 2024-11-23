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

# Function: Normalize content for comparison
Function Get-NormalizedContent {
    param([string]$Content)
    return $Content.Trim().Replace("`r`n", "`n").Replace("`r", "`n")
}

# Function: Verify key press was sent
Function Test-KeyPress {
    param (
        [System.Object]$wshell
    )
    
    try {
        # Get the initial idle time
        $initialIdleTime = [PowerShell]::Create().AddScript({
            Add-Type @'
            using System;
            using System.Runtime.InteropServices;
            public class LastInput {
                [DllImport("user32.dll")]
                static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
                
                public static uint GetLastInputTime() {
                    LASTINPUTINFO lastInp = new LASTINPUTINFO();
                    lastInp.cbSize = (uint)Marshal.SizeOf(lastInp);
                    if (!GetLastInputInfo(ref lastInp)) return 0;
                    return ((uint)Environment.TickCount - lastInp.dwTime);
                }
            }
            
            public struct LASTINPUTINFO {
                public uint cbSize;
                public uint dwTime;
            }
'@
            [LastInput]::GetLastInputTime()
        }).Invoke()[0]

        # Send the key press
        $wshell.SendKeys("{F15}")
        Start-Sleep -Milliseconds 100  # Small delay to ensure key press is registered

        # Get the new idle time
        $newIdleTime = [PowerShell]::Create().AddScript({
            [LastInput]::GetLastInputTime()
        }).Invoke()[0]

        # If the idle time was reset (new time is less than old time), the key press worked
        $keypressVerified = $newIdleTime -lt $initialIdleTime

        if ($keypressVerified) {
            Write-Log "Key press F15 verified - System idle time was reset"
            return $true
        } else {
            Write-Log "Warning: Key press F15 was sent but could not be verified"
            return $false
        }
    } catch {
        Write-Log "Error verifying key press: $($_.Exception.Message)"
        return $false
    }
}

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Log "Checking for updates..."
        
        # Download the latest script from GitHub with TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $latestScript = (Invoke-WebRequest -Uri $githubRawUrl -UseBasicParsing -ErrorAction Stop).Content
        
        # Read the current script's content
        $currentScript = Get-Content -Path $scriptPath -Raw
        
        # Normalize both contents for comparison
        $normalizedLatest = Get-NormalizedContent -Content $latestScript
        $normalizedCurrent = Get-NormalizedContent -Content $currentScript
        
        # Calculate hashes for comparison
        $latestHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalizedLatest))
        $currentHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalizedCurrent))
        
        # Compare hashes
        $needsUpdate = -not ([Convert]::ToBase64String($latestHash) -eq [Convert]::ToBase64String($currentHash))
        
        if ($needsUpdate) {
            # Double check if update is really needed by comparing lengths and first different character
            if (($normalizedLatest.Length -ne $normalizedCurrent.Length) -or 
                ($normalizedLatest -ne $normalizedCurrent)) {
                Write-Log "Update found! Initiating update process..."
                Update-Script -NewContent $latestScript
            } else {
                Write-Log "False positive detected. No update needed."
            }
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
        $NewContent | Out-File -FilePath $tempScriptPath -Encoding UTF8 -Force
        Write-Log "Saved new script content to temporary file"
        
        # Verify the temporary file exists and has content
        if (!(Test-Path -Path $tempScriptPath) -or !(Get-Content -Path $tempScriptPath)) {
            throw "Temporary script file is missing or empty"
        }
        
        # Verify content was written correctly
        $tempContent = Get-NormalizedContent -Content (Get-Content -Path $tempScriptPath -Raw)
        $expectedContent = Get-NormalizedContent -Content $NewContent
        
        if ($tempContent -ne $expectedContent) {
            throw "Content verification failed"
        }
        
        # Replace the original script
        Move-Item -Path $tempScriptPath -Destination $scriptPath -Force
        Write-Log "Successfully updated script file"
        
        # Verify the update one final time
        $finalContent = Get-NormalizedContent -Content (Get-Content -Path $scriptPath -Raw)
        if ($finalContent -ne $expectedContent) {
            throw "Final content verification failed"
        }
        
        # Start a new PowerShell process with the updated script
        Write-Log "Restarting script with updated version..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
        
        # Exit the current session after a short delay
        Start-Sleep -Seconds 2
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
        $wshell = New-Object -ComObject wscript.shell
        $failedAttempts = 0
        $counter = 0
        
        while ($True) {
            # Send and verify the key press
            $keypressSuccess = Test-KeyPress -wshell $wshell
            
            if (-not $keypressSuccess) {
                $failedAttempts++
                if ($failedAttempts -ge 3) {
                    Write-Log "Multiple key press verifications failed. Attempting to recreate wscript.shell object..."
                    $wshell = New-Object -ComObject wscript.shell
                    $failedAttempts = 0
                }
            } else {
                $failedAttempts = 0
            }
            
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

# Create log file if it doesn't exist
if (!(Test-Path -Path $outputFilePath)) {
    New-Item -ItemType File -Path $outputFilePath -Force | Out-Null
}

# Run update check and then the main function
Write-Log "Script started"
Check-ForUpdates
Main

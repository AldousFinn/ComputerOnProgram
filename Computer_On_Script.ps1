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
            # Also check if the screen is actually on
            $powerStatus = (Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorPowerStatus | 
                          Select-Object -First 1).PowerState
            if ($powerStatus -eq 0) {
                Write-Log "Display is active - System is being kept awake"
            } else {
                Write-Log "Warning: Display may be in power saving mode despite key press"
            }
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

# [Rest of your original script remains the same - Update functions, etc.]

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

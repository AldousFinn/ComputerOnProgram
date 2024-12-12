# Define paths using environment variables
$outputFilePath = Join-Path $env:USERPROFILE "Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath = Split-Path $outputFilePath
$scriptPath = Join-Path $env:USERPROFILE "Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"

# Function: Write log with timestamp
Function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $outputFilePath -Value $logMessage
}

# Function: Simulate mouse movement to keep the computer awake after idle detection
Function Simulate-MouseMovement {
    param ([int]$XOffset = 1, [int]$YOffset = 1)
    try {
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class MouseMover {
            [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
            public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint cButtons, uint dwExtraInfo);
            [DllImport("user32.dll")]
            public static extern bool GetCursorPos(out POINT lpPoint);
            [DllImport("user32.dll")]
            public static extern uint GetLastInputInfo(ref LASTINPUTINFO plii);

            public struct POINT {
                public int X;
                public int Y;
            }

            [StructLayout(LayoutKind.Sequential)]
            public struct LASTINPUTINFO {
                public uint cbSize;
                public uint dwTime;
            }

            public const uint MOUSEEVENTF_MOVE = 0x0001;

            public static void MoveMouse(uint dx, uint dy) {
                mouse_event(MOUSEEVENTF_MOVE, dx, dy, 0, 0);
            }

            public static uint GetIdleTime() {
                LASTINPUTINFO lastInputInfo = new LASTINPUTINFO();
                lastInputInfo.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lastInputInfo);
                return (uint)Environment.TickCount - lastInputInfo.dwTime;
            }

            public static POINT GetMousePosition() {
                POINT point;
                GetCursorPos(out point);
                return point;
            }
        }
"@ -ErrorAction Stop

        # Check idle time
        $idleTime = [MouseMover]::GetIdleTime() / 1000
        if ($idleTime -ge 600) {  # Only move mouse if idle for 10 minutes
            # Get current mouse position
            $currentPosition = [MouseMover+POINT]::new()
            $currentPosition = [MouseMover]::GetMousePosition()

            # Move the mouse by the offset, accounting for edge of screen
            $newX = [Math]::Max(0, $currentPosition.X + $XOffset)
            $newY = [Math]::Max(0, $currentPosition.Y + $YOffset)

            [MouseMover]::MoveMouse($newX - $currentPosition.X, $newY - $currentPosition.Y)
            Write-Log "Mouse moved from ($($currentPosition.X), $($currentPosition.Y)) to ($newX, $newY)."
        } else {
            Write-Log "Mouse movement skipped. System idle time: $idleTime seconds."
        }
    } catch {
        Write-Log "Mouse movement simulation failed: $($_.Exception.Message)"
    }
}

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Log "Checking for updates..."
        $repoApiUrl = "https://api.github.com/repos/AldousFinn/ComputerOnProgram/contents"
        # Placeholder logic for updates
        Write-Log "No updates available."
    } catch {
        Write-Log "Update check failed: $($_.Exception.Message)`nDetails: $($_.Exception.StackTrace)"
    }
}

# Function: Cleanup logs older than 4 hours
Function Cleanup-Logs {
    try {
        if (Test-Path -Path $outputFilePath) {
            $currentTime = Get-Date
            $fourHoursAgo = $currentTime.AddHours(-4)

            $logEntries = Get-Content -Path $outputFilePath

            $filteredEntries = $logEntries | Where-Object {
                if ($_ -match '^\[(\d{2}-\d{2}-\d{4}) (\d{2}:\d{2}:\d{2})\]') {
                    $entryDateString = $matches[1]
                    $entryTimeString = $matches[2]

                    $entryDateTime = [DateTime]::ParseExact(
                        "$entryDateString $entryTimeString", 
                        "dd-MM-yyyy HH:mm:ss", 
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )

                    return $entryDateTime -ge $fourHoursAgo
                }
                return $true
            }

            if ($filteredEntries) {
                $filteredEntries | Set-Content -Path $outputFilePath
                Write-Log "Log cleanup completed. Removed entries older than 4 hours."
            } else {
                Clear-Content -Path $outputFilePath
                Write-Log "All log entries were older than 4 hours. File cleared."
            }
        } else {
            Write-Log "Log file not found. Skipping cleanup."
        }
    } catch {
        Write-Log "Error during log cleanup: $($_.Exception.Message)"
    }
}

# Main function
Function Main {
    try {
        if (!(Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
        }
        $counter = 0
        Write-Log "Script started"
        while ($True) {
            Write-Log "Simulating mouse movement (iteration $counter)"
            Simulate-MouseMovement -XOffset 1 -YOffset 0
            if ($counter % 10 -eq 0) {
                Write-Log "Checking for updates (counter: $counter)"
                Check-ForUpdates
            }
            if ($counter % 5 -eq 0) {
                Write-Log "Running log cleanup (counter: $counter)"
                Cleanup-Logs
            }
            $counter++
            Start-Sleep -Seconds 870
        }
    } catch {
        Write-Log "Error in Main loop: $($_.Exception.Message)"
        Start-Sleep -Seconds 30
        Main
    }
}

# Create log file if needed
if (!(Test-Path -Path $outputFilePath)) {
    New-Item -ItemType File -Path $outputFilePath -Force | Out-Null
}

# Add a delay at startup
Write-Log "Waiting 1 minute before starting the main script..."
Start-Sleep -Seconds 60

# Start the script
Main

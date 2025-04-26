# Define base folder paths
$baseFolderPath = Join-Path $env:USERPROFILE "Documents\Computer_On_Folder"
$logFolderPath  = Join-Path $baseFolderPath "Computer_On_Log_Files"
$scriptFolderPath = Join-Path $baseFolderPath "Computer_On_Script"

# Define the paths for the log file and the script file
$logFilePath = Join-Path $logFolderPath "Computer_On_Log.txt"
$scriptFilePath = Join-Path $scriptFolderPath "Computer_On_Script.ps1"

# Ensure that the base folder and subfolders exist
if (-not (Test-Path $baseFolderPath)) {
    New-Item -ItemType Directory -Path $baseFolderPath | Out-Null
}
if (-not (Test-Path $logFolderPath)) {
    New-Item -ItemType Directory -Path $logFolderPath | Out-Null
}
if (-not (Test-Path $scriptFolderPath)) {
    New-Item -ItemType Directory -Path $scriptFolderPath | Out-Null
}

# Create the log file if it doesn't exist
if (-not (Test-Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath | Out-Null
}

# Create the full PowerShell script content as a string with single quotes
# to prevent variable expansion
$fullScriptContent = @'
# Define paths using environment variables
$outputFilePath = Join-Path $env:USERPROFILE "Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath     = Split-Path $outputFilePath
$scriptPath     = Join-Path $env:USERPROFILE "Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"

# Escape double quotes for VBS
$escapedScriptPath = $scriptPath.Replace('"', '""')

# Ensure VBScript launcher exists in Startup folder for silent launch
$startupFolder     = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$vbsLauncherPath   = Join-Path $startupFolder "Launch_Computer_On_Script.vbs"
$vbsScriptContent  = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$escapedScriptPath""", 0, False
"@

# Create or update the VBS launcher if needed
if (-not (Test-Path $vbsLauncherPath) -or (Get-Content $vbsLauncherPath -Raw) -ne $vbsScriptContent) {
    $vbsScriptContent | Out-File -FilePath $vbsLauncherPath -Encoding ASCII -Force
}

# Function: Write log with timestamp
Function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("dd-MM-yyyy HH:mm:ss")
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $outputFilePath -Value $logMessage
}

# Function: Test-KeyPress - Simulates a key press to keep system awake
Function Test-KeyPress {
    param([System.Object]$wshell)
    try {
        # Send F15 key which is usually not mapped to any function
        $wshell.SendKeys('{F15}')
        Write-Log "Key press simulation successful"
    } catch {
        Write-Log "Error during key press simulation: $($_.Exception.Message)"
    }
}

# Function: Normalize content for comparison
Function Get-NormalizedContent {
    param([string]$Content)
    return $Content.Trim() -replace "\r\n", "`n" -replace "\r", "`n"
}

# Function: Delete log entries older than 4 hours
Function Cleanup-Logs {
    try {
        if (Test-Path -Path $outputFilePath) {
            $currentTime = Get-Date
            $fourHoursAgo = $currentTime.AddHours(-4)

            # Read all existing log entries
            $logEntries = Get-Content -Path $outputFilePath

            # Filter and keep only entries within the 4-hour window
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

# Function: Get the latest versioned file from GitHub
Function Get-LatestVersionedFile {
    param([string]$RepoApiUrl, [string]$FilePrefix)
    try {
        Write-Log "Fetching the latest versioned file matching prefix '$FilePrefix' from GitHub..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $repoContent = Invoke-WebRequest -Uri $RepoApiUrl -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json

        $matchingFiles = $repoContent | Where-Object { $_.name -match "$FilePrefix`_v(\d+),(\d+),(\d+),(\d+)\.ps1" }
        $latestFile = $matchingFiles |
            Sort-Object -Property {
                if ($_.name -match "$FilePrefix`_v(\d+),(\d+),(\d+),(\d+)\.ps1") {
                    [int[]]@($matches[1], $matches[2], $matches[3], $matches[4])
                } else {
                    [int[]]@(0, 0, 0, 0)
                }
            } -Descending |
            Select-Object -First 1

        if ($latestFile) {
            $latestFileUrl = $latestFile.download_url
            Write-Log "Latest versioned file found: $($latestFile.name)"
            return $latestFileUrl
        } else {
            Write-Log "No matching files found for prefix '$FilePrefix'."
            return $null
        }
    } catch {
        Write-Log "Failed to fetch the latest versioned file: $($_.Exception.Message)"
        return $null
    }
}

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Log "Checking for updates..."
        $repoApiUrl = "https://api.github.com/repos/AldousFinn/ComputerOnProgram/contents"
        $latestScriptUrl = Get-LatestVersionedFile -RepoApiUrl $repoApiUrl -FilePrefix "Computer_On_Advanced"
        if (-not $latestScriptUrl) {
            Write-Log "No updates available."
            return
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $latestScript = (Invoke-WebRequest -Uri $latestScriptUrl -UseBasicParsing -ErrorAction Stop).Content
        $currentScript = Get-Content -Path $scriptPath -Raw -Encoding UTF8
        Write-Log "Fetched latest script and current script for comparison."
        $normalizedLatest = Get-NormalizedContent -Content $latestScript
        $normalizedCurrent = Get-NormalizedContent -Content $currentScript
        if ($normalizedLatest -ne $normalizedCurrent) {
            Write-Log "Update found - installing..."
            Update-Script -NewContent $latestScript
        } else {
            Write-Log "No updates found"
        }
    } catch {
        Write-Log "Update check failed: $($_.Exception.Message)`nDetails: $($_.Exception.StackTrace)"
    }
}

# Function: Update script
Function Update-Script {
    param([string]$NewContent)
    try {
        Write-Log "Creating backup and updating script."
        $tempScriptPath = "$scriptPath.tmp"
        $backupScriptPath = "$scriptPath.backup"
        Copy-Item -Path $scriptPath -Destination $backupScriptPath -Force
        $NewContent | Out-File -FilePath $tempScriptPath -Encoding UTF8 -Force
        if ((Test-Path -Path $tempScriptPath) -and (Get-Content -Path $tempScriptPath)) {
            Move-Item -Path $tempScriptPath -Destination $scriptPath -Force
            Write-Log "Update successful - restarting script."
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File ""$scriptPath""" -WindowStyle Hidden
            Start-Sleep -Seconds 2
            Exit
        }
    } catch {
        Write-Log "Update failed: $($_.Exception.Message)"
        if (Test-Path -Path $backupScriptPath) {
            Write-Log "Restoring backup..."
            Move-Item -Path $backupScriptPath -Destination $scriptPath -Force
        }
    }
}

# Main function
Function Main {
    try {
        if (!(Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
        }
        
        # Create a COM object for sending key presses
        $wshell = New-Object -ComObject wscript.shell
        $counter = 0
        
        Write-Log "Script started"
        
        while ($True) {
            Write-Log "Running key press test (iteration $counter)"
            Test-KeyPress -wshell $wshell
            
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

# Start the main function
Main
'@

# Write the PowerShell script to file
$fullScriptContent | Out-File -FilePath $scriptFilePath -Encoding UTF8 -Force

Write-Host "Script setup completed successfully!" -ForegroundColor Green
Write-Host "The script has been installed to: $scriptFilePath" -ForegroundColor Yellow
Write-Host "Logs will be written to: $logFilePath" -ForegroundColor Yellow

# Launch the installed script in a new PowerShell process
Write-Host "Launching the installed script..." -ForegroundColor Cyan
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptFilePath`"" -WindowStyle Hidden

Write-Host "The Computer On script is now running in the background." -ForegroundColor Green
Write-Host "It will also start automatically when you log in to Windows." -ForegroundColor Green

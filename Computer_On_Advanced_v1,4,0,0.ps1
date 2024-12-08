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

# Function: Normalize content for comparison
Function Get-NormalizedContent {
    param([string]$Content)
    return $Content.Trim() -replace "\r\n", "`n" -replace "\r", "`n"
}

# Function: Get the latest versioned file from GitHub
Function Get-LatestVersionedFile {
    param([string]$RepoApiUrl, [string]$FilePrefix)
    try {
        Write-Log "Fetching the latest versioned file matching prefix '$FilePrefix' from GitHub..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $repoContent = Invoke-WebRequest -Uri $RepoApiUrl -UseBasicParsing -ErrorAction Stop | ConvertFrom-Json

        $matchingFiles = $repoContent | Where-Object { $_.name -match "$FilePrefix_v(\d+),(\d+),(\d+),(\d+)\.ps1" }
        $latestFile = $matchingFiles |
            Sort-Object -Property {
                if ($_.name -match "$FilePrefix_v(\d+),(\d+),(\d+),(\d+)\.ps1") {
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
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
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

# Function: Send and verify key press
Function Test-KeyPress {
    param ($wshell)
    try {
        $wshell.SendKeys("{F15}")
        Write-Log "Key press sent"
        return $true
    } catch {
        Write-Log "Key press failed"
        return $false
    }
}

# Main function
Function Main {
    try {
        if (!(Test-Path -Path $folderPath)) {
            New-Item -ItemType Directory -Path $folderPath | Out-Null
        }
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


#Huxley wuz here
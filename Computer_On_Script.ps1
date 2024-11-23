# Define paths
$outputFilePath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Log_Files\Computer_On_Log.txt"
$folderPath = Split-Path $outputFilePath
$scriptPath = "C:\Users\hrust\Documents\Computer_On_Folder\Computer_On_Script\Computer_On_Script.ps1"
$githubRawUrl = "https://raw.githubusercontent.com/AldousFinn/ComputerOnScript/main/Computer_On_Script.ps1"

# Function: Write log with timestamp
Function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $outputFilePath -Value $logMessage
}

# Function: Normalize content for comparison
Function Get-NormalizedContent {
    param([string]$Content)
    $normalized = $Content.Trim().Replace("`r`n", "`n").Replace("`r", "`n")
    $preview = $normalized.Substring(0, [Math]::Min($normalized.Length, 1)) + "..." # Show only the first 50 characters
    Write-Log "Normalized content preview: $preview"
    return $normalized
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

# Function: Check for updates from GitHub
Function Check-ForUpdates {
    try {
        Write-Log "Checking for updates..."
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $latestScript = (Invoke-WebRequest -Uri $githubRawUrl -UseBasicParsing -ErrorAction Stop).Content
        $currentScript = Get-Content -Path $scriptPath -Raw
        
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
        Write-Log "Update check failed: $($_.Exception.Message)"
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

# Start the script
Main
#Huxley was here.

import os
import win32com.client

# Get the user's home directory and set the paths dynamically
user_profile = os.environ.get('USERPROFILE')
powershell_script_path = os.path.join(user_profile, "Documents", "Computer_On_Folder", "Computer_On_Script", "Computer_On_Script.ps1")
log_file_folder = os.path.join(user_profile, "Documents", "Computer_On_Folder", "Computer_On_Log_Files")
startup_folder = os.path.expandvars(r"%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup")
shortcut_name = "Computer_On_Script.lnk"

# PowerShell script content
powershell_script_content = r"""
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

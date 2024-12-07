# Computer On: Basic/Advanced Program

This program was initially designed to prevent computers at my workplace from entering sleep mode due to inactivity.

When you run the "*.exe*" file, it automatically sets up the required directories and files on your computer to keep the screen awake indefinitely (until you shut down the computer). To activate the script located at:  
"**\Users\<USERNAME>\Documents\Computer_On_Folder\Computer_On_Script**", you have two options:

1. **Restart Your Computer:** The script will automatically start during boot.
2. **Manually Activate the Script:**  
   - Press **`Win + R`**, type **`shell:startup`**, and press Enter.
   - In the Windows Startup folder, double-click the shortcut to begin the program.

---

## Basic Program

The basic program performs the core functionality: it prevents the computer from sleeping by simulating repeated key presses of the **F15** function key. This continues indefinitely until the computer is shut down through normal means.

Additionally, it logs the timestamp of each simulated keypress to a `*.txt*` file stored at:  
**`C:\Users\<USERNAME>\Documents\Computer_On_Folder\Computer_On_Log_Files`**

---

## Advanced Program

The advanced program includes all the features of the basic program, plus the ability to update itself from a `*.ps1*` file hosted on this GitHub repository.

While this functionality could be considered akin to a virus due to its ability to self-update, it allows you to push updates to the script as needed.

### Customizing the Update Source
If you'd like to use your own updates instead of relying on the default, simply edit the script file you downloaded. Change the value of `githubRawUrl` on the **fifth line** to point to the raw URL of your desired `*.ps1*` file.



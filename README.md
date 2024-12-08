# Computer On: Basic/Advanced Program

This program was designed to prevent computers at my workplace from entering sleep mode due to inactivity.

When you run either the Basic or Advanced "*.exe*" file, it automatically sets up the required directories and files on your computer to keep the screen awake indefinitely (until you shut down the computer). To activate the script located at "**\Users\Username\Documents\Computer_On_Folder\Computer_On_Script**", you have two options:

1. **Restart Your Computer:** The script will automatically start during boot.
2. **Manually Activate the Script:**  
   - Press "**Win + R**", type "**shell:startup**", and press Enter.
   - In the Windows Startup folder, double-click the shortcut to begin the program.

---

## Basic Program

The basic program performs the core functionality: it prevents the computer from sleeping by simulating repeated key presses of the **F15** function key. This continues indefinitely until the computer is shut down through normal means. If you find that the F15 key press types something else onto your computer you are more than welcome to change the script file to press a different key.

Additionally, it logs the timestamp of each simulated keypress to a "*.txt*" file stored at:  
"**\Users\Username\Documents\Computer_On_Folder\Computer_On_Log_Files**".

---

## Advanced Program

The advanced program includes all the features of the basic program, plus the ability to update itself from the most recent "*Computer_On_Advanced_vX,X,X,X.ps1*" file hosted on this GitHub repository.

While this functionality could be considered akin to a virus due to its ability to self-update, it allows you to push updates to the script as needed.

### Customizing the Update Source
If you'd like to use your own updates instead of relying on the default, you will have to edit the script file you downloaded. Change the value of "*repoApiUrl*" on the **106th line** to point to the raw URL of your desired repository in a manner such as this: **$repoApiUrl = "https://api.github.com/repos/YourUsername/NewRepo/contents"**.



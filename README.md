# Computer On Basic/Adv Program
This was originally design to circumvent my employer's desire for the computers at work to fall asleep due to inactivity. 

The "*.exe*" file when run will create all the necessary directories and files on your computer to keep the screen awake indefinitely (Until you turn the computer off). To start the script that should be installed at **"\Users\<USERNAME>\Documents\Computer_On_Folder\Computer_On_Script"** you must either restart the computer or activate the script in the Windows startup folder. This can be accessed by pressing "*Win + R*" and typing "*shell:startup*". Then you must double-click the shortcut to begin the program.



## Basic Program
The basic program does just as the above describes. It will keep the computer awake by pressing the "*F15*" function key until you turn the computer off via the normal methods. It will then output timestamps of when a keypress is sent to a "*.txt*" file located at **"\Users\<USERNAME>\Documents\Computer_On_Folder\Computer_On_Log_Files"**.



## Advanced Program
The advanced program has all of the same functionality as the basic program but it will also check for updates from the "*.ps1*" file in this github repo. This does make the advanced program some sort of defacto virus. However it does allow you to push updates to the script however you see fit. If you would like to push your own updates instead of relying on me to do it, all you need to do is change the "**githubRawUrl**" on the *fifth* line of the script file you downloaded to the raw URL for the "*.ps1*" file you would like you the script file to replicate.   



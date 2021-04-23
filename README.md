# Timecord

Hello there! Timecord keeps track of commands sent in Discord (or any other platform) and can prevent you from running a command too early, and tell you how much time is left. It can also notify you when a cooldown has finished. This can be useful if you are trying to grind coins in an economy bot.

### Disclaimer

Timecord DOES NOT directly interact with Discord. It only detects your keystrokes and saves the information. This means that if you type a command in another application (like google), it will recognize the command is being run. Timecord DOES NOT and WILL NEVER automatically send commands. This is to prevent you from breaking Discord's ToS or the Discord bot's ToS. However, I (Timothy Huang) am not liable for anything that results from using this software.

## Download and Installation

Note: Timecord is a portable application.

**NOTE:** It's getting detected as a virus on many different things, so I removed the exe. Please use the source code instead.

Download the latest release [here](https://github.com/timothymhuang/Timecord/releases).

Move it to the folder you would like, the run it. The necessary files should automatically be created. If you ever need to move the application, make sure you also copy all the files it created or else your settings won't be saved.

## Instructions

Once you download it you may be lost. Here is how you use it.

### Getting Started

All of the commands you add to Timecord are called timers. This is because the app is basically a timer app that resets the timer when you type a command. 

**Creating Your First Timer**

1. Find the icon in your taskbar tray named Timecord. Right click on it and select [Settings]. 
2. Switch to the [Create Timer] tab. Now, fill in the information. 
   1. The command name is what you want to call the command, and what will display in the notifications. It isn't what command you want to detect. For example, you can name it "TacoShack Work" or "Dank Memer Fishing". 
   2. In command aliases, put in all the aliases for the command you want to here. Place each command on a new line.
   3. Now, input the command cooldown. Input the number and change between days, hours, minutes, or seconds.
   4. Decide if you want to disable notifications. If a command's cooldown is only 30s, then you might not want to be notified every time the cooldown finishes, but it can prevent you from accidentally spamming a command that isn't available yet. 
   5. Once all the settings are correct, click "Create Timer"
3. The timer is now ready to test. Make sure to close the settings menu before you test a command because the timers are disabled while the settings window is open (it's still running the timer but won't detect keystrokes). 
4. Run the command. If you enabled notifications it should go away. If you run the command again right away, it should tell you the command still has a cooldown active.

**Editing a Command**

1. In the settings, go the [Edit Timer] tab and select the timer you want to edit from the dropdown. Click the [Edit Timer] button.
2. Here you can customize all the settings of the timer except the command name (for now, I want to remove this limitation later). You can also delete a timer from this menu.

**Other Settings**

1. In the settings, go to the [Settings] tab. Here you can edit the following settings:
   1. Windows push notifications (work in progress).
   2. Tooltip notifications - a small piece of text in the corner of your screen that will display what commands are available.
   3. Tooltip location - Where you want the tooltip to display. The top left of your screen is x0 y0. The X coordinate goes left to right and the Y coordinate goes up and down.
   4. Tooltip notification sound - play a notification sound (sounds like a bunch of rapid clicks) when a new command is ready (only works when tooltip notifications are active).
   5. Run on Windows Startup - Startup when you turn on your computer.

**Oops**

If you ran a command in a channel where the bot isn't active, you may try to run the command in the correct channel, but of course you can't because Timecord is telling you a cooldown is still active.

 In order to run the command, right click on the tray icon and select [Force Next Command]. The next command you run will ignore the cooldown and allow the command to be run, and will also reset the cooldown.

## Notes

All the information for the timer is stored in the file named "timers.ini", meaning the program will still work if you sync this between two computers. 

## To Do

**Out in next update**

- Create notification sound

**Priority**

- Create a Windows notification option
- Make sure command aliases don't already exist

**Backlog**

- Create "alarm" timers (trigger at specific time instead of interval
- Add option to make timers only work in certain applications
- Create "Check for Update" button
- Ability to rename timers.

#SingleInstance, Force
#Persistent
AutoTrim, On
SendMode Input
SetWorkingDir %A_ScriptDir%
SetKeyDelay, -1

;TRAY MENU
;---------
Menu,Tray,NoStandard 
Menu,Tray,DeleteAll
If FileExist("icon.ico") {
    Menu, Tray, Icon, icon.ico
} else {
    Extract_geticon("icon.ico")
    If FileExist("icon.ico") {
        Menu, Tray, Icon, icon.ico
    }
}
Menu, Tray, Add, Force Next Command, skipcheck
Menu, Tray, Add
Menu, Tray, Add, Settings, starttimermenu
;Menu, Tray, Add, Reload, reload
Menu, Tray, Add, Exit, exitapp

;FIRST TIME CHECKUP
;------------------
if !(FileExist("timers.ini")) {
    FileAppend,, timers.ini
}
if !(FileExist("settings.ini")) {
    FileAppend,[notification]`ntraytip=1`ntooltip=1`nttx=0`ntty=0, settings.ini
}

;VARIABLES
;---------
IniRead, traytip, settings.ini, notification, traytip
IniRead, tooltip, settings.ini, notification, tooltip
IniRead, ttx, settings.ini, notification, ttx
IniRead, tty, settings.ini, notification, tty
checkx := ttx
checky := tty
Gosub, writeinfo
resettimer := false
settingsopen := false
createhotstrings()

SetTimer, tooltipnotifs, 1000
Return

tooltipnotifs:
if (A_TimeIdlePhysical > 5000) {
    Return
}

prev := msg
msg := ""

checklist := getcmds()

Loop % checklist.MaxIndex()
{
    name := checklist[A_Index]
    if isready(name) {
        IniRead, check, timers.ini, %name%, notification
        if (check) {
            if (msg = "") {
                msg := name
            } else {
                msg := msg ", " name
            }
        }
    }
}


foldername := "C:\Users\" A_UserName "\AppData\Local\Temp"
if (msg = foldername) {
    ToolTip,,,,15
    msg := ""
} else if (tooltip = 1) && (msg != prev) {
    CoordMode, Tooltip, Screen
    ToolTip, %msg%, %ttx%, %tty%, 15
} else if (ttx != checkx) && ((tty != checky) || (tooltip = 1)) {
    CoordMode, Tooltip, Screen
    ToolTip, %msg%, %ttx%, %tty%, 15
    checkx := ttx
    checky := tty
}else if (tooltip = 0){
    ToolTip,,,,15
    msg := ""
}
Return

;~~~~~~~~~~~~~~~~~~~~~~~~;
;       SETTINGS GUI     ;
;~~~~~~~~~~~~~~~~~~~~~~~~;

;   THE GUI
;----------
starttimermenu:
deletehotstrings()
selecttab := 1
if (settingsopen){
    Return
}
settingsopen := true
timermenu:
Gui, New,,Timecord Settings
Gui, -MinimizeBox
Gui, Add, Tab3, choose%selecttab%, Edit Timer|Create Timer|Settings|About
Gui, Tab, 1
Gui, Add, Text,, Edit Existing Timers

IniRead, temp, timers.ini
foldername := "C:\Users\" A_UserName "\AppData\Local\Temp"
If (temp = foldername) {
    Gui, Add, Text,,There are currently no timers!
    Gui, Add, Text,,Go to the Create Timer tab to make one.
    Gui, Add, GroupBox, x15 y48 h60 w210
    Gosub, goto2
    Return
}
currentcmds := StrReplace(temp, "`n","|")
Gui, Add, DropDownList, veditthiscommand, %currentcmds%
Gui, Add, Button, w100 gedittiemr, Edit Timer

goto2:
Gui, Tab, 2
Gui, Add, Text,,Command Name (Not The Trigger)
Gui, Add, Edit, r1 w280 vNewName
Gui, Add, Text,,Command Aliases (Put each alias on a new line)
Gui, Add, Edit, r5 w280 vNewAliases
Gui, Add, Text,,Command Cooldown
Gui, Add, Edit, Number
Gui, Add, UpDown, Range0-1000 r1 w135 vNewCooldown, 10
Gui, Add, DropDownList, y197 x156 w134 vTimeUnit choose3, Days|Hours|Minutes|Seconds
Gui, Add, Checkbox, x20 y230 checked1 venablenotifs, Enable Notifications
Gui, Add, Button, x20 y250 w123 gcreatetimer, Create Timer

temp := A_Startup "\timecord.lnk"
if(FileExist(temp)) {
    startup := 1
} else {
    startup := 0
}
Gui, Tab, 3
Gui, Add, Text,,Notifications
Gui, Add, Checkbox, checked%traytip% vtraytip, Enable Tray Notifications (Coming Soon)
Gui, Add, Checkbox, checked%tooltip% vtooltip, Enable Tooltips
Gui, Add, Text,,Tooltip Location
Gui, Add, Text, x22 y107, X                 Y
Gui, Add, Edit, Number y122 x22 w50
Gui, Add, UpDown, vttx Range0-%A_ScreenWidth%, %ttx%
Gui, Add, Edit, Number y122 x80 w50
Gui, Add, UpDown, vtty Range0-%A_ScreenHeight%,%tty%
Gui, Add, Checkbox, x20 y150 vstartup checked%startup%, Run on Windows Startup
Gui, Add, Button, w75 gsavesettings, Save

Gui, Tab, 4
Gui, Add, Text,,Timecord v1.0.0 - Copyright 2021 Timothy Huang
Gui, Add, Edit,readonly r14 w280, %helpinfo%
Gui, Add, Button, x20 y250 ggithub,View GitHub Repository (Contains Instructions)

Gui, Tab
Gui, Add, Text, x10 y293, Timers Disabled While Settings Opened
Gui, Add, Button, x215 y290 w100 gGuiClose, Close
Gui, show, w324 h320
Return

;EDIT TIMER
;----------
github:
Run, https://github.com/timothymhuang/Timecord
Return

edittiemr:
Gui, Submit
If editthiscommand is space
{
    Gui, Tab, 1
    Gui, Add, Text, x150 y56,Select a Timer
    Gui, Show
    Return
}
Gui, Destroy
IniRead, tempargs, timers.ini, %editthiscommand%, alias
currentaliases := StrReplace(tempargs, A_Tab, "`n")
IniRead, currenttime, timers.ini, %editthiscommand%, time
IniRead, tempunit, timers.ini, %editthiscommand%, unit
if (tempunit = "d") {
    currentunit = 1
} else if (tempunit = "h") {
    currentunit = 2
} else if (tempunit = "m") {
    currentunit = 3
} else {
    currentunit = 4
}
IniRead, currentnotif, timers.ini, %editthiscommand%, notification

Gui, New,,Timecord Settings
Gui, Add, Text,,Command Name (Not The Trigger)
Gui, Add, Edit, ReadOnly r1 w280, %editthiscommand%
Gui, Add, Text,,Command Aliases (Put each alias on a new line)
Gui, Add, Edit, r5 w280 vNewAliases, %currentaliases%
Gui, Add, Text,,Command Cooldown
Gui, Add, Edit, Number
Gui, Add, UpDown, Range0-1000 r1 w135 vNewCooldown, %currenttime%
Gui, Add, DropDownList, y169 x156 w134 vTimeUnit choose%currentunit%, Days|Hours|Minutes|Seconds
Gui, Add, Checkbox, x10 y202 checked%currentnotif% venablenotifs, Enable Notifications
Gui, Add, Button, x10 y222 w123 gsavetimer, Save Timer
Gui, Add, Button, x155 y222 w123 gdeletetimer, Delete Timer
Gui, Add, Text, x10 y293, Timers disabled while settings open
Gui, Add, Button, x215 w100 y290 gcancelback, Cancel
Gui, show, w324 h320
Return

savetimer:
Gui, Submit
If NewAliases is Space
{
    Gui, Show
    MsgBox,, Create Timer, Command Aliases is empty.
    Return
}
If (NewCooldown = 0)
{
    Gui, Show
    MsgBox,, Create Timer, Cooldown must be greater than 0.
    Return
}
Gui, Destroy
IniAliases := StrReplace(NewAliases,"`n", A_Tab)
IniUnit := SubStr(TimeUnit, 1, 1)
StringLower, IniUnit, IniUnit
IniWrite, %IniAliases%, timers.ini, %editthiscommand%, alias
IniWrite, %NewCooldown%, timers.ini, %editthiscommand%, time
IniWrite, %IniUnit%, timers.ini, %editthiscommand%, unit
IniWrite, %enablenotifs%, timers.ini, %editthiscommand%, notification
IniWrite, 16010101000000, timers.ini, %editthiscommand%, lastrun
selecttab := 1
Gosub, timermenu
Return

deletetimer:
MsgBox, 260,Timecord Settings, Are you sure you want to delete %editthiscommand%?
IfMsgBox, Yes
{
    IniDelete, timers.ini, %editthiscommand%
    Gui, Destroy
    selecttab := 1
    Gosub, timermenu
    Return
}
Return

cancelback:
Gui, Destroy
selecttab := 1
Gosub, timermenu
Return

;CREATE NEW TIMER
;----------------
createtimer:
Gui, Submit
If NewName is Space
{
    Gui, Show
    MsgBox,,Timecord Settings, Command name is empty.
    Return
}
If NewAliases is Space
{
    Gui, Show
    MsgBox,,Timecord Settings, Command Aliases is empty.
    Return
}
If (NewCooldown = 0)
{
    Gui, Show
    MsgBox,,Timecord Settings, Cooldown must be greater than 0.
    Return
}
If cmdexist(NewName) {
    Gui, Show
    MsgBox,,Timecord Settings, Command name already exists.
    Return
}
Gui, Destroy
IniAliases := StrReplace(NewAliases,"`n", A_Tab)
IniUnit := SubStr(TimeUnit, 1, 1)
StringLower, IniUnit, IniUnit
IniWrite, %IniAliases%, timers.ini, %NewName%, alias
IniWrite, %NewCooldown%, timers.ini, %NewName%, time
IniWrite, %IniUnit%, timers.ini, %NewName%, unit
IniWrite, %enablenotifs%, timers.ini, %NewName%, notification
IniWrite, 16010101000000, timers.ini, %NewName%, lastrun
selecttab := 2
Gosub, timermenu
MsgBox,,Timecord Settings, Timer Created
Return

;   MISC NOTIFICATIONS
;---------------------
savesettings:
Gui, Submit
IniWrite, %traytip%, settings.ini, notification, traytip
IniWrite, %tooltip%, settings.ini, notification, tooltip
IniWrite, %ttx%, settings.ini, notification, ttx
IniWrite, %tty%, settings.ini, notification, tty
if (startup = 1) {
    if !(FileExist(A_Startup "\timecord.lnk")) {
        temp := A_Startup "\timecord.lnk"
        FileCreateShortcut, %A_ScriptFullPath%, %temp%, %A_ScriptDir%
    }
} else {
    if FileExist(A_Startup "\timecord.lnk") {
        temp := A_Startup "\timecord.lnk"
        FileDelete, %temp%
    }
}

Gui, Show
Return

guicancel:
Gui, Cancel
Gui, Destroy
createhotstrings()
settingsopen := false
Return

nothing:
Return

GuiClose:
Gui, Cancel
Gui, Destroy
createhotstrings()
settingsopen := false
Return

;~~~~~~~~~~~~~~~~~~~~~~~;
;       TRAY MENU       ;
;~~~~~~~~~~~~~~~~~~~~~~~;
reload:
reload
Return

exitapp:
ExitApp
Return

skipcheck:
resettimer := true
ToolTip, Next command run will ignore timer.
Return

hidetooltip:
ToolTip
Return

;~~~~~~~~~~~~~~~~~~~~~~~;
;       FUNCTIONS       ;
;~~~~~~~~~~~~~~~~~~~~~~~;

action(name){
    ToolTip
    command := SubStr(A_ThisHotkey, 6)
    global timecheck
    global resettimer

    if (resettimer) {
        Sendraw % command
        IniWrite, %A_Now%, timers.ini, %name%, lastrun
        variable := "n_" name
        %variable% := false
        resettimer := false
        Return
    }
    if isready(name) {
        Sendraw % command
        IniWrite, %A_Now%, timers.ini, %name%, lastrun
        variable := "n_" name
        %variable% := false
    } else {
        ToolTip % "Please wait " timecheck
        SetTimer, hidetooltip, -2000
    }
}

isready(name){
    global timecheck
    IniRead, lastrun, timers.ini, %name%, lastrun
    IniRead, time, timers.ini, %name%, time
    IniRead, unit, timers.ini, %name%, unit
    EnvAdd, lastrun, %time%, %unit%
    EnvSub, lastrun, %A_Now%, s

    if (lastrun >= 0) {
        IniRead, lastrun, timers.ini, %name%, lastrun
        EnvAdd, lastrun, %time%, %unit%
        day := lastrun
        hour := lastrun
        minute := lastrun
        second := lastrun
        EnvSub, day, %A_Now%, d
        EnvSub, hour, %A_Now%, h
        hour := Mod(hour, 24)
        EnvSub, minute, %A_Now%, m
        minute := Mod(minute, 60)
        EnvSub, second, %A_Now%, s
        second := Mod(second, 60)

        msg := ""
        if (day >= 1) {
            if (day = 1) {
                msg := day " day, "
            } else {
                msg := day " days, "
            }
        }
        if (hour >= 1) {
            if (hour = 1) {
                msg := msg hour " hour, "   
            } else {
                msg := msg hour " hours, "
            }
        }
        if (minute >= 1) {
            if (minute = 1) {
                msg := msg minute " minute, "   
            } else {
                msg := msg minute " minutes, "
            }
        }
        if (true) {
            if (second = 1) {
                msg := msg second " second"   
            } else {
                msg := msg second " seconds"
            }
        }
        timecheck := msg

        Return false
    } else {
        Return true
    }
}

timecheck(section,key,time,unit) {
    IniRead, lastrun, timecord.ini, %Section%, %key%
    EnvAdd, lastrun, %time%, %unit%
    day := lastrun
    hour := lastrun
    minute := lastrun
    second := lastrun
    EnvSub, day, %A_Now%, d
    EnvSub, hour, %A_Now%, h
    hour := Mod(hour, 24)
    EnvSub, minute, %A_Now%, m
    minute := Mod(minute, 60)
    EnvSub, second, %A_Now%, s
    second := Mod(second, 60)

    msg := ""
    if (day >= 1) {
        if (day = 1) {
            msg := day " day, "
        } else {
            msg := day " days, "
        }
    }
    if (hour >= 1) {
        if (hour = 1) {
            msg := msg hour " hour, "   
        } else {
            msg := msg hour " hours, "
        }
    }
    if (minute >= 1) {
        if (minute = 1) {
            msg := msg minute " minute, "   
        } else {
            msg := msg minute " minutes, "
        }
    }
    if (true) {
        if (second = 1) {
            msg := msg second " second"   
        } else {
            msg := msg second " seconds"
        }
    }
    Return %msg%
}


;OTHER
createhotstrings(){
    names := getcmds()
    Loop % names.MaxIndex()
    {
        section := names[A_Index]
        IniRead, aliases, timers.ini, %section%, alias
        aliases := StrSplit(aliases, A_Tab)
        outsideindex := A_Index
        Loop % aliases.MaxIndex()
        {
            cmd := ":X?*:" aliases[A_Index] "`n"
            name := names[outsideindex]
            Fn := Func("action").Bind(name)
            Hotstring(cmd,Fn,"On")
        }
    }
}
Return

deletehotstrings(){
    names := getcmds()
    Loop % names.MaxIndex()
    {
        section := names[A_Index]
        IniRead, aliases, timers.ini, %section%, alias
        aliases := StrSplit(aliases, A_Tab)
        Loop % aliases.MaxIndex()
        {
            cmd := ":?*:" aliases[A_Index] "`n"
            Hotstring(cmd,,"Off")
        }
    }
}
Return

HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}

getcmds(){
    IniRead, temp, timers.ini
    currentcmds := StrSplit(temp, "`n")
    Return %currentcmds%
}



cmdexist(name){
    IniRead, temp, timers.ini
    currentcmds := StrSplit(temp, "`n")
    if HasVal(currentcmds,name) {
        Return True
    } else {
        Return False
    }
}


writeinfo:
helpinfo=
(
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

Please go to https://github.com/timothymhuang/Timecord/blob/main/LICENSE to view a full copy of the license.

Timecord is made with AutoHotkey (https://www.autohotkey.com/)
Uses "Include virtually any file in a script" by Rseding91 (https://autohotkey.com/board/topic/64481-include-virtually-any-file-in-a-script-exezipdlletc/)

)
Return

geticon_Get(_What)
{
	Static Size = 67646, Name = "icon.ico", Extension = "ico", Directory = "D:\Timothy\OneDrive\Surface\Documents\AutoHotKey\Timecord"
	, Options = "Size,Name,Extension,Directory"
	;This function returns the size(in bytes), name, filename, extension or directory of the file stored depending on what you ask for.
	If (InStr("," Options ",", "," _What ","))
		Return %_What%
}

Extract_geticon(_Filename, _DumpData = 0)
{
	;This function "extracts" the file to the location+name you pass to it.
	Static HasData = 1, Out_Data, Ptr, ExtractedData
	Static 1 = "AAABAAEAgIAAAAEAIAAoCAEAFgAAACgAAACAAAAAAAEAAAEAIAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN+PcBDZiXE22YpyXtmKcYfainKl2opxv9qKcb/aiXLW2oly39qJcubaiXL/2oly/9qJcubaiXLf2oly1tqKcb/ainG/2opypdmKcYfZinJe2YlxNt+PcBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAagzZiHNJ2olzitqJcsLaiXLq2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcuraiXLC2olzitmIc0nVgGoMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVgIAG2Id0QtqIc4PZiXLF2oly+tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcvrZiXLF2ohzg9iHdELVgIAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADbiXI42YlzldqJc+zaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc+zZiXOV24lyOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN6Mcx/ainF82olx2tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olx2tqKcXzejHMfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANiJcTTbiXKv2oly/tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv7biXKv2IlxNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANmKcT3aiXK42oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bi3T/4JyJ/+Onlf/kqJj/6LWn/+i1p//swbX/7MG1/+i1p//otaf/46eV/+Onlf/gnIj/2olz/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olyuNmKcT0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANmJckPaiXLC2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/fmob/6LWn/+7Jvv/029T/+ezp///+/v/////////////////////////////////////////////////////////////////+/Pz/+Orm//PY0f/txbn/5rCh/96VgP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcsLZiXJDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJdhzaiXGr2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3pWA/+e0pf/x08r/+/Lv//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////nr5//vy8H/5Kqa/9uOeP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXGr24l2HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL+AgATaiHJ02oly89qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dkn3/6ruu//fn4v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////vz7//Tc1f/mrp//24t1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLz2ohydL+AgAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiHM+2oly1NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdf/lrZ3/89nS//78/P/////////////////////////////////////////////////////////////////78u//9uHc//Xf2f/x08r/8dPK/+7Ivf/uyb7/8dPK//HTyv/24dz/9uLc//z08v/////////////////////////////////////////////////////////////////89PL/7sm//+Ccif/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly1NqIcz4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC/gIAE2olyiNqJcv7aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uMdv/puq3/+/Hu//////////////////////////////////////////////////36+f/13tj/7cW5/+exov/hoI3/3I54/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yQev/iopD/6Lep/+7Kv//25N7//v39//////////////////////////////////////////////////Xg2//jppT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/tqJcoi/gIAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA3I1yHduJcsTaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uNd//qvK//+/Px/////////////////////////////////////////v7/9uPe/+3Fuf/jppT/24x1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/vzcT/9uHc//bh3P/24dz/9uHc//bh3P/24dz/8M7E/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/cj3n/5q6e//DOxf/67uv////////////////////////////////////////////14Nr/46ST/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uJcsTcjXIdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANqIdEvaiXPs2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qKc//puaz//PTy///////////////////////////////////////57Oj/68G0/96Vgf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//fl3//////////////////////////////////35eD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hoY7/8M7E//349v//////////////////////////////////////9d/Y/+Gfjf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc+zaiHRLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP+AgALaiXKI2oly/tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hoI3/9+bh//////////////////////////////////77+v/wzsX/4qKQ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9+Xf//////////////////////////////////fl4P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2412/+ezpP/24dz//////////////////////////////////v39/+7Ivv/bjXf/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv7aiXKI/4CAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVgIAG24lyqNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/cj3n/78vB//79/f////////////////////////////36+f/uyb//3ZR//9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/35d//////////////////////////////////9+Xg/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ipJL/9eDZ//////////////////////////////////rv7P/kqJj/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXKo1YCABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA1YBqDNqIc7vaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46WT//vy7/////////////////////////////35+P/tx7z/3ZJ9/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//fl3//////////////////////////////////35eD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46WU//bh2//////////////////////////////////x08r/3I95/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiHO71YBqDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANyLdBbbiXLL2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+u/s//+/f3////////////////////////////z2ND/3pWB/9qJcv/bi3T/6ryv/+i1p//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9+Xf//////////////////////////////////fl4P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6LWn/+q8r//bi3T/2oly/+Wsm//78e7////////////////////////////57Oj/4JyI/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXLL3It0FgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADejHMf2olx2tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yRe//029T////////////////////////////67+z/5aua/9qJcv/aiXL/5KmZ//ns6P///////Pb0/9yRe//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/35d//////////////////////////////////9+Xg/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yRe//89vT///////ns6P/kqZn/2oly/9yPef/vzML///79///////////////////////9+fj/5rCg/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXHa3oxzHwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA24ZtFdqJcdraiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/gnYr/+vDt/////////////////////////v7/7si+/9uNd//aiXL/35qG//Tc1f//////////////////////78zC/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+/NxP/24dz/9uHc//bh3P/24dz/9uHc//bh3P/wzsT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/78zC///////////////////////03NX/35qG/9qJcv/iopD/+Orm////////////////////////////7sm//9qKdP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXHa24ZtFQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAagzainLM2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4qSS//339v///////////////////////Pb0/+Wrmv/aiXL/3I96/+7Jv//+/Pz////////////////////////////+/fz/4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Ccif/+/fz////////////////////////////+/Pz/7sm//9yPev/bjXf/8dPK////////////////////////////89rS/9uMdf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ainLM1YBqDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVgIAG2ohzu9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Wrmv/++vn///////////////////////fl3//eloL/2oly/9qJcv/dkn3//ff2///////////////////////////////////////13tj/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9d7Y///////////////////////////////////////99/b/3ZJ9/9qJcv/aiXL/6biq//78+///////////////////////9d7Y/9uOeP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiHO71YCABgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/4CAAtuJcqjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/nsqP//v38///////////////////////vzcT/24t1/9qJcv/aiXL/2oly/9qJcv/qvK/////////////////////////////////////////////lrJv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Wsm////////////////////////////////////////////+q8r//aiXL/2oly/9qJcv/aiXL/4qKP//vy7///////////////////////9uPd/9yPev/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXKo/4CAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADainKJ2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/57Ok///+/v//////////////////////7MG1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdP/57Oj/////////"
	Static 2 = "//////////////////////////////fl3//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9+Xf///////////////////////////////////////57Oj/24t0/9qJcv/aiXL/2oly/9qJcv/aiXL/3pWA//ns6P//////////////////////9+fi/9yRe//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ainKJAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2oh0S9qJcv7aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+SomP/+/Pz///////////////////79/+m5q//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Sqmf////////////////////////////79/P/vzML/3JF7/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ckXv/78zC//79/P///////////////////////////+Sqmf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3ZJ9//jn4///////////////////////9uLc/9uMdv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv7aiHRLAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANyNch3aiXPs2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hoI3//fn3//////////////////78/P/msKH/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//Tc1f/////////////////139j/4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4JyJ//Xf2P/////////////////03NX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3JB6//bj3v//////////////////////8tbO/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc+zcjXIdAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC/gIAE24lyxNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/35iE//z08v///////////////////v7/5rCh/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4JuH//78/P/67uv/5ayc/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+WsnP/67uv//vz8/+Cbh//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2454//bi3P//////////////////////7se9/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uJcsS/gIAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANqJcojaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yOeP/57Oj//////////////////////+q8r//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46eV/9uLdf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdf/jp5X/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3JF7//ns6P//////////////////////6biq/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcogAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiHM+2oly/dqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/8dLJ///////////////////////uyL3/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3peD//vz8f/////////////////+/Pz/4aCO/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/dqIcz4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzJlmBdqJctPaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+ezpP//////////////////////8tTM/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4aCO//35+P/////////////////57er/3I54/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly08yZZgUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiHJ02oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/fmob//fn4//////////////////nr5//bjXf/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5q6e///////////////////////x0sn/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2ohydAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA24l2HNqJcvPaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24t0//jo4//////////////////++vn/4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/8M7E///////////////////////msaL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLz24l2HAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiXGr2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/qvbD//////////////////////+m3qf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjXb/+evn//////////////////349v/dlH//2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXGrAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2YlyQ9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3ZR///359//////////////////y1s7/2454/+Wtnf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Wtnf/hoY///vv6//////////////////HSyf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZiXJDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiXLC2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/y1Mz//////////////////ff2/92Tfv/sxLj///////bh2//hnov/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Gei//24dv//////+zEuP/qvK////////////////////7+/+KikP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcsIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2YpxPdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46aU/////v/////////////////puq3/3paC//76+f/////////////+/f/wz8X/3ZJ9/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/92Sff/wz8X///79/////////////vr5/96XhP/46ub/////////////////9+bh/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9mKcT0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiXK42oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/46OP/////////////////+Ojj/9qKc//y1s7////////////////////////////99/b/6ryv/9uLdf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdf/qvK///ff2////////////////////////////8tbO/+Omlf////7/////////////////6Lao/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olyuAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2IlxNNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5aua///////////////////+/v/io5L/46ST/////v//////////////////////////////////////6r2w/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6r2w//////////////////////////////////////////7/46ST//LXz//////////////////78/D/24x1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2IlxNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADbiXKv2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/2493/////////////////8tfP/9qKc//45+P///////////////////////////////////////vy7//bjnj/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjnj/+/Lv///////////////////////////////////////45+P/3peD//36+f/////////////////otqj/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXKvAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA14dwINqJcv3aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46WT/////////////////////v/hn4z/6Lao////////////////////////////////////////////57Kj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/nsqP////////////////////////////////////////////otqj/7srA//////////////////nt6f/ainP/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv3Xh3AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADainF82oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/03db/////////////////9N3W/9qJcv/fmIT/89nR//////////////////////////////////bk3v/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/25N7/////////////////////////////////89nR/9+YhP/elYH//vz8/////////////////+avn//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qKcXwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJctnaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4JyI/////v/////////////////jpZP/2oly/9qJcv/aiXL/46eW//jq5v///////////////////v7/4aGO/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Ghjv///v7/////////////////+Orm/+Onlv/aiXL/2oly/9qJcv/x0sn/////////////////9+bh/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24ly2QAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADbiXI42oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/tx7z/////////////////9uPd/9qJcv/aiXL/2oly/9qJcv/aiXL/2op0/+m5q//89vT///////HSyf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//HSyf///////Pb0/+m5q//ainT/2oly/9qJcv/aiXL/2oly/+CciP///v7/////////////////4qKQ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24lyOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANmJc5XaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olz//rw7f/////////////////ntKX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yQe//uyb//3ZR//9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3ZR//+7Jv//ckHv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//Ta0//////////////////vzML/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZiXOVAAAAAAAAAAAAAAAAAAAAAAAAAADVgIAG2olz7NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/jppT//////////////////fr5/9yPef/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5a6e//////////////////z08v/bi3T/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc+zVgIAGAAAAAAAAAAAAAAAAAAAAANiHdELaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//DQx//////////////////y1c3/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjHX//Pf1/////////////////+Sqmv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9iHdEIAAAAAAAAAAAAAAAAAAAAA2ohzg9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bi3T//ff2/////////////////+Sqmv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJ"
	Static 3 = "cv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/wz8b/////////////////8tTM/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2ohzgwAAAAAAAAAAAAAAAAAAAADZiXLF2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Kjkf/////////////////89PL/2op0/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+OllP/////////////////9+fj/24x1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZiXLFAAAAAAAAAAAAAAAA1YBqDNqJcvraiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/68G0//////////////////LVzf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olz//vy7//////////////////jpZT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcvrVgGoMAAAAAAAAAADZiHNJ2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/139j/////////////////6bep/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/8dPK/////////////////+zDt//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9mIc0kAAAAAAAAAANqKcovaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24t1//36+f/////////////////fmob/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/otaf/////////////////9eDb/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2opyiwAAAAAAAAAA2olywdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/jpJP/////////////////+/Lv/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9+YhP/////////////////++/r/24x2/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLBAAAAAAAAAADaiXLp2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+q8r//////////////////y1Mz/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//rw7f/////////////////jppT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcukAAAAA4Yd4EdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/8M7E/////////////////+u/sv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/8dPK/////////////////+q9sP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+GHeBHai3Q32oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/14Nn/////////////////5a2d/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/elYH/3pWB/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/rvrH/////////////////8M7F/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2ot0N9mKcl7aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//vx7v/////////////////gm4j/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2412/+q8r//24t3///7+//////////////7+//bi3f/qvK//2412/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+WsnP/////////////////14Nr/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZinJe24hxhdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjnj///7+/////////////v39/9uLdf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Sqmf/78u/////////////////////////////////////////////78u//5KqZ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4JuH//////////////////vy7//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uIcYXbiXKo2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Gei//////////////////67uv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/puKr///79/////////////////////////////////////////////////////////v3/6biq/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bi3X//v38///////////////+/9uOeP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24lyqNqJcrjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46eV//////////////////bh3P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5KqZ///+/f///////////////////////////////////////////////////////////////////v3/5KqZ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/57er/////////////////4Z6L/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXK42YlyxdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/lrJz/////////////////9NvU/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uNdv/78u/////////////////////////////////////////////////////////////////////////////78u//2412/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//bh3P/////////////////jp5X/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9mJcsXbiXLS2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+eyo//////////////////y1c3/5aub//bh3P/24dz/9uHc//bh3P/24dz/9uHc//bh3P/fmIT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6ruu///////////////////////////////////////////////////////////////////////////////////////qu67/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/35iE//bh3P/24dz/9uHc//bh3P/24dz/9uHc//bh3P/lq5v/9NvU/////////////////+Wtnf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24ly0tqJct/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6biq//////////////////DQx//otqj//////////////////////////////////////+Cdiv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/2493///////////////////////////////////////////////////////////////////////////////////////bj3f/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/gnYr//////////////////////////////////////+i2qP/y1c3/////////////////57Kj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLf2oly69qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/rvrL/////////////////7sq//+i2qP//////////////////////////////////////4J2K/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2op0//79/f///////////////////////////////////////////////////////////////////////////////////////v39/9qKdP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Cdiv//////////////////////////////////////6Lao//DQx//////////////////puKr/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcuvaiXL42oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+zCt//////////////////txbr/6Lao///////////////////////////////////////gnYr/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/elYD/////////////////////////////////////////////////////////////////////////////////////////////////3pWA/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4J2K///////////////////////////////////////otqj/7sq//////////////////+u+sv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly+NqJcvjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/676y/////////////////+7Jv//otqj//////////////////////////////////////+Cdiv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/96VgP/////////////////////////////////////////////////////////////////////////////////////////////////elYD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/gnYr//////////////////////////////////////+i2qP/txbr/////////////////7MK3/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL42oly69qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/puav/////////////////8M/G/+i2qP//////////////////////////////////////4J2K/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2op0//79/f///////////////////////////////////////////////////////////////////////////////////////v39/9qKdP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Cdiv//////////////////////////////////////6Lao/+7Kv//////////////////rvrH/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc+zaiXLf2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+ezpP/////////////////y1c3/6Lao///////////////////////////////////////gnYr/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9uPd///////////////////////////////////////////////////////////////////////////////////////24t3/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4J2K///////////////////////////////////////otqj/8NDH/////////////////+m4qv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly39uJctLaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5a6e//////////////////Ta0//lq5v/9uHc//bh3P/24dz/9uHc//bh3P/24dz/9uHc/9+YhP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/qu67//////////////////////////////////////////////////////////////////////////////////////+q7rv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/fmIT/9uHc//bh3P/24dz/9uHc//bh3P/24dz/9uHc/+Wrm//y1s7/////////////////57Kj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLT2YlyxdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/kqJb/////////////////9eDa/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uNdv/78u/////////////////////////////////////////////////////////////////////////////78u//2412/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//Tc1f/////////////////lrJz/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJc8baiXK42oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Ggjf/////////////////57Oj/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Sqmf///v3///////////////////////////////////////////////////////////////////79/+Spmf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9uLc/////////////////+Omlf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2ohyuduJcqjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3I96//////////////////77+//ainP/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJ"
	Static 4 = "cv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+m4qv///v3////////////////////////////////////////////////////////+/f/puKr/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/68O3/////////////////4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXOn24hxhdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL//PTy/////////////////96Xg//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Sqmf/78u/////////////////////////////////////////////78u//5KmZ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2413///+/v////////////79/f/bjHX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcoLZinJe2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/2497/////////////////5KiY/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uNdv/qvK//9uLd///+/v/////////////+/f/24t3/6ruu/9uMdv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hnov/////////////////+u7r/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24hyXNqLdDfaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//HTyv/////////////////puqz/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/96Vgf/eloH/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+awoP/////////////////03db/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZiXE24Yd4EdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7MG1/////////////////+/NxP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7MK2/////////////////+/Lwf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9+PcBAAAAAA2oly6dqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/lq5r/////////////////+Onl/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7sm+//HTyv/x08r/8dPK//HTyv/uyb7/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/02tP/////////////////6bmr/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLpAAAAAAAAAADaiXLB2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yQev///v3//////////////v7/3JF7/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/9+fj///////////////////////35+P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2opz//339v/////////////////hnov/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcsAAAAAAAAAAANqKcovaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//jo4//////////////////lrJz/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3JB6/////////////////////////////////9yQev/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hoI7//////////////////PXz/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olyhAAAAAAAAAAA2YhzSdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/78zC/////////////////+7Jvv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/gnIn/////////////////////////////////4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+u+sv/////////////////z2NH/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ai3FEAAAAAAAAAADVgGoM2oly+tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/mr5//////////////////+Ofj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Spmf/////////////////////////////////kqZn/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9NzV/////////////////+m6rf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly+eaAZgoAAAAAAAAAAAAAAADZiXLF2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/92Sff///v3///////////////7/35mF/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6Lao/////////////////////////////////+i2qP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yPef/++vn/////////////////4JyJ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLDAAAAAAAAAAAAAAAAAAAAANqIc4PaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//Xg2//////////////////swbX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/swrf/////////////////////////////////7MK3/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6LWn//////////////////rv7P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcoIAAAAAAAAAAAAAAAAAAAAA2Id0QtqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6biq//////////////////jq5v/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//DPxv/////////////////////////////////wz8b/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/139n/////////////////7ca6/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24d0QAAAAAAAAAAAAAAAAAAAAADVgIAG2olz7NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dkXz//v38/////////////////+Ccif/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Wtnf/bjHb/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9NzV//////////////////////////////////Tc1f/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjHb/5a2d/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3pWA///+/f/////////////////gm4j/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcub/qlUDAAAAAAAAAAAAAAAAAAAAAAAAAADZiXOV2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/03db/////////////////7se9/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Gei//14Nv//////+zBtf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/46OT/////////////////////////////////+Ojk/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+zBtf//////9eDb/+Gei//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/rvrH/////////////////9+fi/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2YhxjgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJcjjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+e0pf/////////////////89/X/3I54/9qJcv/aiXL/2oly/92Sff/wzsX//v39/////////////fn4/96VgP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//z18//////////////////////////////////89fP/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/elYD//fn4/////////////v39//DOxf/dkn3/2oly/9qJcv/aiXL/2op0//rv7P/////////////////qvK//2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ch3MzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJctnaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2413//z18//////////////////qu67/2oly/9uLdP/qvK///ff2////////////////////////////8dTL/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjHb////+/////////////////////////////////////v/bjHb/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//HUy/////////////////////////////339v/qvK//24t0/9qJcv/nsqP//////////////////vv7/92Tfv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly1gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2opxfNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7MS4//////////////////rv7P/ainT/67+y/////////////////////////////////////////v7/4qKQ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9+YhP///////////////////////////////////////////9+YhP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/iopD///7+///////////////////////////////////////rv7L/2olz//jq5v/////////////////wz8X/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXJ7AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADXh3Ag2oly/dqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dk37//vv6/////////////////+awoP/cj3n/+/Px///////////////////////////////////////35eD/2olz/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46WU////////////////////////////////////////////46WU/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olz//fl4P//////////////////////////////////////+/Px/9yPef/lq5v//////////////////v39/9+Zhf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly+96Mcx8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADbiXKv2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/wz8b/////////////////+Onl/9qKc//otKb////////////////////////////////////////////ntKX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/nsqP////////////////////////////////////////////nsqP/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ntKX////////////////////////////////////////////otKb/2oly//fk3//////////////////y1s7/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXKmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANiJcTTaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Cbh////v7/////////////////6biq/9qJc//35uH/////////////////////////////////89nS/9+Zhf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+u+sv///////////////////////////////////////////+u+sv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9+Zhf/z2dL/////////////////////////////////9+bh/9qJc//nsqP////////////////////+/+GfjP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/tiLdC4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANqJcrjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//HSyf/////////////////89fP/3I96/+Kjkf////7/////////////////+Orm/+Onlv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/78vB////////////////////////////////////////////78vB/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/jp5b/+Orm/////////////////////v/io5H/3I95//vz8P/////////////////02tP/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXG0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2YpxPdqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3pWA//35+P/////////////////uyL7/2oly//LUzP///////Pb0/+m5rP/ainT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/z2ND////////////////////////////////////////////z2ND/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ainT/6bms//z29P//////8tTM/9qJcv/uyL3//////////////////vv7/9+Zhf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9iKcDsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2olywtqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7MK2//////////////////78+//fmob/3pWB/+7Kv//ckXv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//fk3/////////////////////////////////////////////fk3//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJ"
	Static 5 = "cv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3JF7/+7Kv//elYH/4JuH//78/P/////////////////txrv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADZiXJD2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjXb/+/Hu//////////////////fm4f/bi3T/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/+/Hu////////////////////////////////////////////+/Hu/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdP/35N//////////////////+/Hu/9uOeP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/tqIcz4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiXGr2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/msaL//////////////////////+3Euf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qKc//+/fz////////////////////////////////////////////+/fz/2opz/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7ca6///////////////////////msKD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXKkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJdhzaiXLz2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/z2ND//////////////////v39/+Kjkf/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3ZR////////////////////////////////////////////////////////dlH//2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Onlf///v3/////////////////9NvU/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2ohy8daFcBkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANqIcnTaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/92RfP/78/D/////////////////+u7r/9yPef/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/hoY7//////////////////////////////////////////////////////+Ghjv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dkn3/+/Pw//////////////////vz8P/dkn3/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/ZiHJyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzJlmBdqJctPaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+SpmP////7/////////////////9N3W/9qKdP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Wunv//////////////////////////////////////////////////////5a6e/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/24t1//Xf2f///////////////////v3/46eV/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly1L+AgAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2ohzPtqJcv3aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+/Mwv//////////////////////783D/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6bqt///////////////////////////////////////////////////////puq3/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/x08r//////////////////////+3Guv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv3aiHM+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2olyiNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2412//fl4P//////////////////////6ruu/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/92Uf//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/tx7z//////////////////////////////////////////////////////+3HvP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dlH//2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/7ca6///////////////////////2497/24t0/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olyggAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC/gIAE24lyxNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3ZN+//rw7f///////////////////v3/5a2d/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/elYD//fn4//LWzv/eloL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+7Jv//68O3/+vDt//rw7f/68O3/+vDt//rw7f/68O3/+vDt//rw7f/68O3/7sm//9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/eloL/8tbO//35+P/elYD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+m4qv//////////////////////+u7r/92Sff/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcsH/qlUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADcjXId2olz7NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/4J2K//349//////////////////+/Pz/5q+f/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//HTyv////////////76+f/sxLj/2413/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjXf/7MS4//76+f////////////HTyv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/otaf//v39//////////////////z18//fmYX/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLr2Y5xGwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiHRL2oly/tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5KqZ//79/f/////////////////+/f3/57Kj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/iopD///7+///////////////////////78e7/57Kj/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/57Kj//vx7v////////////////////////7+/+KikP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6r2w/////v/////////////////9+vn/4qKP/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/tqIdEsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADainKJ2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6LWn///+/f///////////////////v3/6LWn/9qJcv/aiXL/2oly/9qJcv/aiXL/2olz//fl3///////////////////////////////////////89jQ/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//PY0P//////////////////////////////////////9+Xf/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/+3Fuv///////////////////////v39/+Wsm//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXKIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP+AgALbiXKo2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/57Sl///+/f///////////////////v7/7MO3/9qJc//aiXL/2oly/9qJcv/ntKX////////////////////////////////////////////otKb/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/6LSm////////////////////////////////////////////57Sl/9qJcv/aiXL/2oly/9uLdP/wzsX///////////////////////77+//lrp7/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2opypf//AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAgAbaiHO72oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5rCh//79/P//////////////////////9NrT/9yPef/aiXL/3I54//vy8P//////////////////////////////////////9+bh/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXP/9+bh///////////////////////////////////////78vD/3I54/9qJcv/eloH/9uTe///////////////////////9+fj/46eW/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qIcrnMmWYFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAagzainLM2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/5a6e//78+///////////////////////+ezo/+CbiP/el4P/9uPe/////////////////////////////////////v/io5H/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/io5H////+//////////////////////////////////bj3v/el4P/5KqZ//z18////////////////////////Pb0/+Kij//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXLL1YBqDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuGbRXaiXHa2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/46aV//z18////////////////////////fn3/+m4qv/aiXL/57Kj//vx7v//////////////////////8tTM/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/wzsT/9uHc//bh3P/24dz/9uHc//bh3P/24dz/8M7E/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/y1Mz///////////////////////vx7v/nsqP/24t1/+3HvP///v7///////////////////////vx7v/gnIn/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olx2tuGbRUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAN6Mcx/aiXHa2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3paC//fn4v////////////////////////////bh2//fmYX/2413/+zEuP/++vn///////36+f/elYH/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//fl4P/////////////////////////////////35eD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/96Vgf/9+vn///////76+f/sxLj/2413/+Onlv/57On////////////////////////////03Nb/3ZF8/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcdrejHMfAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANyLdBbbiXLL2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2412//HTyv////////////////////////////76+f/rvrL/2op0/96Wgv/y1s7/7MK3/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9+Xg//////////////////////////////////fl4P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+zCt//y1s7/3paC/92Uf//y1c3////////////////////////////+/f3/68C0/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/biXLL24ZtFQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAagzaiHO72oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+m5rP/9+fj////////////////////////////57en/57Kj/9qJc//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/35eD/////////////////////////////////9+Xg/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9yQev/swbX//fj3////////////////////////////+/Pw/+Olk//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olyutWAagwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANWAgAbbiXKo2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9+YhP/139j/////////////////////////////////+evn/+avn//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//fl4P/////////////////////////////////35eD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/92Sff/txrv//fj2//////////////////////////////7+//DPxv/ckXv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcqbMmWYFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP+AgALaiXKI2oly/tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/otaf//ff2//////////////////////////////////jp5f/puqz/3JB6/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/9+Xg//////////////////////////////////fl4P/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Cdiv/vzML//vr5//////////////////////////////////jn4//iopD/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv7aiXKI//8AAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADaiHRL2olz7NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dlH//8dHI//79/f/////////////////////////////////++/r/8dTL/+OllP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/35eD/////////////////////////////////9+Xg/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/3pWA/+u+sv/46eT///////////////////////////////////////339v/qu63/2op0/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLr2oh0SwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADcjXId24lyxNqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/35qG//LUzP///v3///////////////////////////////////////vx7v/w0cj/5rGi/9yRe//aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly//DOxP/24dz/9uHc//bh3P/24dz/9uHc//bh3P/wzsT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uLdf/ipJL/7MK2//bh2////v3///////////////////////////////////////z18//rwbT/3I96/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olywdmOcRsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC/gIAE2olyiNqJcv7aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+Ccif/z2ND///7+//////////////////////////////////////////////7+//fm4f/uysD/6biq/+KikP/ckHv/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9uOeP/hn4z/5rCg/+zDuP/13tj//fr5//////////////////////////////////////////////////vy7//qvK//2413/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/NqJcoL/qlUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
	Static 6 = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2ohzPtqJctTaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/eloL/7MO4//vx7v/////////////////////////////////////////////////////////////////89PL/9uLd//bh3P/x08r/8dPK/+7Jvv/sxLj/7se9//HTyv/x08r/9N3X//bh3P/78/D//////////////////////////////////////////////////////////////////v39//Td1v/nsqP/24x1/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJctTZinE9AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAv4CABNqIcnTaiXLz2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2olz/+Spmf/z2ND//vr5////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////9+bi/+q8r//dk37/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qIcvHZiHJyv4CABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJdhzaiXGr2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/bjXb/5KiX/+7Ivv/46eX///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////vy8P/y1Mz/6Lao/9+YhP/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXKk1oVwGQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADZiXJD2olywtqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/dlH//5rCg/+zEuP/z2ND/+Orm//78+/////////////////////////////////////////////////////////////////////////7+//nt6f/03NX/78vB/+i3qf/fmob/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLC2ohzPgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA2YpxPdqJcrjaiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/+CciP/jp5X/46eV/+i1p//otaf/67+z/+zEuP/rwbT/6LWn/+i1p//lq5r/46eV/+CciP/ainT/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXKz2IpwOwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANiJcTTbiXKv2oly/tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcvvaiXKm2It0LgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADejHMf2opxfNqJcdraiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qKctfainF83YhvHgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAANuJcjjZiXOV2olz7NqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly5tmIcY7ch3MzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVgIAG2Id0QtqIc4PZiXLF2oly+tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcvnaiXLD2ohzg9yJckH/qlUDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADVgGoM2YhzSdqJc4raiXLC2oly6tqJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXL/2oly/9qJcv/aiXLq2opxv9qJcoTai3FE5oBmCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA349wENmJcTbZinJe2Ypxh9qKcqXainG/2opxv9qJctbaiXLf2oly5tqJcv/aiXL/2Yly59qJct/aiXPY2opxv9qKcb/ZiXOp2olyhNqIcVrZh3M1349wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA////////+AAAH////////////////wAAAAD///////////////AAAAAAD//////////////AAAAAAAP////////////+AAAAAAAAf///////////+AAAAAAAAB///////////+AAAAAAAAAH//////////+AAAAAAAAAAf/////////+AAAAAAAAAAB/////////+AAAAAAAAAAAH/////////AAAAAAAAAAAA/////////AAAAAAAAAAAAD////////gAAAAAAAAAAAAf///////wAAAAAAAAAAAAD///////wAAAAAAAAAAAAAP//////4AAAAAAAAAAAAAB//////8AAAAAAAAAAAAAAP/////+AAAAAAAAAAAAAAB//////AAAAAAAAAAAAAAAP/////gAAAAAAAAAAAAAAB/////wAAAAAAAAAAAAAAAP////4AAAAAAAAAAAAAAAB////8AAAAAAAAAAAAAAAAP////AAAAAAAAAAAAAAAAD////gAAAAAAAAAAAAAAAAf///wAAAAAAAAAAAAAAAAD///4AAAAAAAAAAAAAAAAAf//+AAAAAAAAAAAAAAAAAH///AAAAAAAAAAAAAAAAAA///gAAAAAAAAAAAAAAAAAH//4AAAAAAAAAAAAAAAAAB//8AAAAAAAAAAAAAAAAAAP//AAAAAAAAAAAAAAAAAAD//gAAAAAAAAAAAAAAAAAAf/4AAAAAAAAAAAAAAAAAAH/8AAAAAAAAAAAAAAAAAAA//AAAAAAAAAAAAAAAAAAAP/gAAAAAAAAAAAAAAAAAAB/4AAAAAAAAAAAAAAAAAAAf8AAAAAAAAAAAAAAAAAAAD/AAAAAAAAAAAAAAAAAAAA/wAAAAAAAAAAAAAAAAAAAP4AAAAAAAAAAAAAAAAAAAB+AAAAAAAAAAAAAAAAAAAAfAAAAAAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAPAAAAAAAAAAAAAAAAAAAADgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAGAAAAAAAAAAAAAAAAAAAABgAAAAAAAAAAAAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAHAAAAAAAAAAAAAAAAAAAADwAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAPAAAAAAAAAAAAAAAAAAAAD4AAAAAAAAAAAAAAAAAAAB+AAAAAAAAAAAAAAAAAAAAfwAAAAAAAAAAAAAAAAAAAP8AAAAAAAAAAAAAAAAAAAD/AAAAAAAAAAAAAAAAAAAA/4AAAAAAAAAAAAAAAAAAAf+AAAAAAAAAAAAAAAAAAAH/wAAAAAAAAAAAAAAAAAAD/8AAAAAAAAAAAAAAAAAAA//gAAAAAAAAAAAAAAAAAAf/4AAAAAAAAAAAAAAAAAAH//AAAAAAAAAAAAAAAAAAD//wAAAAAAAAAAAAAAAAAA//+AAAAAAAAAAAAAAAAAAf//gAAAAAAAAAAAAAAAAAH//8AAAAAAAAAAAAAAAAAD///gAAAAAAAAAAAAAAAAB///4AAAAAAAAAAAAAAAAAf///AAAAAAAAAAAAAAAAAP///4AAAAAAAAAAAAAAAAH////AAAAAAAAAAAAAAAAD////wAAAAAAAAAAAAAAAA////+AAAAAAAAAAAAAAAAf////wAAAAAAAAAAAAAAAP////+AAAAAAAAAAAAAAAH/////wAAAAAAAAAAAAAAD/////+AAAAAAAAAAAAAAB//////wAAAAAAAAAAAAAA//////+AAAAAAAAAAAAAAf//////wAAAAAAAAAAAAAP///////AAAAAAAAAAAAAP///////4AAAAAAAAAAAAH////////AAAAAAAAAAAAD////////8AAAAAAAAAAAD/////////gAAAAAAAAAAB/////////+AAAAAAAAAAB//////////4AAAAAAAAAB///////////gAAAAAAAAB///////////+AAAAAAAAB////////////4AAAAAAAB/////////////wAAAAAAD//////////////AAAAAAD///////////////AAAAAP////////////////gAAB////////8="
	
	If (!HasData)
		Return -1
	
	If (!ExtractedData){
		ExtractedData := True
		, Ptr := A_IsUnicode ? "Ptr" : "UInt"
		, VarSetCapacity(TD, 92676 * (A_IsUnicode ? 2 : 1))
		
		Loop, 6
			TD .= %A_Index%, %A_Index% := ""
		
		VarSetCapacity(Out_Data, Bytes := 67646, 0)
		, DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &TD, "UInt", 0, "UInt", 1, Ptr, &Out_Data, A_IsUnicode ? "UIntP" : "UInt*", Bytes, "Int", 0, "Int", 0, "CDECL Int")
		, TD := ""
	}
	
	IfExist, %_Filename%
		FileDelete, %_Filename%
	
	h := DllCall("CreateFile", Ptr, &_Filename, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
	, DllCall("WriteFile", Ptr, h, Ptr, &Out_Data, "UInt", 67646, "UInt", 0, "UInt", 0)
	, DllCall("CloseHandle", Ptr, h)
	
	If (_DumpData)
		VarSetCapacity(Out_Data, 67646, 0)
		, VarSetCapacity(Out_Data, 0)
		, HasData := 0
}

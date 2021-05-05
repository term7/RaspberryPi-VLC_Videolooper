# RaspberrPi_VLC_Videolooper
*A Videolooper based on VLC for the Raspberry Pi*

## INTRODUCTION

This Videolooper is designed to use the commandline interface of the VLC Player, which is included in the standard installation of Raspberry Pi OS. In the past VLC did not support Hardware acceleratinon on the Raspberry Pi, which is why other Videolooper Projects for the Raspberry Pi use the OMXplayer instead. However this has changed. Harware acceleration and VLC is no issue anmore which is why we decided to develop a Videolooper based on VLC for the Raspberry Pi.

This Videolooper has been tested on the Raspberry Pi 2B, 3B, 3B+ and 4B.
To setup this Videolooper, follow these instuctions step by step. Feel free to make your own adjustments according to your own needs.


### WHAT THIS VIDEOLOOPER DOES:

After the successful implementation of these instruction, when you boot your Raspberry Pi, it will look for all video files stored in an autoplay folder, add them to a playlist and loop this playlist indefinitely. Furthermore it will look for attached USB drives, search them for video files and add them to the playlist. The USB drive can either already be attached to the Raspberry Pi when it boots up, or be plugged in while the first video (or no video at all) is already playing. In any case the Videolooper will add all video files found on the USB drive to the playlist and play loop.


## SETUP

- [01 - Prerequisite](#01---Prerequisite)
- [02 - Setup unprivileged Workstation User](#02---Setup-unprivileged-Workstation-User)
- [03 - Prepare Desktop Environment](#03---Adjust-Desktop-Environment)
- [04 - Prepare Folders and Locations](#04---Prepare-Folders-and-Locations)
- [05 - Setup USB Stick Handler and Service](#05---Setup-Autoplay-Service)
- [06 - The Autoplay Script](#06---Bitrate-presets-to-reduce-file-size-for-Vimeo-or-Youtube)
- [07 - Setup Autoplay Service](#07---Setup-Autoplay-Service)
- [08 - Links and Resources](#08---Links-and-Resources)


# 01 - Prerequisite

We recommend you work with a clean install of [Raspberry Pi OS](https://www.raspberrypi.org/software/operating-systems/) with desktop (without recommended software, unless you intend to use it). You could also start with a minimal installation of Raspberry Pi OS Lite. However, some additional packages that are not covered in this guide will have to be installed for this Videolooper to work on Raspberry Pi OS Lite.


# 02 - Setup unprivileged Workstation User

We have been using this Videolooper on a Raspberry Pi that had to be reachable via SSH over the internet, which is why we set up an unprivileged user account called *workstation* to run our autoplay script.
But first we grant our new user also admin rights. This makes it easy to change all required settings, so in future our Raspberry Pi will automatically log in as *workstation*. We will revoke admin rights later.

To create this user with all privileges, log into your Raspberry Pi via SSH and execute the following commands (you will be asked to create a password for your new user):

`sudo adduser workstation`<br>
`sudo usermod -a -G adm,tty,pi,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi,sudo workstation`

Then log into your new user account:<br>
`su - workstation`

Once you are logged in, change the autologin settings in */etc/lightdm/lightdm.conf*:<br>
`sudo nano /etc/lightdm/lightdm.conf`

Find the line that says `autologin-user=pi` and change it to `autologin-user=workstation`

Also change `pi` to `workstation` in  */etc/systemd/system/autologin@.service*:<br>
`sudo nano /etc/systemd/system/autologin@.service`

Finally to make absolutely sure your new user will be logged in on boot run:

`sudo raspi-config`

Navigate to *1 System Options* and select *Boot / Auto login*. Make sure you select user *workstation* to automatically log into desktop.
Please note that [raspi-config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md) is constantly being developed. The location of the required menu item might change!
Then, reboot your Raspberry Pi. You should now be logged into your desktop environment as *workstation*.

Finally, either log again into your Raspberry Pi via SSH, or use a terminal window to log into the *pi* user account:<br>
`su - pi`

To revoke admin rights for *workstation* execute the following command:<br>
`sudo usermod -a -G adm,tty,pi,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi workstation`

Reboot your Raspberry Pi. You should now still be logged into your desktop environment as *workstation*.

To douple-check that the group `sudo` is missing from the list of groups run this command in a terminal window:<br><br>
`groups workstation`

# 03 - Prepare Desktop Environment

VLC briefly shows the desktop when it reloads the playlist loop, which is why we want to hide all elements that are present on the desktop.
There are several settings that you can change:

- Right-click on the top menubar and change the settings to autohide the menubar. Also change its size to 0px (2px is set as default, which will be visible as a thin line on top of your screen)
- Right-click on the desktop to change the desktop settings. Select no background as desktop background and change the background color to black. Also hide all items that are visible on your desktop (i.e. untick the option that shows the Wastebasket, USB Drives, etc.)
- Open the file manager and in its advanced settings disable all popup notifications for when a USB drive is inserted

To automatically hide the mouse cursor log into you admin account (*pi*) and install unclutter:
`sudo apt install unclutter`



## MIT License

Copyright (c) 2021 term7

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

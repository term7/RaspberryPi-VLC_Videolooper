# RaspberrPi_VLC_Videolooper
*A Videolooper based on VLC for the Raspberry Pi*

## INTRODUCTION

This Videolooper is designed to use the commandline interface of the VLC Player, which is included in the standard installation of Raspberry Pi OS. In the past VLC did not support Hardware acceleratinon on the Raspberry Pi, which is why other Videolooper Projects for the Raspberry Pi use the OMXplayer instead. However this has changed. Harware acceleration and VLC is no issue anmore which is why we decided to develop a Videolooper based on VLC for the Raspberry Pi.

This Videolooper has been tested on the Raspberry Pi 2B, 3B, 3B+ and 4B.
To setup this Videolooper, follow these instuctions step by step. Feel free to make your own adjustments according to your own needs.

In future we might write a script that does the whole setup automatically. However we think it is fun to learn, which is why we decided to write a detailed guide instead.
;-)


### WHAT THIS VIDEOLOOPER DOES:

After the successful implementation of these instruction, when you boot your Raspberry Pi, it will look for all video files stored in an autoplay folder, add them to a playlist and loop this playlist indefinitely. Furthermore it will look for attached USB drives, search them for video files and add them to the playlist. The USB drive can either already be attached to the Raspberry Pi when it boots up, or be plugged in while the first video (or no video at all) is already playing. In any case the Videolooper will add all video files found on the USB drive to the playlist and play loop.


## SETUP

- [01 - Prerequisite](#01---Prerequisite)
- [02 - Setup unprivileged Workstation User](#02---Setup-unprivileged-Workstation-User)
- [03 - Prepare Desktop Environment](#03---Adjust-Desktop-Environment)
- [04 - Prepare Folders and Locations](#04---Prepare-Folders-and-Locations)
- [05 - Setup USB Device Handler and Service](#05---Setup-USB-Device-Handler-and-Service)
- [06 - VLC Autoplay Script](#06---VLC-Autoplay-Script)
- [07 - VLC Autoplay Service](#07---VLC-Autoplay-Service)
- [08 - Links and Resources](#08---Links-and-Resources)


# 01 - Prerequisite

We recommend you work with a clean install of [Raspberry Pi OS](https://www.raspberrypi.org/software/operating-systems/) with desktop (without recommended software, unless you intend to use it). You could also start with a minimal installation of Raspberry Pi OS Lite. However, some additional packages that are not covered in this guide will have to be installed for this Videolooper to work on Raspberry Pi OS Lite.


# 02 - Setup unprivileged Workstation User

We have been using this Videolooper on a Raspberry Pi that had to be reachable via SSH over the internet, which is why we set up an unprivileged user account called *workstation* to run our autoplay script. But first we grant our new user also admin rights. This makes it easy to change all required settings, so in future our Raspberry Pi will automatically log in as *workstation*. We will revoke admin rights later.

SIDE NOTE: This is a security related precaution and we strongly recommend you run the Vidolooper in an unprivileged user account if your Raspberry Pi is exposed to the internet. Then you should also consider to set up a firewall and to harden your SSH login configuration. 

To create the user *workstation* with all privileges, log into your Raspberry Pi via SSH and execute the following commands (you will be asked to create a password for your new user):

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

To douple-check that the group *sudo* is missing from the list of groups run this command in a terminal window:<br>
`groups workstation`


# 03 - Prepare Desktop Environment

VLC briefly shows the desktop when it reloads the playlist loop, which is why we want to hide all elements that are present on the desktop.
There are several settings that you can change:

- Right-click on the top menubar and change the settings to autohide the menubar. Also change its size to 0px (2px is set as default, which will be visible as a thin line on top of your screen)
- Right-click on the desktop to change the desktop settings. Select no background as desktop background and change the background color to black. Also hide all items that are visible on your desktop (i.e. untick the option that shows the Wastebasket, USB Drives, etc.)
- Open the file manager and in its advanced settings disable all popup notifications for when a USB drive is inserted
- To automatically hide the mouse cursor log into you admin account *pi* and install unclutter:<br>
`su - pi`<br>
`sudo apt install unclutter`


# 04 - Prepare Folders and Locations

Most steps during the following setup require admin rights, which is why you should remain logged in as an admin user. Some folders that we use as locations for our Videolooper do not exist after a fresh installation of Raspberry Pi OS. We need to create them:

`mkdir /home/workstation/Videos/autoplay`<br>
`mkdir /home/workstation/Script`<br>
`mkdir /media/workstation`

The last folder will be generated automatically once you insert a USB-drive. We only create this folder manually to avoid an error in case you don't insert a USB-drive before the Videolooper is started for the first time.


# 05 - Setup USB Device Handler and Service

We need to enable our Videolooper to know when a USB-drive is inserted. To do so, we first define a new [udev rule](https://en.wikipedia.org/wiki/Udev):<br>
`sudo nano /etc/udev/rules.d/usb_hook.rules`

Insert:
```
ACTION=="add", KERNEL=="sd[a-z][0-9]", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k"
```

Now we create a [systemd service](https://www.freedesktop.org/wiki/Software/systemd/), that monitors when a USB device is plugged in and that defines what happens, once a USB drive is inserted. <br>
`sudo nano /lib/systemd/system/usbstick-handler@.service`

Insert:

```
[Unit]
Description=Mount USB sticks
BindsTo=dev-%i.device
After=dev-%i.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/automount /dev/%I
```

The executed function has to be very short, because udev does kill longer running scripts that have been started by a udev rule. If we wanted to execute our autoplay script directly via this systemd service, it would not work.
Thus we came up with this workaround: we use our function to modify a file on our harddisk. Further we watch this file with inotify, another monitoring tool, that will in turn start our VLC-Videolooper once this file has been modified.

First we install inotify:<br>
`sudo apt install inotify`

Then we create our short function:<br>
`sudo nano /usr/local/bin/automount`

Insert:

```
#!/bin/bash

export mnt=/home/workstation/Script/.mnt
find /dev/sd* | sed -n '1~2!p' | sed ':a;N;$!ba;s/\n/ /g' > "$mnt"
```

This simple function just writes the SCSI disk identifier of the inserted USB devices to a temporary log file (.mnt). Each time a USB device is inserted this file will be overwritten.

Finally we need to make this script executable:<br>
`sudo chmod +x /usr/local/bin/automount`


# 06 - VLC Autoplay Script

Now we create the actual script that uses inotify as a trigger, creates a playlist and launches VLC to play the loop. In this script you can define all paramaters and all options that the [VLC command line](https://wiki.videolan.org/VLC_command-line_help/) has to offer. For example: we only want to play MP4, MOV and MKV files. What if you want to play an AVI? Just edit this script and add it to the list of filetypes that you want to play. Perhaps you want to rotate the video in your screen, mute the video or play a slideshow of images instead? Here you can add the required parameters. There are a lot of possibilities:

`sudo nano /home/workstation/autoplay.sh`

Insert:

```
#!/bin/sh

# VLC OPTIONS:
# View all possible options: vlc -H

# Specify file paths and playlist location to be used for playback
export USB=/media/workstation
export AUTOPLAY=/home/workstation/Videos/autoplay
export PLAYLIST=/home/workstation/Videos/autoplay/playlist.m3u
export mnt=/home/workstation/Script/.mnt

FILETYPES="-name *.mp4 -o -name *.mov -o -name *.mkv"

# Playlist Options

Playlist_Options="-L --started-from-file --one-instance --playlist-enqueue"

#Additional Playlist Options

#      --one-instance, --no-one-instance
#                                 Allow only one running instance
#                                 (default disabled)
#          Allowing only one running instance of VLC can sometimes be useful,
#          for example if you associated VLC with some media types and you don't
#          want a new instance of VLC to be opened each time you open a file in
#          your file manager. This option will allow you to play the file with
#          the already running instance or enqueue it.
#      --playlist-enqueue, --no-playlist-enqueue
#                                 Enqueue items into playlist in one instance
#                                 mode
#                                 (default disabled)
#          When using the one instance only option, enqueue items to playlist
#          and keep playing current item.

# Output Modules

Video_Output="--gles2 egl_x11 --glconv mmal_converter --mmal-opaque"
Audio_Output="--stereo-mode 2"

# Interface Options
# Fullscreen, hide title display, decorations, window borders, etc.

Interface_Options="-f --no-video-title-show"

# Some useful Video Filters for Special Occacions:

# Mirror video filter (mirror)
# Splits video in two same parts, like in a mirror
#      --mirror-split {0 (Vertical), 1 (Horizontal)}
#                                 Mirror orientation
#          Defines orientation of the mirror splitting. Can be vertical or horizontal.
#      --mirror-direction {0 (Left to right/Top to bottom), 1 (Right to left/Bottom to top)}

#VLC AUTOMATIC FULLSCREEN LOOP:

# When a USB is plugged in at startup or before the Raspberry Pi is booted, Inotify is not yet ready to notice
# filechanges in the watchfile, which is why we run an see if there are playable files once  at boot and start
# the watch script afterwards:

sleep 10;
echo "#EXTM3U" > "$PLAYLIST";
find "$USB" -type f \( $FILETYPES \)  >> "$PLAYLIST";
find "$AUTOPLAY" -type f \( $FILETYPES \)  >> "$PLAYLIST";
sed -i '/\/\./d' "$PLAYLIST";
sed -i '2,$s/^/file:\/\//' "$PLAYLIST";
sleep 0.1;
if [ "$(wc -l < /home/workstation/Videos/autoplay/playlist.m3u )" != "1" ]; then
    /usr/bin/cvlc -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
fi


# Start WatchScript:

while /usr/bin/inotifywait -e modify "$mnt"; do
    sleep 10;
    echo "#EXTM3U" > "$PLAYLIST";
    find "$USB" -type f \( $FILETYPES \)  >> "$PLAYLIST";
    find "$AUTOPLAY" -type f \( $FILETYPES \)  >> "$PLAYLIST";
    sed -i '/\/\./d' "$PLAYLIST";
    sed -i '2,$s/^/file:\/\//' "$PLAYLIST";
    sleep 0.1;
    if [ "$(wc -l < /home/workstation/Videos/autoplay/playlist.m3u )" != "1" ]; then
        /usr/bin/cvlc -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
    fi
done
```

Also this script needs to be executable:<br>
`sudo chmod +x /home/Script/autoplay.sh`


# 07 - VLC Autoplay Service

Finally we need to create another systemd service that runs our VLC Autoplay Script at boot:<br>
`sudo nano /lib/systemd/system/autoplay.service`

Insert:

```
[Unit]
Description=Autoplay
After=multi-user.target

[Service]
WorkingDirectory=/home/workstation
User=workstation
Group=workstation
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/home/workstation/.Xauthority"
Environment="XDG_RUNTIME_DIR=/run/user/1001"
ExecStart=/bin/sh /home/workstation/Script/autoplay.sh

[Install]
WantedBy=graphical.target
```

Doublecheck if the XDG_RUNTIME_DIR is correct (if it is not correct, the script will exit with an error). It should be 1001. However, if for example it turns out to be 1002 while you are logged in as *workstation*, change your systemd service accordingly:<br>
`su workstation`<br>
`id -u`

Finally, we enable and start the VLC autoplay service with the following commands (you need to be logged in as an administrator to execute these commands):

`sudo systemctl daemon-reload`<br>
`sudo systemctl enable autoplay.service`<br>
`sudo systemctl start autoplay.service`

If you get an error you can try:<br>
`sudo systemctl reset-failed`

Now all you have to do is to transfer one or more video files to /home/workstation/Videos/autoplay and/or insert a USB-drive that contains your files and watch the VLC Videolooper start the loop.

# 08 - Links and Resources

Raspberry Pi OS:
[Download Raspberry Pi OS](https://www.raspberrypi.org/software/operating-systems/)
[Install Raspberry Pi OS](https://www.raspberrypi.org/software/)
[Documentation Raspi-Config](https://www.raspberrypi.org/documentation/configuration/raspi-config.md)


## MIT License

Copyright (c) 2021 term7

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# RaspberryPi VLC_Videolooper
*Videolooper based on VLC for the Raspberry Pi - Raspberry Pi OS (Lite)*

## INTRODUCTION

This Videolooper is designed to use the commandline interface of the VLC Player. In the past VLC did not support hardware acceleratinon on the Raspberry Pi, which is why older Videolooper Projects for the Raspberry Pi use the OMXplayer instead. However this has changed. Harware acceleration and VLC is not an issue anmore, which is why we decided to develop a Videolooper based on VLC for the Raspberry Pi.

This Videolooper has been tested on the Raspberry Pi 2B, 3B, 3B+ and 4B.
To setup this Videolooper, follow these instuctions step by step. Feel free to make your own adjustments according to your own needs.

We think it is fun to learn, which is why we decided to write a detailed guide instead. ;-)


### WHAT THIS VIDEOLOOPER DOES:

After the successful implementation of these instruction, when you boot your Raspberry Pi, it will look for all video files stored in an autoplay folder, add them to a playlist and loop this playlist indefinitely. Furthermore it will look for attached USB drives, search them for video files and add them to the playlist. The USB drive has to be attached to the Raspberry Pi when it boots up. The autoplay script can easily be tweaked to accomodate a wide variety of VLC command line options.


## SETUP

- [01 - Prerequisites](#01-prerequisites)
- [02 - Setup unprivileged Workstation User](#02-setup-unprivileged-workstation-user)
- [03 - Prepare Folders and Locations](#03-prepare-folders-and-locations)
- [04 - Setup USB Device Handler and Service](#04-setup-usb-device-handler-and-service)
- [05 - VLC Autoplay Service](#05-vlc-autoplay-service)
- [06 - VLC Autoplay Script](#06-vlc-autoplay-script)
- [07 - Links and Resources](#07-links-and-resources)


# 01 - Prerequisites

We recommend you work with a clean and fully updated installation of [Raspberry Pi OS Lite](https://www.raspberrypi.org/software/operating-systems/). We also recommend you create separate accounts for your standard user without sudo privileges and an admin account with sudo privileges. We have written a tutorial on our blog that covers our usual first time setup steps: [HEADLESS SETUP: basic configuration of a Raspberry Pi + hardened SECURITY](https://term7.info/intro-raspberry-pi/)

If you follow this tutorial first, installing the Videolooper will be easy.


# 02 - Setup unprivileged Workstation User

Often we have been using this Videolooper on a Raspberry Pi that also had to be reachable via SSH over the internet, which is why we set up an unprivileged user account. For this guide we use a standard user account called *looper* to run our autoplay script. Next we create an *admin* account that runs all privileged processes, including the installation of required software packages. This makes it easy to change all video settings in our standard user account without needing admin rights.

SIDE NOTE: Running the Videolooper in an unprivileged user account is a precaution related to [security](https://term7.info/intro-raspberry-pi/#SSH-SECURITY) and we strongly recommend you follow this setup if your Raspberry Pi is exposed to the internet. You should also consider to set up a [firewall](https://term7.info/intro-raspberry-pi/#FIREWALL) and set up [fail2ban](https://term7.info/intro-raspberry-pi/#FAIL2BAN). 

To create the *admin* user with all privileges, log into your Raspberry Pi via SSH and execute the following commands (you will be asked to create a password for your new user):

`sudo adduser admin`<br>
`sudo usermod -a -G adm,tty,dialout,cdrom,audio,video,plugdev,games,users,input,netdev,gpio,i2c,spi,sudo,looper admin`

Next, replace your standard user with *admin* in /etc/sudoers.d/010_pi-nopasswd:<br>
`sudo nano /etc/sudoers.d/010_pi-nopasswd`

Edit the file to look like this:<br>
`admin ALL=(ALL) NOPASSWD: ALL`

Then log into your new user account:<br>
`su - admin`

Remove your standard user *looper* from the sudo group:<br>
`sudo deluser looper sudo`

Reboot your Raspberry Pi and log back in via SSH.

To douple-check that the group *sudo* is missing from the list of groups run this command in a terminal window:<br>
`groups looper`


# 03 - Prepare Folders and Locations

Most steps during the installation require admin rights. But before we log into the *admin* account we create folder locations that will be used by our VLC Videolooper:

`mkdir ~/Videos && mkdir ~/Videos/autoplay`<br>
`mkdir ~/home/workstation~/Script`


# 04 - Setup USB Device Handler and Service

Raspberry Pi OS Lite doesn't automatically mount USB storage media by default. Since we want to be able to autoplay files from a USB drive, our next step is to enable this behavior. With a [udev](https://en.wikipedia.org/wiki/Udev) rule, [systemd](https://www.freedesktop.org/wiki/Software/systemd/) service, and a mount script, we can ensure that any attached USB stick is not just mounted at boot, but also assigned a predictable mount point.

First, log into you admin account:<br>
`su admin`

Then install required software package:<br>
`sudo apt install pmount`

Next, we create the required UDEV rule:<br>
`sudo nano /etc/udev/rules.d/usb_hook.rules`

Insert:
```
ACTION=="add", KERNEL=="sd[a-z][0-9]", TAG+="systemd", ENV{SYSTEMD_WANTS}="usbstick-handler@%k"
```

Now we create a [systemd service](https://www.freedesktop.org/wiki/Software/systemd/), that monitors when a USB device is plugged in and that defines what happens, once a USB drive is inserted: <br>
`sudo nano /lib/systemd/system/usbstick-handler@.service`

Insert:

```
[Unit]
[Unit]
Description=Automount USB drives
BindsTo=dev-%i.device
After=dev-%i.device systemd-udev-trigger.service systemd-udev-settle.service

[Service]
Type=oneshot
ExecStart=/home/admin/script/automount/usbmount /dev/%I
ExecStop=sync && /usr/bin/pmount /dev/%I

[Install]
WantedBy=multi-user.target
```

The executed script has to be very short, because udev does kill longer running scripts. Again, prepare the folder locations that we will use:<br>
`mkdir ~/script && mkdir ~/script/automount`

Write a script for the required mount points. Most Raspberry Pi's have 4 USB ports, so we define 4 mountpoints:<br>
`sudo nano ~/script/automount/usbmount`

Insert:

```
#!/bin/bash

# Add a small delay to ensure the USB device is fully initialized
sleep 2

for i in {1..4}; do
    if ! mountpoint -q /media/usb$i; then
        /usr/bin/pmount --umask 000 --noatime -w --sync $1 usb$i
        exit 0
    fi
done

echo "No mountpoints available!"
exit 1

```

Make the script executable:<br>
`sudo chmod +x /usr/local/bin/automount`


Sometimes you may want to play files that are larger than 4GB which is the file size limit for USB devices that are FAT32. You can get around this file size limit if you format your USB device using EXFAT. However, in order to add support for EXFAT on your Raspberry Pi, you have to install the following software package:

`sudo apt install exfat-fuse`

You can reboot your Raspberry Pi now and plug in a USB drive. After the reboot SSH into your Raspberry Pi and check if you can access its contents under /media/usb1:

`ls /media/usb1`

If you see usb1 and its content, then your USB drive has been automatically mounted successfully and you are good to proceed! Otherwise retrace your previous steps and double-check your installation for mistakes.

# 05 - VLC Autoplay Service

Finally it is time to set up your Videolooper!

First log into your admin account and install the video player. We use VLC because it supports hardware acceleration, it does not need a graphical user interface (GUI) and it can be controlled via the command line (our autoplay script):<br>
`sudo apt install vlc`

We again need to create a system service that starts out Videolooper after every reboot:<br>
`sudo nano /lib/systemd/system/autoplay.service`

Insert:

```
[Unit]
Description=Autoplay
After=multi-user.target

[Service]
WorkingDirectory=/home/looper     
User=looper
Group=looper
Environment="DISPLAY=:0"
ExecStart=/bin/sh /home/looper/Script/autoplay.sh

[Install]
WantedBy=multi-user.target
```

Finally, we enable the VLC autoplay service with the following command:

`sudo systemctl enable autoplay.service`

Don't start the service yet. It will automatically start with the next reboot, but we have not yet created the VLC autoplay script!

# 06 - VLC Autoplay Script

For the next steps, make sure you are looged into your standard user account: in this example *looper*. If you named your standard user differently, please make sure you adjust the system service script and the folder paths in the autoplay script accordingly. If you are still logged into your *admin* account, type the following command to log out:

`exit`

Now we create the actual script that uses inotify as a trigger, creates a playlist and launches VLC to play the loop. In this script you can define all paramaters and all options that the [VLC command line](https://wiki.videolan.org/VLC_command-line_help/) has to offer. For example: we only want to play MP4, MOV and MKV files. What if you want to play an AVI? Just edit this script and add it to the list of filetypes that you want to play. Perhaps you want to rotate the video in your screen, mute the video or play a slideshow of images instead? Here you can add the required parameters. There are a lot of possibilities:

`sudo nano ~/home/workstation~/Script/autoplay.sh`

Insert the following content:

```
#!/bin/sh

# VLC OPTIONS:
# View all possible options: vlc -H

export AUTOPLAY=/home/looper/Videos/autoplay
export USB=/media/
export PLAYLIST=/home/looper/Videos/playlist.m3u

# Video Filetypes (you can add more filetypes):

FILETYPES="-name *.mp4 -o -name *.mov -o -name *.mkv"

# Playlist Options:
Playlist_Options="-L --started-from-file --one-instance --playlist-enqueue"

# Output Modules (edit to add options):
Video_Output=""

# Audio Options:
Audio_Output="--stereo-mode 1"

# Interface Options:
Interface_Options="-f --loop --no-video-title-show"


# Create Playlist File
# COMMENT: change sleep to 3 if you only want to play from the internal disk to start playback earlier, 25 is only necessary in order to find the USB drive after the Pi boots up, because otherwise the script may start before the USB drive is mounted and no files will be added from USB!

sleep 25
# Create Playlist File
echo "#EXTM3U" > "$PLAYLIST"
find "$AUTOPLAY" ! -iname ".*" -type f \( $FILETYPES \) 2>/dev/null >> "$PLAYLIST"
find "$USB" ! -iname ".*" -type f \( $FILETYPES \) 2>/dev/null >> "$PLAYLIST"

# Play Playlist if Files Exist
if [ -s "$PLAYLIST" ]; then
   /usr/bin/vlc -I dummy -q $Video_Output $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
else
   echo "No files found to play."
fi
```

Also this script needs to be executable:<br>
`chmod +x ~/Script/autoplay.sh`

You can now test your Videolooper!

Prepare some files on a USB media storage and/or use this command to transfer a file from your computer to the autoplay folder of your Raspberry Pi (adjust the variables to match your video file and your Pi's local IP address):

`scp -P 6666 ~/Desktop/video.mp4 looper@192.168.1.123:/home/looper/Videos/autoplay`

When the file transfer is finished, shutdown your Raspberry Pi. Then attach a screen to your Pi's HDMI port, place some video files on a USB media storage and plug it into your Raspberry Pi (if you want you can also just play from the internal autoplay folder). Connect power to boot it. After a short while it should automatically loop the video you transferred to the autoplay folder and/or the files on your USB media storage.


# 07 - Links and Resources

Download and install Raspberry Pi OS:<br>
[https://www.raspberrypi.org/software/operating-systems/](https://www.raspberrypi.org/software/operating-systems/)<br>
[https://www.raspberrypi.org/software/](https://www.raspberrypi.org/software/)

Raspberry Pi Security:<br>
[https://www.raspberrypi.org/documentation/configuration/security.md](https://www.raspberrypi.org/documentation/configuration/security.md)<br>
[https://term7.info/intro-raspberry-pi/](https://term7.info/intro-raspberry-pi/)

VLC Command Line:<br>
[https://wiki.videolan.org/VLC_command-line_help/](https://wiki.videolan.org/VLC_command-line_help/)<br>
[https://wiki.videolan.org/Documentation:Command_line/](https://wiki.videolan.org/Documentation:Command_line/)

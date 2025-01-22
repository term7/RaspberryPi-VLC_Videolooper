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

# Output Modules (edit and uncomment to add more options):
Video_Output="--deinterlace=0 --aspect-ratio=4:3 --no-autoscale --width=720 --height=576"

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
    /usr/bin/vlc -I dummy -q $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
else
    echo "No files found to play."
fi
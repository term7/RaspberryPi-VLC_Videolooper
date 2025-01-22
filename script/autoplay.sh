#!/bin/sh

# VLC OPTIONS:
# View all possible options: vlc -H

export AUTOPLAY=/home/looper/Videos/autoplay
export USB=/media/
export PLAYLIST=/home/looper/Videos/playlist.m3u

# Video Filetypes
FILETYPES="( -name '*.mp4' -o -name '*.mov' -o -name '*.mkv' )"

# Playlist Options
Playlist_Options="-L --started-from-file --one-instance --playlist-enqueue"

# Audio Output Options
Audio_Output="--stereo-mode 1"

# Interface Options
Interface_Options="-f --loop --no-video-title-show"

# Create Playlist File
echo "#EXTM3U" > "$PLAYLIST"

# Check if there are any files in the AUTOPLAY directory
if find "$AUTOPLAY" ! -iname ".*" -type f \( $FILETYPES \) | grep -q .; then
    # If files are found in AUTOPLAY, add them to the playlist and skip waiting for USB
    find "$AUTOPLAY" ! -iname ".*" -type f \( $FILETYPES \) 2>/dev/null >> "$PLAYLIST"
else
    # If no files are found in AUTOPLAY, wait for the USB to be mounted and scan it
    for i in {1..25}; do
        if [ -d "$USB" ]; then
            break
        fi
        sleep 1
    done
    find "$USB" ! -iname ".*" -type f \( $FILETYPES \) 2>/dev/null >> "$PLAYLIST"
fi

# Play Playlist if Files Exist
if [ -s "$PLAYLIST" ]; then
    /usr/bin/vlc -I dummy -q $Audio_Output $Interface_Options $Playlist_Options "$PLAYLIST"
else
    echo "No files found to play."
fi
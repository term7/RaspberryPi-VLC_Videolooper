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
Audio_Output="--stereo-mode 1"

# Interface Options
# Fullscreen, hide title display, decorations, window borders, etc.

Interface_Options="-f --no-video-title-show"

# Some useful Video Filters for Special Occacions:

# Mirror video filter (mirror)
# Splits video in two same parts, like in a mirror
#      --mirror-split {0 (Vertical), 1 (Horizontal)}
#                                 Mirror orientation
#          Defines orientation of the mirror splitting. Can be vertical or
#          horizontal.
#      --mirror-direction {0 (Left to right/Top to bottom), 1 (Right to left/Bottom to top)}
#                                 Direction
#          Direction of the mirroring.

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

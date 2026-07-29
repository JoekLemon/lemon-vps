#!/bin/bash
: '
Title:          Icecast Stream Script
Description:    Streams a music file to Icecast using FFmpeg.
Author:         Joek Lemon
Contributors:
Notes:          Runs inside the ices container via Docker Compose.
'
exec ffmpeg -re -stream_loop -1 -i /music/music.mp3 -c copy -f mp3 \
  icecast://source:${ICECAST_SOURCE_PASS:-hackme}@icecast:8000/stream
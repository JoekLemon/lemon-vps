#!/bin/sh
exec ffmpeg -re -stream_loop -1 -i /music/music.mp3 -c copy -f mp3 \
  icecast://source:${ICECAST_SOURCE_PASS:-hackme}@icecast:8000/stream
#!/bin/bash

RD="$(dirname "$(realpath "$0")")"

IMG='willyhorizont/musicv-player'

if ! docker image inspect "$IMG" > /dev/null 2>&1; then
    docker build \
        --no-cache \
        -t "$IMG" \
        -f "$RD/Dockerfile" \
        "$RD"
fi

docker run -it --rm \
    --device /dev/snd \
    -v "$PWD:$PWD" \
    -v "$RD:$RD" \
    "$IMG" \
    "$@"

# ./debug.sh mpv --version
# ./debug.sh yt-dlp --version
# ./debug.sh mpv --property-list
# ./debug.sh cat /etc/pipewire/client.conf

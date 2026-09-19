#!/bin/bash

RD="$(dirname "$(realpath "$0")")"

IMG='willyhorizont/musicv-player:0.0.6'

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
    playmusicsv "$@"

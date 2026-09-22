#!/bin/bash

HOST_SCRIPT_PATH="$1"
shift

RD="$(dirname "$(realpath "$0")")"

IMG='willyhorizont/musicv-player'

if [[ -z "$HOST_SCRIPT_PATH" || ! -f "$HOST_SCRIPT_PATH" ]]; then
    echo "Error: Host script path invalid or not provided!"
    exit 1
fi

ABS_SCRIPT_PATH="$(realpath "$HOST_SCRIPT_PATH")"
SCRIPT_DIR="$(dirname "$ABS_SCRIPT_PATH")"

if ! docker image inspect "$IMG" > /dev/null 2>&1; then
    docker build \
        --no-cache \
        -t "$IMG" \
        -f "$RD/Dockerfile" \
        "$RD"
fi

HOST_COLS=$(tput cols 2>/dev/null || echo 80)
HOST_LINES=$(tput lines 2>/dev/null || echo 24)

docker run -it --rm \
    --device /dev/snd \
    -e PIPEWIRE_DEBUG=0 \
    -e HOST_HOME="$HOME" \
    -e TERM="$TERM" \
    -e COLUMNS="$HOST_COLS" \
    -e LINES="$HOST_LINES" \
    -v "$PWD:$PWD" \
    -v "$RD:$RD" \
    -v "$SCRIPT_DIR:$SCRIPT_DIR" \
    "$IMG" \
    bash "$ABS_SCRIPT_PATH" "$@"

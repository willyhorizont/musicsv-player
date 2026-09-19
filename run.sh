#!/bin/bash

HOST_SCRIPT_PATH="$1"
shift

RD="$(dirname "$(realpath "$0")")"

IMG='willyhorizont/musicv-player:0.0.7'

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

docker run -it --rm \
    --device /dev/snd \
    -v "$PWD:$PWD" \
    -v "$RD:$RD" \
    -v "$SCRIPT_DIR:$SCRIPT_DIR" \
    "$IMG" \
    bash "$ABS_SCRIPT_PATH" "$@"

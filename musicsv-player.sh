#!/bin/bash

SD=$(dirname "$(realpath "$0")")
RD=$(realpath "$SD")

# "$RD/musicsv-player-node-builtinsocket.sh" "$@"
# "$RD/musicsv-player-node-netcat.sh" "$@"
# "$RD/musicsv-player-node-socat.sh" "$@"
"$RD/musicsv-player-python3-builtinsocket.sh" "$@"
# "$RD/musicsv-player-python3-netcat.sh" "$@"
# "$RD/musicsv-player-python3-socat.sh" "$@"

# "$RD/musicsv-player-python3.sh" "$@"

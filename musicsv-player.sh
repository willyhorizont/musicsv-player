#!/bin/bash

SD=$(dirname "$(realpath "$0")")
RD=$(realpath "$SD")

# "$RD/musicsv-player-node.sh" --cat=builtin "$@"
# "$RD/musicsv-player-node.sh" --cat=netcat "$@"
# "$RD/musicsv-player-node.sh" --cat=socat "$@"
# "$RD/musicsv-player-node.sh" "$@"
# "$RD/musicsv-player-python3.sh" --cat=builtin "$@"
# "$RD/musicsv-player-python3.sh" --cat=netcat "$@"
# "$RD/musicsv-player-python3.sh" --cat=socat "$@"
# "$RD/musicsv-player-python3.sh" "$@"
"$RD/musicsv-player.py" "$@"

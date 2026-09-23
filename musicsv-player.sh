#!/bin/bash

SD=$(dirname "$(realpath "$0")")
RD=$(realpath "$SD")

# "$RD/musicsv-player-oldversion.sh" --cat=builtin --rnr="js" "$@"
# "$RD/musicsv-player-oldversion.sh" --cat=netcat --rnr="js" "$@"
# "$RD/musicsv-player-oldversion.sh" --cat=socat --rnr="js" "$@"
# "$RD/musicsv-player-oldversion.sh" --rnr="js" "$@"
# "$RD/musicsv-player-oldversion.sh" --cat=builtin "$@"
# "$RD/musicsv-player-oldversion.sh" --cat=netcat "$@"
# "$RD/musicsv-player-oldversion.sh" --cat=socat "$@"
# "$RD/musicsv-player-oldversion.sh" "$@"
"$RD/musicsv-player.py" "$@"

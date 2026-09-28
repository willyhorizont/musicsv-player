#!/bin/bash

SD=$(dirname "$(realpath "$0")")
RD=$(realpath "$SD/..")
rm -rf "$HOME/willyhorizont.github.io/musicsv-player"
mkdir -p "$HOME/willyhorizont.github.io/musicsv-player/"
cp -r "$RD/." "$HOME/willyhorizont.github.io/musicsv-player/"

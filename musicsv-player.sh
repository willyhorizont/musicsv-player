play_musicsv() {
    local l="" eln fp peln
    if [[ "$1" =~ ^--playlist= ]]; then
        fp=$(echo "$1" | sed 's/^--playlist=//; s/^["'\'']//; s/["'\'']$//')
        if [[ ! -f "$fp" ]]; then
            echo "Error! file not found in: $fp"
            return 1
        fi
        while IFS= read -r peln || [[ -n "$peln" ]]; do
            peln=$(echo "$peln" | sed "s/^'//; s/'[[:space:]]*\\\\*$//; s/'[[:space:]]*$//")
            [[ -z "$peln" || "$peln" =~ ^[[:space:]]*# ]] && continue
            eln=$(echo "$peln" | sed 's/^[[:space:]]*|[[:space:]]*//; s/[[:space:]]*|[[:space:]]*$//' | xargs)
            l+="\"ytdl://ytsearch:$eln\" "
        done < "$fp"
    else
        for el in "$@"; do
            [[ -z "$el" || "$el" =~ ^[[:space:]]*# ]] && continue
            eln=$(echo "$el" | sed 's/^[[:space:]]*|[[:space:]]*//; s/[[:space:]]*|[[:space:]]*$//' | xargs)
            l+="\"ytdl://ytsearch:$eln\" "
        done
    fi
    eval "mpv --no-video --ytdl-format=worstaudio \
        --ytdl-raw-options-append=compat-options=no-live-chat \
        --ytdl-raw-options-append=extractor-args=youtube:player_client=android_vr \
        --demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5 \
        --term-playing-msg='Currently Playing: \${media-title}' $l"
}

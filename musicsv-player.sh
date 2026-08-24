play_musicsv() {
    local fp peln eln direct_query=""
    local -a songs=()
    local mode="playlist"

    if [[ "$1" =~ ^--play= ]]; then
        direct_query=$(echo "$1" | sed 's/^--play=//; s/^["'\'']//; s/["'\'']$//' | xargs)
        mode="continuous_search"
        echo "Searching YouTube for: '$direct_query'..."
        echo "Building local history queue, please wait a moment..."
        IFS=$'\n' songs=($(yt-dlp --flat-playlist --get-id "ytsearch20:$direct_query" 2>/dev/null | sed 's/^/https:\/\/www.youtube.com\/watch?v=/'))
    elif [[ "$1" =~ ^--playlist= ]]; then
        fp=$(echo "$1" | sed 's/^--playlist=//; s/^["'\'']//; s/["'\'']$//')
        [[ ! -f "$fp" ]] && { echo "Error! file not found in: $fp"; return 1; }
        while IFS= read -r peln || [[ -n "$peln" ]]; do
            peln=$(echo "$peln" | sed "s/^'//; s/'[[:space:]]*\\\\*$//; s/'[[:space:]]*$//")
            [[ -z "$peln" || "$peln" =~ ^[[:space:]]*# ]] && continue
            eln=$(echo "$peln" | sed 's/^[[:space:]]*|[[:space:]]*//; s/[[:space:]]*|[[:space:]]*$//' | xargs)
            songs+=("ytdl://ytsearch:$eln")
        done < "$fp"
    else
        for el in "$@"; do
            [[ -z "$el" || "$el" =~ ^[[:space:]]*# ]] && continue
            eln=$(echo "$el" | sed 's/^[[:space:]]*|[[:space:]]*//; s/[[:space:]]*|[[:space:]]*$//' | xargs)
            songs+=("ytdl://ytsearch:$eln")
        done
    fi

    if [ ${#songs[@]} -eq 0 ]; then
        echo "Not found!"
        return 1
    fi

    local i=0
    while [ $i -lt ${#songs[@]} ] && [ $i -ge 0 ]; do
        echo "--------------------------------------------------------"
        if [ "$mode" == "continuous_search" ]; then
            echo "Streaming Query : $direct_query (Track $((i+1)) of ${#songs[@]} from history)"
        else
            echo "Track $((i+1)) of ${#songs[@]}: ${songs[$i]}"
        fi
        echo "Controls        : [q]=Next/Skip | [Ctrl+C]=Prev | [ESC]=Exit"
        echo "--------------------------------------------------------"

        mpv --no-video --ytdl-format=ba \
            --ytdl-raw-options-append=compat-options=no-live-chat \
            --demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5 \
            --term-playing-msg='Currently Playing: ${media-title}' \
            --input-conf=<(echo "ESC quit 123") \
            "${songs[$i]}" </dev/tty

        local exit_status=$?

        if [ $exit_status -eq 123 ]; then
            echo -e "\nExit program safely. Bye!"
            return 0
        fi

        if [ $exit_status -eq 130 ] || [ $exit_status -eq 4 ]; then
            if [ $i -gt 0 ]; then
                echo -e "\n[<<] Fetching previous track from local history cache..."
                i=$((i - 1))
            else
                echo -e "\n[!] This is already the first track!"
            fi
            sleep 0.5
            continue
        fi

        i=$((i + 1))
    done

    echo -e "\nPlaying queue is done!"
}

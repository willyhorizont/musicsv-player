#!/bin/bash

IPC_SOCK="/tmp/mpv-socket"
fp=""
peln=""
eln=""
act_sig="none"
is_rptall="False"
is_rptone="False"
is_shuf="False"
show_pl="False"
declare -a sgs=() lns=()

for arg in "$@"; do
    [[ "$arg" == "--loop" || "$arg" == "--rptall" ]] && is_rptall="True" && continue
    [[ "$arg" == "--rptone" ]] && is_rptone="True" && continue
    [[ "$arg" == "--shuffle" ]] && is_shuf="True" && continue
    [[ "$arg" == "--show-playlist" ]] && show_pl="True" && continue
    [[ "$arg" =~ ^-- ]] && continue
    [ -z "$fp" ] && fp="$arg" || { [[ ! "$arg" =~ ^[[:space:]]*# ]] && lns+=("$arg"); }
done

if [ -n "$fp" ]; then
    [[ ! -f "$fp" ]] && { echo "Error! file not found in: $fp"; exit 1; }
    while IFS= read -r peln || [[ -n "$peln" ]]; do
        peln=$(echo "$peln" | sed "s/^'//; s/'[[:space:]]*\\\\*$//; s/'[[:space:]]*$//")
        [[ -z "$peln" || "$peln" =~ ^[[:space:]]*# ]] && continue
        lns+=("$peln")
        eln=$(echo "$peln" | sed 's/^[[:space:]]*;[[:space:]]*//; s/[[:space:]]*;[[:space:]]*$//' | xargs)
        sgs+=("ytdl://ytsearch:$eln")
    done < "$fp"
else
    for el in "${lns[@]}"; do
        eln=$(echo "$el" | sed 's/^[[:space:]]*;[[:space:]]*//; s/[[:space:]]*;[[:space:]]*$//' | xargs)
        sgs+=("ytdl://ytsearch:$eln")
    done
fi

[ ${#sgs[@]} -eq 0 ] && { echo "Not found!"; exit 1; }

declare -a ord=()
for ((k=0; k<${#sgs[@]}; k++)); do ord+=($k); done

shuf() {
    if [ "$is_shuf" == "True" ]; then
        local sta_idx=$(( $1 + 1 ))
        for ((k=${#ord[@]}-1; k>sta_idx; k--)); do
            local j=$((RANDOM % (k - sta_idx + 1) + sta_idx))
            local tmp=${ord[$k]}
            ord[$k]=${ord[$j]}
            ord[$j]=$tmp
        done
    fi
}

[ "$is_shuf" == "True" ] && shuf -1

cur_tit="Loading track title..."
cur_upl="Loading artist info..."
cur_sz="0MB"
cur_prog="00:00:00 / 00:00:00"

prt_ui() {
    local disp_fp="None"
    [ -n "$fp" ] && disp_fp=$(echo "$fp" | sed -E 's|/home/[^/]+|\$HOME|')

    printf "\033[Hplaylist: \"%s\"\033[K\n" "$disp_fp"
    if [ "$show_pl" == "True" ]; then
        echo -e "---\033[K"
        for ((idx=0; idx<${#lns[@]}; idx++)); do
            if [ ${ord[$idx]} -eq ${ord[$1]} ]; then
                printf "> ; %s\033[K\n" "${lns[${ord[$idx]}]}"
            else
                printf "  ; %s\033[K\n" "${lns[${ord[$idx]}]}"
            fi
        done
    fi
    echo -e "---\033[K"
    printf "RptAll:%s RptOne:%s Shuf:%s\033[K\n" \
        "$([ "$is_rptall" == "True" ] && echo "Y" || echo "N")" \
        "$([ "$is_rptone" == "True" ] && echo "Y" || echo "N")" \
        "$([ "$is_shuf" == "True" ] && echo "Y" || echo "N")"
    echo -e "---\033[K"
    echo -e "[B]=[Rev] [Z]=[Prev] [P]=[Play/Pause] [Y]=[Next] [F]=[Frwd]\033[K"
    echo -e "[Q]=[Quit]\033[K"
    echo -e "[R]=[RptAll] [1]=[RptOne] [X]=[Shuf] [L]=[ShwLs]\033[K"
    echo -e "---\033[K"
    echo -e "Currently Playing\033[K"
    printf "Title: %s\033[K\nUploader: %s\033[K\nSize: %s\033[K\n%s\033[K\n" "$cur_tit" "$cur_upl" "$cur_sz" "$cur_prog"
    echo -e "---\033[K"
}

q_prop() {
    [ -S "$IPC_SOCK" ] && socat - "UNIX-CONNECT:$IPC_SOCK" 2>/dev/null <<< '{"command":["get_property","'"$1"'"]}' | python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d.get('data') if d.get('data') is not None else '')" 2>/dev/null
}

send_mpv_cmd() {
    [ -S "$IPC_SOCK" ] && printf "%s\n" "{\"command\": $1}" | socat - "UNIX-CONNECT:$IPC_SOCK" >/dev/null 2>&1
}

fmt_tm() {
    date -u -d "@${1%.*}" +%T 2>/dev/null || echo "00:00:00"
}

clear

i=0
while [ $i -lt ${#sgs[@]} ] && [ $i -ge 0 ]; do
    cur_idx=${ord[$i]} act_sig="none" cur_tit="Loading track title..." cur_upl="Loading artist info..." cur_sz="0MB" cur_prog="00:00:00 / 00:00:00"
    clear
    prt_ui $i; rm -f "$IPC_SOCK"

    mpv --no-video --ytdl-format=ba --msg-level=all=no --ytdl-raw-options-append=compat-options=no-live-chat --demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5 --input-ipc-server="$IPC_SOCK" "${sgs[$cur_idx]}" >/dev/null 2>&1 &
    mpv_pid=$!

    while kill -0 "$mpv_pid" 2>/dev/null; do
        read -s -n1 -t 1 k_inp; r_stat=$?
        
        if [ $r_stat -eq 0 ]; then
            case "$k_inp" in
                [zZ]) act_sig="prev"; kill "$mpv_pid" 2>/dev/null; break ;;
                [yY]) act_sig="next"; kill "$mpv_pid" 2>/dev/null; break ;;
                [qQ]) act_sig="exit"; kill "$mpv_pid" 2>/dev/null; break ;;
                [pP]) send_mpv_cmd '["cycle", "pause"]' ;;
                [bB]) send_mpv_cmd '["seek", -5, "relative"]' ;;
                [fF]) send_mpv_cmd '["seek", 5, "relative"]' ;;
                [lL])
                    [ "$show_pl" == "True" ] && show_pl="False" || show_pl="True"
                    clear
                    prt_ui $i
                    ;;
                [rR])
                    if [ "$is_rptall" == "True" ]; then is_rptall="False"; else is_rptall="True"; is_rptone="False"; fi
                    clear
                    prt_ui $i
                    ;;
                1)
                    if [ "$is_rptone" == "True" ]; then is_rptone="False"; else is_rptone="True"; is_rptall="False"; fi
                    clear
                    prt_ui $i
                    ;;
                [xX])
                    if [ "$is_shuf" == "True" ]; then
                        is_shuf="False"
                    else
                        is_shuf="True"
                        shuf $i
                    fi
                    clear
                    prt_ui $i
                    ;;
            esac
        fi
        
        t_val=$(q_prop "media-title")
        [[ -n "$t_val" && ! "$t_val" =~ ^ytsearch: && ! "$t_val" =~ ^ytdl:// ]] && cur_tit="$t_val"
        
        u_val=$(q_prop "file-tags/uploader")
        [ -z "$u_val" ] && u_val=$(q_prop "metadata/by-key/Uploader")
        [ -z "$u_val" ] && u_val=$(q_prop "uploader")
        [ -n "$u_val" ] && cur_upl="$u_val"
        
        cac_j=$(socat - "UNIX-CONNECT:$IPC_SOCK" 2>/dev/null <<< '{"command":["get_property","demuxer-cache-state"]}')
        c_bytes=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d.get('data', {}).get('total-bytes',0))" <<< "$cac_j" 2>/dev/null)
        [[ "$c_bytes" =~ ^[0-9]+$ ]] && [ "$c_bytes" -gt 0 ] && cur_sz="$((c_bytes / 1024 / 1024))MB" || cur_sz="0MB"
        
        tmpos=$(q_prop "time-pos") dur=$(q_prop "duration")
        if [ -n "$tmpos" ] && [ -n "$dur" ]; then
            cur_prog="$(fmt_tm "$tmpos") / $(fmt_tm "$dur")"
        fi
        prt_ui $i
    done

    wait "$mpv_pid" 2>/dev/null; rm -f "$IPC_SOCK"

    case "$act_sig" in
        "exit") printf "\nExit program safely. Bye!\n"; exit 0 ;;
        "prev") [ $i -gt 0 ] && i=$((i - 1)) || { printf "\n[!] First track!\n"; sleep 0.5; }; continue ;;
        *) [[ "$is_rptone" == "True" ]] && continue || { [ $i -eq $(( ${#sgs[@]} - 1 )) ] && { [[ "$is_rptall" == "True" ]] && i=0 || break; } || i=$((i + 1)); }; continue ;;
    esac
done

printf "\nPlaying queue is done!\n"

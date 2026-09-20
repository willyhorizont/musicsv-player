#!/bin/bash

IPC_SOCK="${TMPDIR:-/tmp}/mpv-socket"
fp=""
peln=""
eln=""
act_sig="none"
is_rptall="False"
is_rptone="False"
is_shuf="False"
shw_pl="False"
declare -a sgs=() lns=()

for arg in "$@"; do
    [[ "$arg" == "--rptall" ]] && is_rptall="True" && continue
    [[ "$arg" == "--rptone" ]] && is_rptone="True" && continue
    [[ "$arg" == "--shuf" ]] && is_shuf="True" && continue
    [[ "$arg" == "--shwpl" ]] && shw_pl="True" && continue
    [[ "$arg" =~ ^-- ]] && continue
    [ -z "$fp" ] && fp="$arg" || { [[ ! "$arg" =~ ^[[:space:]]*# ]] && lns+=("$arg"); }
done

if [ -n "$fp" ]; then
    [[ ! -f "$fp" ]] && { echo "Error! file not found in: $fp"; exit 1; }
    while IFS= read -r peln || [[ -n "$peln" ]]; do
        peln=$(echo "$peln" | sed "s/^'//; s/'[[:space:]]*\\\\*$//; s/'[[:space:]]*$//")
        [[ -z "$peln" || "$peln" =~ ^[[:space:]]*# ]] && continue
        peln_sfs="${peln//\'/\\\'}"
        peln_sfd="${peln_sfs//\"/\\\"}"
        peln_cln=$(echo "$peln_sfd" | sed 's/[[:space:]]*;[[:space:]]*/ ; /g; s/[[:space:]]\+/ /g' | xargs)
        lns+=("$peln_cln")
        eln=$(echo "$peln_cln" | sed 's/^[[:space:]]*;[[:space:]]*//; s/[[:space:]]*;[[:space:]]*$//' | xargs)
        sgs+=("ytdl://ytsearch:$eln")
    done < "$fp"
else
    for el in "${lns[@]}"; do
        el_sfs="${el//\'/\\\'}"
        el_sfd="${el_sfs//\"/\\\"}"
        eln_cln=$(echo "$el_sfd" | sed 's/[[:space:]]*;[[:space:]]*/ ; /g; s/[[:space:]]\+/ /g' | xargs)
        sgs+=("ytdl://ytsearch:$eln_cln")
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

cur_tit="Loading title..."
cur_upl="Loading uploader info..."
cur_sz="0MB"
cur_prog="00:00:00 / 00:00:00"
pl_scroll=0

prt_sep() {
    printf '%*s' "$(( $(tput cols 2>/dev/null || echo 56) - 3 ))" '' | tr ' ' "${1:-=}" ; printf "\033[K\n"
}

get_anm_chnk() {
    local lb="$1"
    local full_txt="$2"
    local mx_w=$3
    
    local lb_len=${#lb}
    local chnk_sz=$(( mx_w - lb_len ))
    local tot_len=${#full_txt}
    
    if [ $tot_len -le $chnk_sz ]; then
        printf "%s%s" "$lb" "$full_txt"
    else
        local num_chnks=$(( (tot_len + chnk_sz - 1) / chnk_sz ))
        local trg_len=$(( num_chnks * chnk_sz ))
        local pad_need=$(( trg_len - tot_len ))
        local pd_txt="$full_txt"
        if [ $pad_need -gt 0 ]; then
            local pdg=$(printf '%*s' "$pad_need" '')
            pd_txt="${full_txt}${pdg}"
        fi
        local anm_spd=2
        local cur_chnk=$(( (ANM_TICK / anm_spd) % num_chnks ))
        local sta_pos=$(( cur_chnk * chnk_sz ))
        
        printf "%s%s" "$lb" "${pd_txt:$sta_pos:$chnk_sz}"
    fi
}

prt_ui() {
    local hst_home="${HOST_HOME:-$HOME}"
    local disp_fp="None"
    if [ -n "$fp" ] && [ -n "$HOST_HOME" ]; then
        disp_fp="\$HOME/${fp#$hst_home/}"
    elif [ -n "$fp" ]; then
        disp_fp="\$HOME/${fp#$HOME/}"
    fi

    local mx_w=$(( $(tput cols 2>/dev/null || echo 56) - 3 ))

    abt='github.com/willyhorizont/MusiCSV-Player/tree/0.1.19'
    printf "\033[H\033[J$abt\033[K\n"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Query: " "${lns[$cur_idx]}" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Title: " "$cur_tit" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Uploader: " "$cur_upl" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Playlist: " "\"$disp_fp\"" $mx_w)"
    if [ "$shw_pl" == "True" ]; then
        prt_sep "="
        
        local actv_stp=$1
        local tot_lns=${#lns[@]}
        
        local ctr_fcs=$(( actv_stp + pl_scroll ))
        local sta_win=$(( ctr_fcs - 1 ))
        local end_win=$(( ctr_fcs + 1 ))
        
        if [ $sta_win -lt 0 ]; then
            sta_win=0
            end_win=2
            [ $end_win -ge $tot_lns ] && end_win=$(( tot_lns - 1 ))
        fi
        
        if [ $end_win -ge $tot_lns ]; then
            end_win=$(( tot_lns - 1 ))
            sta_win=$(( end_win - 2 ))
            [ $sta_win -lt 0 ] && sta_win=0
        fi
        
        for ((idx=sta_win; idx<=end_win; idx++)); do
            if [ $idx -ge 0 ] && [ $idx -lt $tot_lns ]; then
                local raw_itm="${lns[${ord[$idx]}]}"
                
                local prefix="  ; $((idx + 1)) ; "
                [ ${ord[$idx]} -eq ${ord[$actv_stp]} ] && prefix="> ; $((idx + 1)) ; "
                
                printf "%s\033[K\n" "$(get_anm_chnk "$prefix" "$raw_itm" $mx_w)"
                
                if [ $idx -lt $end_win ] && [ $idx -lt $(( tot_lns - 1 )) ]; then
                    prt_sep "-"
                fi
            fi
        done
        prt_sep "="
    else
        prt_sep "-"
        printf "Size: %s\033[K | %s\033[K\n" "$cur_sz" "$cur_prog"
        prt_sep "-"
    fi
    
    printf "RptOne:%s | RptAll:%s | Shuf:%s\033[K\n" \
        "$([ "$is_rptall" == "True" ] && echo "Ya" || echo "No")" \
        "$([ "$is_rptone" == "True" ] && echo "Ya" || echo "No")" \
        "$([ "$is_shuf" == "True" ] && echo "Ya" || echo "No")"
    printf "[P]=[Quit] [N]=[Rwnd] [M]=[Frwd]\033[K\n"
    printf "[Z]=[Prev] [X]=[Play/Pause] [C]=[Next]\033[K\n"
    printf "[1]=[RptOne] [2]=[RptAll] [3]=[Shuf]\033[K\n"
    printf "[U]=[ShwLs] [T]=[ScrlLsUp] [G]=[ScrlLsDwn]\033[K\n"
    prt_sep "-"
}

q_prop() {
    if [ -S "$IPC_SOCK" ]; then
        local cmd_pld
        cmd_pld=$(python3 -c "import sys, json; print(json.dumps({'command': ['get_property', sys.stdin.read().strip()]}))" <<< "$1" 2>/dev/null)
        if [ -n "$cmd_pld" ]; then
            local raw_j
            raw_j=$(socat - "UNIX-CONNECT:$IPC_SOCK" 2>/dev/null <<< "$cmd_pld")
            if [ -n "$raw_j" ]; then
                python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('data', ''))" <<< "$raw_j" 2>/dev/null
            fi
        fi
    fi
}

send_mpv_cmd() {
    if [ -S "$IPC_SOCK" ]; then
        local cmd_pld
        cmd_pld=$(python3 -c "import sys, json; print(json.dumps({'command': json.loads(sys.stdin.read().strip())}))" <<< "$1" 2>/dev/null)
        [ -n "$cmd_pld" ] && socat - "UNIX-CONNECT:$IPC_SOCK" >/dev/null 2>&1 <<< "$cmd_pld"
    fi
}

fmt_tm() {
    date -u -d "@${1%.*}" +%T 2>/dev/null || echo "00:00:00"
}

clear

i=0
while [ $i -lt ${#sgs[@]} ] && [ $i -ge 0 ]; do
    cur_idx=${ord[$i]} act_sig="none" cur_tit="Loading title..." cur_upl="Loading uploader info..." cur_sz="0MB" cur_prog="00:00:00 / 00:00:00"
    clear
    prt_ui $i; rm -f "$IPC_SOCK"

    mpv --no-video --ytdl-format=ba --msg-level=all=no --ytdl-raw-options-append=compat-options=no-live-chat --demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5 --input-ipc-server="$IPC_SOCK" "${sgs[$cur_idx]}" >/dev/null 2>&1 &
    mpv_pid=$!
    ANM_TICK=0

    while kill -0 "$mpv_pid" 2>/dev/null; do
        read -s -n1 -t 1 k_inp; r_stat=$?
        
        if [ $r_stat -eq 0 ]; then
            case "$k_inp" in
                [pP]) act_sig="exit"; kill "$mpv_pid" 2>/dev/null; break ;;
                [nN]) send_mpv_cmd '["seek", -5, "relative"]' ;;
                [mM]) send_mpv_cmd '["seek", 5, "relative"]' ;;
                [zZ]) act_sig="prev"; kill "$mpv_pid" 2>/dev/null; break ;;
                [xX]) send_mpv_cmd '["cycle", "pause"]' ;;
                [cC]) act_sig="next"; kill "$mpv_pid" 2>/dev/null; break ;;
                1)
                    if [ "$is_rptone" == "True" ]; then is_rptone="False"; else is_rptone="True"; is_rptall="False"; fi
                    clear
                    prt_ui $i
                    ;;
                2)
                    if [ "$is_rptall" == "True" ]; then is_rptall="False"; else is_rptall="True"; is_rptone="False"; fi
                    clear
                    prt_ui $i
                    ;;
                3)
                    pl_scroll=0
                    if [ "$is_shuf" == "True" ]; then
                        is_shuf="False"
                    else
                        is_shuf="True"
                        shuf $i
                    fi
                    clear
                    prt_ui $i
                    ;;
                [uU])
                    [ "$shw_pl" == "True" ] && shw_pl="False" || shw_pl="True"
                    pl_scroll=0
                    clear
                    prt_ui $i
                    ;;
                [tT])
                    if [ "$shw_pl" == "True" ]; then
                        if [ $(( i + pl_scroll )) -gt 0 ]; then
                            pl_scroll=$(( pl_scroll - 1 ))
                            clear
                            prt_ui $i
                        fi
                    fi
                    ;;
                [gG])
                    if [ "$shw_pl" == "True" ]; then
                        if [ $(( i + pl_scroll )) -lt $(( ${#lns[@]} - 1 )) ]; then
                            pl_scroll=$(( pl_scroll + 1 ))
                            clear
                            prt_ui $i
                        fi
                    fi
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
        if [ -n "$cac_j" ]; then
            c_bytes=$(python3 -c "import sys, json; print(json.loads(sys.stdin.read()).get('data', {}).get('total-bytes',0))" <<< "$cac_j" 2>/dev/null)
            [[ "$c_bytes" =~ ^[0-9]+$ ]] && [ "$c_bytes" -gt 0 ] && cur_sz="$((c_bytes / 1024 / 1024))MB" || cur_sz="0MB"
        fi
        tmpos=$(q_prop "time-pos") dur=$(q_prop "duration")
        if [ -n "$tmpos" ] && [ -n "$dur" ]; then
            cur_prog="$(fmt_tm "$tmpos") / $(fmt_tm "$dur")"
        fi
        ANM_TICK=$(( ANM_TICK + 1 ))
        prt_ui $i
    done
    wait "$mpv_pid" 2>/dev/null; rm -f "$IPC_SOCK"
    case "$act_sig" in
        "exit") clear; exit 0 ;;
        "prev") [ $i -gt 0 ] && i=$((i - 1)) || { printf "\n[!] First track!\n"; sleep 0.5; }; continue ;;
        *) [[ "$is_rptone" == "True" ]] && continue || { [ $i -eq $(( ${#sgs[@]} - 1 )) ] && { [[ "$is_rptall" == "True" ]] && i=0 || break; } || i=$((i + 1)); }; continue ;;
    esac
done

printf "\nPlaying queue is done!\n"

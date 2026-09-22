#!/bin/bash

SD=$(dirname "$(realpath "$0")")
RD=$(realpath "$SD")

printf "\033[?25l"
clean_exit() {
    printf "\033[?25h\033[2J\033[H"
    exit 0
}
trap clean_exit SIGINT SIGTERM

IPC_SOCK="${TMPDIR:-/tmp}/mpv-socket"
fp=""
peln=""
eln=""
act_sig="none"
is_rptall="False"
is_rptone="False"
is_shuf="False"
shw_pl="False"
is_scrn_pau="False"
declare -a sgs=() lns=() reqry_offsets=()

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
for ((k=0; k<${#sgs[@]}; k++)); do 
    ord+=($k)
    reqry_offsets[$k]=1
done

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
pl_scrl=0
sel_ptr=0

MX_W=$(( COLUMNS - 3 ))
[ -z "$MX_W" ] || [ "$MX_W" -le 0 ] && MX_W=$(( $(tput cols 2>/dev/null || echo 56) - 3 ))
trap 'MX_W=$(( $(tput cols 2>/dev/null || echo 56) - 3 ))' SIGWINCH

prt_sep() {
    printf '%*s' "$MX_W" '' | tr ' ' "${1:-=}" ; printf "\033[K\n"
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
    printf "\033[1;1H"

    local hst_home="${HOST_HOME:-$HOME}"
    local disp_fp="None"
    if [ -n "$fp" ] && [ -n "$HOST_HOME" ]; then
        disp_fp="\$HOME/${fp#$hst_home/}"
    elif [ -n "$fp" ]; then
        disp_fp="\$HOME/${fp#$HOME/}"
    fi

    local mx_w=$MX_W

    abt='github.com/willyhorizont/MusiCSV-Player/tree/0.1.28'
    printf "%s\033[K\n" "$abt"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Query: " "${lns[$cur_idx]}" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Title: " "$cur_tit" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Uploader: " "$cur_upl" $mx_w)"
    prt_sep "-"
    printf "%s\033[K\n" "$(get_anm_chnk "Playlist: " "\"$disp_fp\"" $mx_w)"
    if [ "$shw_pl" == "True" ]; then
        prt_sep "v"
        
        local actv_stp=$1
        local tot_lns=${#lns[@]}
        
        local sta_win=$pl_scrl
        local end_win=$(( pl_scrl + 2 ))
        
        if [ $end_win -ge $tot_lns ]; then
            end_win=$(( tot_lns - 1 ))
            sta_win=$(( end_win - 2 ))
            [ $sta_win -lt 0 ] && sta_win=0
        fi
        
        for ((idx=sta_win; idx<=end_win; idx++)); do
            if [ $idx -ge 0 ] && [ $idx -lt $tot_lns ]; then
                local rl_idx_pos=${ord[$idx]}
                local raw_itm="${lns[$rl_idx_pos]}"
                
                local p_now=" "
                local p_sel=" "
                [ $idx -eq $actv_stp ] && p_now=">"
                [ $idx -eq $sel_ptr ] && p_sel="*"
                
                local v_offset=""
                if [ -n "${reqry_offsets[$rl_idx_pos]}" ] && [ "${reqry_offsets[$rl_idx_pos]}" -gt 1 ]; then
                    v_offset=" [v${reqry_offsets[$rl_idx_pos]}]"
                fi
                
                local prefx="${p_now}${p_sel}; $((idx + 1)) ; "
                printf "%s\033[K\n" "$(get_anm_chnk "$prefx" "${raw_itm}${v_offset}" $mx_w)"
                
                if [ $idx -lt $end_win ] && [ $idx -lt $(( tot_lns - 1 )) ]; then
                    prt_sep "-"
                fi
            fi
        done
        prt_sep "^"
    else
        prt_sep "x"
        printf "Size: %s\033[K | %s\033[K\n" "$cur_sz" "$cur_prog"
        prt_sep "-"
    fi
    
    printf "RptOne:%s | RptAll:%s | Shuf:%s | ScrnPau: %s\033[K\n" \
        "$([ "$is_rptone" == "True" ] && echo "Ya" || echo "No")" \
        "$([ "$is_rptall" == "True" ] && echo "Ya" || echo "No")" \
        "$([ "$is_shuf" == "True" ] && echo "Ya" || echo "No")" \
        "$([ "$is_scrn_pau" == "True" ] && echo "Ya" || echo "No")"
    printf "[0]=[Ext] [1]=[RptOne] [2]=[RptAll] [3]=[Shuf]\033[K\n"
    printf "[L]=[Reqry] [O]=[Prv] [P]=[Nxt] [T]=[PtrUp]\033[K\n"
    printf "[M]=[ShwLs] [U]=[Sel] [F]=[PtrDwn]\033[K\n"
    printf "[A]=[Rewnd] [S]=[Frwd] [Z]=[Rsm/Pau] [B]=[PauScrn]\033[K\n"
    prt_sep "-"
    
    printf "\033[J"
}

q_prop() {
    if [ -S "$IPC_SOCK" ]; then
        local cmd_pld
        cmd_pld=$(python3 "$RD/mpv-util.py" --get-prop <<< "$1" 2>/dev/null)
        if [ -n "$cmd_pld" ]; then
            local raw_j
            raw_j=$(socat -t 1 - "UNIX-CONNECT:$IPC_SOCK" 2>/dev/null <<< "$cmd_pld")
            if [ -n "$raw_j" ]; then
                python3 "$RD/mpv-util.py" --parse-prop <<< "$raw_j" 2>/dev/null
            fi
        fi
    fi
}

send_mpv_cmd() {
    if [ -S "$IPC_SOCK" ]; then
        local cmd_pld
        cmd_pld=$(python3 "$RD/mpv-util.py" --send-cmd <<< "$1" 2>/dev/null)
        [ -n "$cmd_pld" ] && socat -t 1 - "UNIX-CONNECT:$IPC_SOCK" >/dev/null 2>&1 <<< "$cmd_pld"
    fi
}

fmt_tm() {
    date -u -d "@${1%.*}" +%T 2>/dev/null || echo "00:00:00"
}

printf "\033[2J"
i=0
sel_ptr=0

while [ $i -lt ${#sgs[@]} ] && [ $i -ge 0 ]; do
    cur_idx=${ord[$i]} act_sig="none" cur_tit="Loading title..." cur_upl="Loading uploader info..." cur_sz="0MB" cur_prog="00:00:00 / 00:00:00"
    is_scrn_pau="False"
    
    rm -f "$IPC_SOCK"
    prt_ui $i

    mpv --no-video --ytdl-format=ba --msg-level=all=no --ytdl-raw-options-append=compat-options=no-live-chat --demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5 --input-ipc-server="$IPC_SOCK" "${sgs[$cur_idx]}" >/dev/null 2>&1 &
    mpv_pid=$!
    ANM_TICK=0

    while kill -0 "$mpv_pid" 2>/dev/null; do
        read -s -n1 -t 0.1 k_inp; r_stat=$?
        
        if [ $r_stat -eq 0 ]; then
            case "$k_inp" in
                0) act_sig="exit"; kill "$mpv_pid" 2>/dev/null; break ;;
                1)
                    if [ "$is_rptone" == "True" ]; then is_rptone="False"; else is_rptone="True"; is_rptall="False"; fi
                    prt_ui $i;
                    ;;
                2)
                    if [ "$is_rptall" == "True" ]; then is_rptall="False"; else is_rptall="True"; is_rptone="False"; fi
                    prt_ui $i;
                    ;;
                3)
                    if [ "$is_shuf" == "True" ]; then
                        is_shuf="False"
                    else
                        is_shuf="True"
                        shuf $i
                    fi
                    prt_ui $i;
                    ;;
                [oO]) act_sig="prev"; kill "$mpv_pid" 2>/dev/null; break ;;
                [pP]) act_sig="next"; kill "$mpv_pid" 2>/dev/null; break ;;
                [tT])
                    if [ "$shw_pl" == "True" ]; then
                        if [ $sel_ptr -gt 0 ]; then
                            sel_ptr=$(( sel_ptr - 1 ))
                            if [ $sel_ptr -lt $pl_scrl ]; then
                                pl_scrl=$sel_ptr
                            fi
                            prt_ui $i;
                        fi
                    fi
                    ;;
                [fF])
                    if [ "$shw_pl" == "True" ]; then
                        if [ $sel_ptr -lt $(( ${#lns[@]} - 1 )) ]; then
                            sel_ptr=$(( sel_ptr + 1 ))
                            if [ $sel_ptr -gt $(( pl_scrl + 2 )) ]; then
                                pl_scrl=$(( sel_ptr - 2 ))
                            fi
                            prt_ui $i;
                        fi
                    fi
                    ;;
                [mM])
                    [ "$shw_pl" == "True" ] && shw_pl="False" || shw_pl="True"
                    prt_ui $i;
                    ;;
                [uU])
                    if [ "$shw_pl" == "True" ]; then
                        act_sig="seltrig"
                        kill "$mpv_pid" 2>/dev/null
                        break
                    fi
                    ;;
                [lL])
                    if [ "$shw_pl" == "True" ]; then
                        curq_offst=${reqry_offsets[$cur_idx]}
                        [[ ! "$curq_offst" =~ ^[0-9]+$ ]] && curq_offst=1
                        reqry_offsets[$cur_idx]=$(( curq_offst + 1 ))
                        cln_q=""
                        if [ -n "$fp" ]; then
                            cln_q=$(echo "${lns[$cur_idx]}" | sed 's/^[[:space:]]*;[[:space:]]*//; s/[[:space:]]*;[[:space:]]*$//' | xargs)
                        else
                            cln_q=$(echo "${lns[$cur_idx]}" | sed 's/[[:space:]]*;[[:space:]]*/ ; /g; s/[[:space:]]\+/ /g' | xargs)
                        fi
                        cln_q=$(echo "$cln_q" | sed 's/[[:space:]]*;[[:space:]]*$//' | xargs)
                        nu_offst=${reqry_offsets[$cur_idx]}
                        sgs[$cur_idx]="ytdl://ytsearch${nu_offst}:$cln_q"
                        act_sig="reqry"
                        kill "$mpv_pid" 2>/dev/null
                        break
                    fi
                    ;;
                [aA]) send_mpv_cmd '["seek", -5, "relative"]' ;;
                [sS]) send_mpv_cmd '["seek", 5, "relative"]' ;;
                [zZ]) send_mpv_cmd '["cycle", "pause"]' ;;
                [bB])
                    if [ "$is_scrn_pau" == "True" ]; then
                        is_scrn_pau="False"
                    else
                        is_scrn_pau="True"
                        prt_ui $i
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
        if [ "$shw_pl" == "False" ] && [ -S "$IPC_SOCK" ]; then
            cac_j=$(socat -t 1 - "UNIX-CONNECT:$IPC_SOCK" 2>/dev/null <<< '{"command":["get_property","demuxer-cache-state"]}')
            if [ -n "$cac_j" ]; then
                c_bytes=$(python3 "$RD/mpv-util.py" --cache-bytes <<< "$cac_j" 2>/dev/null)
                if [ -n "$c_bytes" ] && [[ "$c_bytes" =~ ^[0-9]+$ ]] && [ "$c_bytes" -gt 0 ]; then
                    cur_sz="$((c_bytes / 1024 / 1024))MB"
                else
                    cur_sz="0MB"
                fi
            fi
        fi
        tmpos=$(q_prop "time-pos") dur=$(q_prop "duration")
        if [[ "$tmpos" =~ ^[0-9.]+$ ]] && [[ "$dur" =~ ^[0-9.]+$ ]]; then
            cur_prog="$(fmt_tm "$tmpos") / $(fmt_tm "$dur")"
        fi
        if [ "$is_scrn_pau" == "False" ]; then
            ANM_TICK=$(( ANM_TICK + 1 ))
            prt_ui $i
        fi
    done
    wait "$mpv_pid" 2>/dev/null; rm -f "$IPC_SOCK"
    case "$act_sig" in
        "exit") clean_exit ;;
        "reqry") continue ;;
        "seltrig")
            i=$sel_ptr
            continue
            ;;
        "prev")
            [ $i -gt 0 ] && i=$((i - 1)) || { printf "\n[!] First track!\n"; sleep 0.5; }
            sel_ptr=$i
            continue
            ;;
        *)
            if [[ "$is_rptone" == "True" ]]; then
                continue
            else
                [ $i -eq $(( ${#sgs[@]} - 1 )) ] && { [[ "$is_rptall" == "True" ]] && i=0 || break; } || i=$((i + 1))
                sel_ptr=$i
                if [ $i -lt $pl_scrl ] || [ $i -gt $(( pl_scrl + 2 )) ]; then
                    pl_scrl=$i
                    [ $pl_scrl -gt $(( ${#lns[@]} - 3 )) ] && pl_scrl=$(( ${#lns[@]} - 3 ))
                    [ $pl_scrl -lt 0 ] && pl_scrl=0
                fi
                continue
            fi
            ;;
        esac
done

printf "\nPlaying queue is done!\n"

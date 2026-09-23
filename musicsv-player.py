#!/usr/bin/env python3

import os
import sys
import time
import json
import random
import socket
import curses
import subprocess

IPC_SOCK = os.path.join(os.environ.get("TMPDIR", "/tmp"), "mpv-socket")
fp = ""
lns = []
sgs = []
reqry_offsts = []
ord_idx = []

is_rptall = False
is_rptone = False
is_shuf = False
shw_pl = False
is_scrn_pau = False

cur_idx = 0
sel_ptr = 0
pl_scrl = 0
anm_tick = 0
ipc_tick = 0

cur_tit = "Loading title..."
cur_upl = "Loading uploader info..."
cur_sz = "0MB"
cur_prog = "00:00:00 / 00:00:00"

args = sys.argv[1:]
for arg in args:
    if arg == "--rptall": is_rptall = True
    elif arg == "--rptone": is_rptone = True
    elif arg == "--shuf": is_shuf = True
    elif arg == "--shwpl": shw_pl = True
    elif arg.startswith("--"): continue
    else:
        if not fp: fp = arg
        else:
            if not arg.strip().startswith("#"): lns.append(arg)

def cln_qry_ln(ln):
    cln = ln.strip().lstrip("'").rstrip("'").rstrip("\\").strip()
    pts = [p.strip() for p in cln.split(";") if p.strip()]
    cln = " ; ".join(pts)
    return " ".join(cln.split())

if fp:
    if not os.path.isfile(fp):
        print(f"Error! file not found in: {fp}")
        sys.exit(1)
    with open(fp, "r", encoding="utf-8", errors="ignore") as f:
        for ln in f:
            ln_str = ln.strip()
            if not ln_str or ln_str.startswith("#"): continue
            cln = cln_qry_ln(ln_str)
            lns.append(cln)
            eln = cln.strip(";").strip()
            sgs.append(f"ytdl://ytsearch:{eln}")
else:
    raw_lns = list(lns)
    lns.clear()
    for el in raw_lns:
        cln = cln_qry_ln(el)
        lns.append(cln)
        sgs.append(f"ytdl://ytsearch:{cln}")

if not sgs:
    print("Not found!")
    sys.exit(1)

ord_idx = list(range(len(sgs)))
reqry_offsts = [1] * len(sgs)

def shuf(strt_frm):
    if is_shuf:
        sta_idx = strt_frm + 1
        sub_list = ord_idx[sta_idx:]
        random.shuffle(sub_list)
        ord_idx[sta_idx:] = sub_list

if is_shuf:
    shuf(-1)

def q_prop(prop_nm):
    if not os.path.exists(IPC_SOCK): return None
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.05) # ms
            s.connect(IPC_SOCK)
            req = json.dumps({"command": ["get_property", prop_nm]}) + "\n"
            s.sendall(req.encode("utf-8"))
            raw = s.recv(4096).decode("utf-8", errors="ignore").strip()
            for ln in raw.split("\n"):
                if not ln: continue
                obj = json.loads(ln)
                if "data" in obj and obj["data"] is not None:
                    return str(obj["data"])
    except Exception:
        pass
    return None

def snd_mpv_cmd(cmd_ls):
    if not os.path.exists(IPC_SOCK): return
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.05)
            s.connect(IPC_SOCK)
            req = json.dumps({"command": cmd_ls}) + "\n"
            s.sendall(req.encode("utf-8"))
    except Exception:
        pass

def ftch_cac_bytes():
    if not os.path.exists(IPC_SOCK): return 0
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.settimeout(0.05)
            s.connect(IPC_SOCK)
            req = json.dumps({"command": ["get_property", "demuxer-cache-state"]}) + "\n"
            s.sendall(req.encode("utf-8"))
            raw = s.recv(4096).decode("utf-8", errors="ignore").strip()
            for ln in raw.split("\n"):
                if not ln: continue
                obj = json.loads(ln)
                if "data" in obj and isinstance(obj["data"], dict):
                    return obj["data"].get("total-bytes", 0)
    except Exception:
        pass
    return 0

def fmt_tm(sec_str):
    try:
        sec = int(float(sec_str))
        h = sec // 3600
        m = (sec % 3600) // 60
        s = sec % 60
        return f"{h:02d}:{m:02d}:{s:02d}"
    except Exception:
        return "00:00:00"

def get_anm_chnk(lb, full_txt, mx_w):
    lb_len = len(lb)
    chnk_sz = mx_w - lb_len
    tot_len = len(full_txt)
    if chnk_sz <= 0: return lb[:mx_w]
    
    if tot_len <= chnk_sz:
        return f"{lb}{full_txt}".ljust(mx_w)[:mx_w]
    else:
        num_chnks = (tot_len + chnk_sz - 1) // chnk_sz
        trg_len = num_chnks * chnk_sz
        pd_txt = full_txt + (" " * (trg_len - tot_len))
        anm_spd = 5
        cur_chnk = (anm_tick // anm_spd) % num_chnks
        sta_pos = cur_chnk * chnk_sz
        return f"{lb}{pd_txt[sta_pos:sta_pos+chnk_sz]}"

def prt_scrn(stdscr, actv_stp):
    global cur_sz, cur_prog, cur_tit, cur_upl
    stdscr.erase()
    mx_y, mx_x = stdscr.getmaxyx()
    mx_w = mx_x - 3
    if mx_w <= 0: mx_w = 56

    def prt_sep(char="="):
        stdscr.addstr(char * mx_w + "\n")

    disp_fp = "None"
    if fp:
        disp_fp = fp.replace(os.environ.get("HOME", ""), "$HOME")

    abt = 'github.com/willyhorizont/MusiCSV-Player/tree/0.2.1'
    stdscr.addstr(f"{abt}\n")
    prt_sep("-")
    
    rl_idx = ord_idx[actv_stp]
    stdscr.addstr(get_anm_chnk("Query: ", lns[rl_idx], mx_w) + "\n")
    prt_sep("-")
    stdscr.addstr(get_anm_chnk("Title: ", cur_tit, mx_w) + "\n")
    prt_sep("-")
    stdscr.addstr(get_anm_chnk("Uploader: ", cur_upl, mx_w) + "\n")
    prt_sep("-")
    stdscr.addstr(get_anm_chnk("Playlist: ", f'"{disp_fp}"', mx_w) + "\n")
    
    if shw_pl:
        prt_sep("v")
        tot_lns = len(lns)
        sta_win = pl_scrl
        end_win = pl_scrl + 2
        if end_win >= tot_lns:
            end_win = tot_lns - 1
            sta_win = end_win - 2
            if sta_win < 0: sta_win = 0
            
        for idx in range(sta_win, end_win + 1):
            if 0 <= idx < tot_lns:
                rl_idx_pos = ord_idx[idx]
                raw_itm = lns[rl_idx_pos]
                p_now = ">" if idx == actv_stp else " "
                p_sel = "*" if idx == sel_ptr else " "
                
                v_offst = ""
                if reqry_offsts[rl_idx_pos] > 1:
                    v_offst = f" [v{reqry_offsts[rl_idx_pos]}]"
                    
                prefx = f"{p_now}{p_sel}; {idx + 1} ; "
                stdscr.addstr(get_anm_chnk(prefx, f"{raw_itm}{v_offst}", mx_w) + "\n")
                if idx < end_win and idx < (tot_lns - 1):
                    prt_sep("-")
        prt_sep("^")
    else:
        prt_sep("x")
        stdscr.addstr(f"Size: {cur_sz} | {cur_prog}\n")
        prt_sep("-")
        
    stdscr.addstr(f"RptOne:{'Ya' if is_rptone else 'No'} | RptAll:{'Ya' if is_rptall else 'No'} | Shuf:{'Ya' if is_shuf else 'No'} | ScrnPau: {'Ya' if is_scrn_pau else 'No'}\n")
    stdscr.addstr("[0]=[Ext] [1]=[RptOne] [2]=[RptAll] [3]=[Shuf]\n")
    stdscr.addstr("[L]=[Reqry] [O]=[Prv] [P]=[Nxt] [T]=[PtrUp]\n")
    stdscr.addstr("[M]=[ShwLs] [U]=[Sel] [F]=[PtrDwn]\n")
    stdscr.addstr("[A]=[Rewnd] [S]=[Frwd] [Z]=[Rsm/Pau] [B]=[PauScrn]\n")
    prt_sep("-")
    stdscr.refresh()

def main(stdscr):
    global is_rptone, is_rptall, is_shuf, shw_pl, is_scrn_pau
    global sel_ptr, pl_scrl, anm_tick, ipc_tick
    global cur_tit, cur_upl, cur_sz, cur_prog
    
    curses.curs_set(0)
    stdscr.nodelay(True)
    stdscr.timeout(100) # read input tick per 0.1 sec
    
    i = 0
    sel_ptr = 0
    
    while 0 <= i < len(sgs):
        cur_idx = ord_idx[i]
        act_sig = "none"
        cur_tit = "Loading title..."
        cur_upl = "Loading uploader info..."
        cur_sz = "0MB"
        cur_prog = "00:00:00 / 00:00:00"
        is_scrn_pau = False
        
        if os.path.exists(IPC_SOCK):
            try: os.remove(IPC_SOCK)
            except Exception: pass
            
        prt_scrn(stdscr, i)
        
        cmd = [
            "mpv", "--no-video", "--ytdl-format=ba", "--msg-level=all=no",
            "--ytdl-raw-options-append=compat-options=no-live-chat",
            "--demuxer-lavf-o=reconnect=1,reconnect_at_eof=1,reconnect_streamed=1,reconnect_delay_max=5",
            f"--input-ipc-server={IPC_SOCK}", sgs[cur_idx]
        ]
        proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        anm_tick = 0
        ipc_tick = 0
        
        while proc.poll() is None:
            try:
                ch = stdscr.getch()
            except Exception:
                ch = -1
                
            if ch != -1:
                k = chr(ch) if 0 <= ch < 256 else ""
                
                if k == "0":
                    act_sig = "exit"
                    proc.terminate()
                    break
                elif k == "1":
                    if is_rptone: is_rptone = False
                    else: is_rptone = True; is_rptall = False
                    prt_scrn(stdscr, i)
                elif k == "2":
                    if is_rptall: is_rptall = False
                    else: is_rptall = True; is_rptone = False
                    prt_scrn(stdscr, i)
                elif k == "3":
                    if is_shuf: is_shuf = False
                    else: is_shuf = True; shuf(i)
                    prt_scrn(stdscr, i)
                elif k in ("o", "O"):
                    act_sig = "prev"
                    proc.terminate()
                    break
                elif k in ("p", "P"):
                    act_sig = "next"
                    proc.terminate()
                    break
                elif k in ("t", "T"):
                    if shw_pl:
                        tot_lns = len(lns)
                        if sel_ptr > 0:
                            sel_ptr -= 1
                            if sel_ptr < pl_scrl: pl_scrl = sel_ptr
                        else:
                            sel_ptr = tot_lns - 1
                            pl_scrl = tot_lns - 3
                            if pl_scrl < 0: pl_scrl = 0
                        prt_scrn(stdscr, i)
                        
                elif k in ("f", "F"):
                    if shw_pl:
                        tot_lns = len(lns)
                        if sel_ptr < (tot_lns - 1):
                            sel_ptr += 1
                            if sel_ptr > (pl_scrl + 2): pl_scrl = sel_ptr - 2
                        else:
                            sel_ptr = 0
                            pl_scrl = 0
                        prt_scrn(stdscr, i)
                elif k in ("m", "M"):
                    shw_pl = not shw_pl
                    prt_scrn(stdscr, i)
                elif k in ("u", "U"):
                    if shw_pl:
                        act_sig = "seltrig"
                        proc.terminate()
                        break
                elif k in ("l", "L"):
                    if shw_pl:
                        reqry_offsts[cur_idx] += 1
                        cln_q = lns[cur_idx].strip(";").strip()
                        nu_offst = reqry_offsts[cur_idx]
                        sgs[cur_idx] = f"ytdl://ytsearch{nu_offst}:{cln_q}"
                        act_sig = "reqry"
                        proc.terminate()
                        break
                elif k in ("a", "A"):
                    snd_mpv_cmd(["seek", -5, "relative"])
                elif k in ("s", "S"):
                    snd_mpv_cmd(["seek", 5, "relative"])
                elif k in ("z", "Z"):
                    snd_mpv_cmd(["cycle", "pause"])
                elif k in ("b", "B"):
                    is_scrn_pau = not is_scrn_pau
                    if is_scrn_pau: prt_scrn(stdscr, i)
                    
            # THROTTLING METHOD: Polling data IPC MPV limited per 5 tick (~0.5 sec)
            ipc_tick += 1
            if ipc_tick % 5 == 0:
                t_val = q_prop("media-title")
                if t_val and not t_val.startswith("ytsearch:") and not t_val.startswith("ytdl://"):
                    cur_tit = t_val
                    
                u_val = q_prop("file-tags/uploader")
                if not u_val or u_val == "null": u_val = q_prop("metadata/by-key/Uploader")
                if not u_val or u_val == "null": u_val = q_prop("uploader")
                if u_val and u_val != "null": cur_upl = u_val
                
                if not shw_pl:
                    c_bytes = ftch_cac_bytes()
                    if c_bytes > 0: cur_sz = f"{c_bytes // (1024 * 1024)}MB"
                    else: cur_sz = "0MB"
                    
                tmpos = q_prop("time-pos")
                dur = q_prop("duration")
                if tmpos and dur and not tmpos.isalpha() and not dur.isalpha():
                    cur_prog = f"{fmt_tm(tmpos)} / {fmt_tm(dur)}"
                    
            if not is_scrn_pau:
                anm_tick += 1
                prt_scrn(stdscr, i)
                
        proc.wait()
        try: os.remove(IPC_SOCK)
        except Exception: pass
        
        if act_sig == "exit":
            break
        elif act_sig == "reqry":
            continue
        elif act_sig == "seltrig":
            i = sel_ptr
            continue
        elif act_sig == "prev":
            if i > 0: i -= 1
            else:
                stdscr.addstr("\n[!] First track!\n")
                stdscr.refresh()
                time.sleep(0.5)
            sel_ptr = i
            continue
        else:
            if is_rptone:
                continue
            else:
                if i == (len(sgs) - 1):
                    if is_rptall: i = 0
                    else: break
                else:
                    i += 1
                sel_ptr = i
                if i < pl_scrl or i > (pl_scrl + 2):
                    pl_scrl = i
                    if pl_scrl > (len(lns) - 3): pl_scrl = len(lns) - 3
                    if pl_scrl < 0: pl_scrl = 0
                continue
                
    stdscr.erase()
    stdscr.addstr("\nPlaying queue is done!\n")
    stdscr.refresh()
    time.sleep(1)

if __name__ == "__main__":
    curses.wrapper(main)

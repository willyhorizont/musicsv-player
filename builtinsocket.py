#!/usr/bin/env python3

import sys
import socket
import json


def main():
    # Validate minimum arguments: action flag and socket path
    if len(sys.argv) < 3:
        print("0")
        sys.exit(1)

    act = sys.argv[1]
    ipc_sock = sys.argv[2]

    # Read payload data dispatched from Bash herestring (STDIN)
    input_data = ""
    if not sys.stdin.isatty():
        input_data = sys.stdin.read().strip()

    # ESTABLISH CONNECTION TO THE UNIX DOMAIN SOCKET OF MPV
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(ipc_sock)
    except Exception:
        if act == "--cache-bytes":
            print("0")
        sys.exit(1)

    try:
        # 1. FETCH STANDARD STRING PROPERTIES (Title, Uploader, Time-pos)
        if act == "--get-prop":
            req = json.dumps({"command": ["get_property", input_data]}) + "\n"
            s.sendall(req.encode("utf-8"))
            
            # Retrieve response dataset frames from the stream buffer
            raw = s.recv(4096).decode("utf-8").strip()
            for ln in raw.split("\n"):
                if not ln:
                    continue
                obj = json.loads(ln)
                if "data" in obj and obj["data"] is not None:
                    print(obj["data"])
                    break

        # 2. DISPATCH AUDIO CONTROL COMMAND MATRIX (Seek, Pause, Resume)
        elif act == "--send-cmd":
            args = json.loads(input_data)
            req = json.dumps({"command": args}) + "\n"
            s.sendall(req.encode("utf-8"))

        # 3. PARSE COMPLEX HASH-MAP STRUCTURE FOR DEMUXER CACHE METRICS
        elif act == "--cache-bytes":
            req = json.dumps({"command": ["get_property", "demuxer-cache-state"]}) + "\n"
            s.sendall(req.encode("utf-8"))
            raw = s.recv(4096).decode("utf-8").strip()
            for ln in raw.split("\n"):
                if not ln:
                    continue
                obj = json.loads(ln)
                if "data" in obj and isinstance(obj["data"], dict) and "total-bytes" in obj["data"]:
                    print(obj["data"]["total-bytes"])
                    break
            else:
                print("0")

    except Exception:
        if act == "--cache-bytes":
            print("0")
    finally:
        try:
            s.close()
        except Exception:
            pass

if __name__ == "__main__":
    main()

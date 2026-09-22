import sys
import json

def main():
    # Ensure there is an action argument passed
    if len(sys.argv) < 2:
        return

    action = sys.argv[1]
    
    # Read all inputs coming from the Bash redirection (<<<) via stdin
    try:
        input_data = sys.stdin.read().strip()
    except Exception:
        input_data = ""

    if action == "--get-prop":
        # Wraps a raw property name string into an mpv JSON IPC command payload
        print(json.dumps({"command": ["get_property", input_data]}))

    elif action == "--parse-prop":
        # Parses mpv socket response and extracts the underlying 'data' field safely
        try:
            obj = json.loads(input_data)
            if "data" in obj and obj["data"] is not None:
                print(obj["data"])
        except Exception:
            pass

    elif action == "--send-cmd":
        # Parses raw string array arguments and embeds them inside an execution command
        try:
            args = json.loads(input_data)
            print(json.dumps({"command": args}))
        except Exception:
            pass

    elif action == "--cache-bytes":
        # Drills deep into the demuxer cache object structure to isolate total-bytes
        try:
            obj = json.loads(input_data)
            data = obj.get("data")
            if data and "total-bytes" in data:
                print(data["total-bytes"])
            else:
                print(0)
        except Exception:
            print(0)

if __name__ == "__main__":
    main()

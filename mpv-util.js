const fs = require('fs');

// Read all inputs coming from the Bash redirection (<<<) via stdin
const input = fs.readFileSync(0, 'utf-8').trim();
const action = process.argv[2];

switch (action) {
    case '--get-prop':
        // Wraps a raw property name string into an mpv JSON IPC command payload
        console.log(JSON.stringify({ "command": ["get_property", input] }));
        break;

    case '--parse-prop':
        // Parses mpv socket response and extracts the underlying 'data' field safely
        try {
            const obj = JSON.parse(input);
            if (obj.data !== undefined && obj.data !== null) {
                console.log(obj.data);
            }
        } catch (e) {}
        break;

    case '--send-cmd':
        // Parses raw string array arguments and embeds them inside an execution command
        try {
            const args = JSON.parse(input);
            console.log(JSON.stringify({ "command": args }));
        } catch (e) {}
        break;

    case '--cache-bytes':
        // Drills deep into the demuxer cache object structure to isolate total-bytes
        try {
            const obj = JSON.parse(input);
            if (obj.data && obj.data["total-bytes"]) {
                console.log(obj.data["total-bytes"]);
            } else {
                console.log(0);
            }
        } catch (e) {
            console.log(0);
        }
        break;
}

#!/usr/bin/env node

const fs = require("fs");
const net = require("net");

(function () {
    // Validate minimum command-line execution parameters: action and socket path
    if (process.argv.length < 4) {
        console.log("0");
        process.exit(1);
    }

    const act = process.argv[2];
    const ipcSock = process.argv[3];

    // Read payload parameters dispatched from Bash herestring via STDIN (FD 0)
    let inputData = "";
    try {
        if (!process.stdin.isTTY) {
            inputData = fs.readFileSync(0, "utf-8").trim();
        }
    } catch (e) {
        inputData = "";
    }

    // ESTABLISH UNIDIRECTIONAL CONNECTION HOOK TO THE MPV UNIX SOCKET
    const client = net.createConnection(ipcSock, () => {
        // 1. STRIP AND ROUTE VALUE PROPERTIES (Title, Uploader, Progress Time)
        if (act === "--get-prop") {
            client.write(JSON.stringify({ "command": ["get_property", inputData] }) + "\n");
        }
        // 2. DISPATCH INTERACTIVE CONTROL ARRAYS (Seek, Pause, Resume)
        else if (act === "--send-cmd") {
            try {
                const args = JSON.parse(inputData);
                client.write(JSON.stringify({ "command": args }) + "\n", () => {
                    client.destroy();
                    process.exit(0);
                });
            } catch (e) {
                client.destroy();
                process.exit(1);
            }
        }
        // 3. UNROLL ADVANCED HASHED HIERARCHIES FOR DEMUXER STREAM CACHE SIZE
        else if (act === "--cache-bytes") {
            client.write(JSON.stringify({ "command": ["get_property", "demuxer-cache-state"] }) + "\n");
        }
    });

    // HANDLE INCOMING RESPONSE STREAM FROM MPV
    client.on("data", (data) => {
        try {
            const rawStr = data.toString().trim();
            // Isolate the very first JSON line returned by the socket buffer
            const fstLn = rawStr.split("\n")[0];
            if (!fstLn) return;
            const obj = JSON.parse(fstLn);
            if (act === "--get-prop") {
                if (obj.data !== undefined && obj.data !== null) {
                    console.log(obj.data);
                }
                client.destroy();
                process.exit(0);
            } 
            else if (act === "--cache-bytes") {
                if (obj.data && obj.data["total-bytes"] !== undefined) {
                    console.log(obj.data["total-bytes"]);
                } else {
                    console.log(0);
                }
                client.destroy();
                process.exit(0);
            }
        } catch (e) {
            if (act === "--cache-bytes") console.log(0);
            client.destroy();
            process.exit(1);
        }
    });

    // FALLBACK SAFETY INTERCEPTORS TO PREVENT HANGING PROCESSES
    client.on("error", () => {
        if (act === "--cache-bytes") console.log(0);
        client.destroy();
        process.exit(1);
    });

    client.on("end", () => {
        client.destroy();
    });
})();

#!/usr/bin/env node
// strudel-sounds.js -- Query available sounds from a running Strudel session.
// Connects to the Strudel browser via Chrome DevTools Protocol and reads
// the soundMap from superdough. Outputs JSON to stdout.
//
// Usage: node strudel-sounds.js [browser-data-dir]
// Default browser-data-dir: ~/.cache/strudel-nvim/

const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");

const BROWSER_DATA_DIR =
  process.argv[2] || path.join(os.homedir(), ".cache", "strudel-nvim");

function httpGetJson(url) {
  return new Promise((resolve, reject) => {
    http
      .get(url, (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      })
      .on("error", reject);
  });
}

async function main() {
  // Read DevTools port
  const portFile = path.join(BROWSER_DATA_DIR, "DevToolsActivePort");
  if (!fs.existsSync(portFile)) {
    console.error("Strudel browser not running (no DevToolsActivePort found)");
    process.exit(1);
  }
  const lines = fs.readFileSync(portFile, "utf-8").trim().split("\n");
  const port = parseInt(lines[0]);

  // Find the Strudel page
  let pages;
  try {
    pages = await httpGetJson(`http://127.0.0.1:${port}/json/list`);
  } catch {
    console.error("Cannot connect to browser on port " + port);
    process.exit(1);
  }

  const strudelPage = pages.find(
    (p) => p.url && p.url.includes("strudel.cc") && !p.url.startsWith("blob:")
  );
  if (!strudelPage) {
    console.error("No Strudel page found in browser");
    process.exit(1);
  }

  // Connect via WebSocket and evaluate JS in the page context
  const wsUrl = strudelPage.webSocketDebuggerUrl;
  let WS = globalThis.WebSocket;
  if (!WS) {
    try { WS = require("ws"); } catch {
      console.error("Node.js 22+ required (for built-in WebSocket), or install 'ws' package");
      process.exit(1);
    }
  }
  const ws = new WS(wsUrl);

  const result = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      ws.close();
      reject(new Error("Timeout"));
    }, 5000);

    ws.onopen = () => {
      ws.send(
        JSON.stringify({
          id: 1,
          method: "Runtime.evaluate",
          params: {
            expression: `
              (function() {
                var map = soundMap.get();
                var keys = Object.keys(map);
                return JSON.stringify(keys.map(function(k) {
                  var entry = map[k];
                  var type = (entry.data && entry.data.type) || 'synth';
                  var tag = (entry.data && entry.data.tag) || '';
                  var count = 0;
                  if (entry.data && entry.data.samples) {
                    if (Array.isArray(entry.data.samples)) {
                      count = entry.data.samples.length;
                    } else if (typeof entry.data.samples === 'object') {
                      count = Object.values(entry.data.samples).flat().length;
                    }
                  }
                  return { name: k, type: type, count: count, tag: tag };
                }));
              })()
            `,
            returnByValue: true,
          },
        })
      );
    };

    ws.onmessage = (event) => {
      try {
        const data =
          typeof event.data === "string" ? event.data : event.data.toString();
        const response = JSON.parse(data);
        if (response.id === 1) {
          clearTimeout(timer);
          ws.close();
          if (response.result?.result?.value) {
            resolve(JSON.parse(response.result.result.value));
          } else {
            reject(new Error("No result from page evaluation"));
          }
        }
      } catch (e) {
        clearTimeout(timer);
        ws.close();
        reject(e);
      }
    };

    ws.onerror = (err) => {
      clearTimeout(timer);
      reject(new Error("WebSocket error: " + (err.message || err)));
    };
  });

  // Output as JSON
  console.log(JSON.stringify(result));
}

main().catch((err) => {
  console.error("Error: " + err.message);
  process.exit(1);
});

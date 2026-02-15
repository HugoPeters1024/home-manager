#!/usr/bin/env node
// strudel-query.js -- Query sounds or functions from a running Strudel session.
// Connects to the Strudel browser via Chrome DevTools Protocol.
//
// Usage: node strudel-sounds.js <sounds|functions> [browser-data-dir]
// Default browser-data-dir: ~/.cache/strudel-nvim/

const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");

const MODE = process.argv[2] || "sounds";
let BROWSER_DATA_DIR =
  process.argv[3] || path.join(os.homedir(), ".cache", "strudel-nvim");

// For "preview" mode: node script.js preview <name> [n] [browser-data-dir]
const PREVIEW_SOUND = MODE === "preview" ? process.argv[3] : null;
let PREVIEW_N = null;
if (MODE === "preview") {
  // argv[4] could be the sample index (a number) or the browser-data-dir (a path)
  const arg4 = process.argv[4];
  const arg5 = process.argv[5];
  if (arg4 && /^\d+$/.test(arg4)) {
    PREVIEW_N = parseInt(arg4);
    BROWSER_DATA_DIR =
      arg5 || path.join(os.homedir(), ".cache", "strudel-nvim");
  } else {
    BROWSER_DATA_DIR =
      arg4 || path.join(os.homedir(), ".cache", "strudel-nvim");
  }
}

function getExpression() {
  if (MODE === "sounds") {
    return `
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
    `;
  }
  if (MODE === "functions") {
    return `
      (function() {
        var proto = Pattern.prototype;
        var allProps = Object.getOwnPropertyNames(proto);
        var methods = [];
        for (var i = 0; i < allProps.length; i++) {
          var k = allProps[i];
          if (k === 'constructor' || k.startsWith('_')) continue;
          var desc = Object.getOwnPropertyDescriptor(proto, k);
          if (desc && typeof desc.value === 'function') methods.push(k);
        }

        var controlNames = typeof controls === 'object' ? Object.keys(controls) : [];

        var result = [];
        var seen = new Set();

        for (var i = 0; i < controlNames.length; i++) {
          var name = controlNames[i];
          if (!seen.has(name)) { seen.add(name); result.push({ name: name, kind: 'control' }); }
        }

        for (var i = 0; i < methods.length; i++) {
          var name = methods[i];
          if (!seen.has(name)) { seen.add(name); result.push({ name: name, kind: 'method' }); }
        }

        var browserSkip = new Set([
          'alert','atob','btoa','blur','close','confirm','fetch','find','focus',
          'getComputedStyle','getSelection','matchMedia','moveBy','moveTo','open',
          'postMessage','print','prompt','queueMicrotask','reportError',
          'requestAnimationFrame','requestIdleCallback','cancelAnimationFrame',
          'cancelIdleCallback','clearInterval','clearTimeout','setInterval','setTimeout',
          'scroll','scrollBy','scrollTo','stop','structuredClone','resizeBy','resizeTo',
          'releaseEvents','captureEvents','createImageBitmap',
          'webkitCancelAnimationFrame','webkitRequestAnimationFrame',
          'webkitRequestFileSystem','webkitResolveLocalFileSystemURL',
          'fetchLater','getScreenDetails','queryLocalFonts'
        ]);
        var ownKeys = Object.keys(globalThis);
        for (var i = 0; i < ownKeys.length; i++) {
          var key = ownKeys[i];
          if (seen.has(key) || browserSkip.has(key)) continue;
          if (/^[A-Z]/.test(key) || key.startsWith('_') || key.startsWith('on')) continue;
          if (typeof globalThis[key] !== 'function') continue;
          seen.add(key);
          result.push({ name: key, kind: 'function' });
        }

        return JSON.stringify(result);
      })()
    `;
  }
  if (MODE === "preview") {
    // Sanitize the sound name to prevent injection
    const safe = PREVIEW_SOUND.replace(/[^a-zA-Z0-9_\-]/g, "");
    const nParam = PREVIEW_N !== null ? `, n: ${PREVIEW_N}` : "";
    return `
      (async function() {
        try {
          var ac = getAudioContext();
          await superdough({s: '${safe}', gain: 0.5, clip: 1${nParam}}, ac.currentTime + 0.05, 0.5);
          return 'ok';
        } catch(e) {
          return 'error: ' + e.message;
        }
      })()
    `;
  }
  return null;
}

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
  const expression = getExpression();
  if (!expression) {
    console.error(`Unknown mode "${MODE}". Use "sounds", "functions", or "preview <name>".`);
    process.exit(1);
  }
  const isAsync = MODE === "preview";

  const portFile = path.join(BROWSER_DATA_DIR, "DevToolsActivePort");
  if (!fs.existsSync(portFile)) {
    console.error("Strudel browser not running (no DevToolsActivePort found)");
    process.exit(1);
  }
  const lines = fs.readFileSync(portFile, "utf-8").trim().split("\n");
  const port = parseInt(lines[0]);

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

  const wsUrl = strudelPage.webSocketDebuggerUrl;
  let WS = globalThis.WebSocket;
  if (!WS) {
    try {
      WS = require("ws");
    } catch {
      console.error(
        "Node.js 22+ required (for built-in WebSocket), or install 'ws' package"
      );
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
      const params = { expression, returnByValue: true };
      if (isAsync) params.awaitPromise = true;
      ws.send(JSON.stringify({ id: 1, method: "Runtime.evaluate", params }));
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
            const raw = response.result.result.value;
            resolve(isAsync ? raw : JSON.parse(raw));
          } else if (response.result?.exceptionDetails) {
            reject(
              new Error(
                response.result.exceptionDetails.exception?.description ||
                  "Evaluation error"
              )
            );
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

  console.log(isAsync ? result : JSON.stringify(result));
}

main().catch((err) => {
  console.error("Error: " + err.message);
  process.exit(1);
});

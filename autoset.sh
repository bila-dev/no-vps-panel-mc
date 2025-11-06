#!/data/data/com.termux/files/usr/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Minecraft Panel auto-setup...${NC}"

# 1️⃣ Update Termux
echo -e "${GREEN}Updating Termux packages...${NC}"
pkg update -y
pkg upgrade -y

# 2️⃣ Install Node.js
echo -e "${GREEN}Installing Node.js...${NC}"
pkg install nodejs -y

# 3️⃣ Assume current folder is panel folder (no mkdir)
PANEL_DIR="$PWD"
echo -e "${GREEN}Using current folder: $PANEL_DIR${NC}"

# 4️⃣ Initialize npm if needed
if [ ! -f package.json ]; then
  echo -e "${GREEN}Initializing npm...${NC}"
  npm init -y
fi

# 5️⃣ Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
npm install express socket.io

# 6️⃣ Create server.js
cat > server.js <<'EOL'
const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const { spawn } = require("child_process");
const path = require("path");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = 3000;
let mcProcess = null;

app.use(express.static(path.join(__dirname, "public")));

io.on("connection", (socket) => {
  console.log("User connected");

  socket.on("startServer", () => {
    if (!mcProcess) {
      mcProcess = spawn("java", ["-jar", "spigot-1.21.5.jar", "nogui"]);
      mcProcess.stdout.on("data", data => socket.emit("console", data.toString()));
      mcProcess.stderr.on("data", data => socket.emit("console", data.toString()));
      mcProcess.on("close", code => { socket.emit("console", `Server stopped with code ${code}`); mcProcess = null; });
      socket.emit("console", "Server started! 🔘");
    } else socket.emit("console", "Server already running! 🔘");
  });

  socket.on("stopServer", () => {
    if (mcProcess) { mcProcess.kill(); socket.emit("console", "Server stopped! 🔪"); mcProcess = null; }
    else socket.emit("console", "Server is not running 😭");
  });

  socket.on("restartServer", () => {
    if (mcProcess) { mcProcess.kill(); socket.emit("console", "Server restarting... 🫁"); mcProcess = null;
      setTimeout(() => { socket.emit("console", "Server starting... 🥶"); socket.emit("startServer"); }, 2000);
    } else socket.emit("console", "Server is not running. Starting new server... 😇"); socket.emit("startServer");
  });

  socket.on("cmd", command => {
    if (mcProcess) { mcProcess.stdin.write(command + "\n"); socket.emit("console", `> ${command}`); }
    else socket.emit("console", "Server is not running! Cannot send command.");
  });
});

server.listen(PORT, () => console.log(`Panel running at http://localhost:${PORT}`));
EOL

# 7️⃣ Create public folder and files
mkdir -p public

# index.html
cat > public/index.html <<'EOL'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Minecraft Panel</title>
<link rel="stylesheet" href="style.css">
<script src="/socket.io/socket.io.js"></script>
</head>
<body>
<div class="container">
<h1>Minecraft Server Panel</h1>
<div class="buttons">
<button id="startBtn">🔘Start🔘</button>
<button id="stopBtn">🔪Stop🔪</button>
<button id="restartBtn">😇Restart😊</button>
</div>

<div class="server-address-container">
  <span id="serverAddress">127.0.0.1:25565</span>
  <button id="copyBtn">📋 Copy</button>
</div>

<pre id="console"></pre>

<div class="cmd-box">
<input type="text" id="cmdInput" placeholder="Type server command..." />
<button id="sendCmd">Send</button>
</div>

<button id="clearConsole">🧹 Clear Console</button>
</div>
<script src="main.js"></script>
</body>
</html>
EOL

# main.js
cat > public/main.js <<'EOL'
const socket = io();
const consoleEl = document.getElementById("console");
const startBtn = document.getElementById("startBtn");
const stopBtn = document.getElementById("stopBtn");
const restartBtn = document.getElementById("restartBtn");
const cmdInput = document.getElementById("cmdInput");
const sendCmd = document.getElementById("sendCmd");
const copyBtn = document.getElementById("copyBtn");
const serverAddress = document.getElementById("serverAddress");
const clearConsoleBtn = document.getElementById("clearConsole");

// Buttons
startBtn.addEventListener("click", () => socket.emit("startServer"));
stopBtn.addEventListener("click", () => socket.emit("stopServer"));
restartBtn.addEventListener("click", () => socket.emit("restartServer"));

// Command input
sendCmd.addEventListener("click", () => {
  const cmd = cmdInput.value.trim();
  if(cmd !== "") { socket.emit("cmd", cmd); cmdInput.value = ""; }
});
cmdInput.addEventListener("keypress", e => { if(e.key==="Enter") sendCmd.click(); });

// Copy IP
copyBtn.addEventListener("click", () => {
  const tempInput = document.createElement("input");
  tempInput.value = serverAddress.textContent;
  document.body.appendChild(tempInput);
  tempInput.select();
  tempInput.setSelectionRange(0,99999);
  document.execCommand("copy");
  document.body.removeChild(tempInput);
  alert(`IP copied: ${serverAddress.textContent}`);
});

// Console handling (limit last 100 lines)
const MAX_LINES = 100;
socket.on("console", data => {
  consoleEl.textContent += data + "\n";
  let lines = consoleEl.textContent.split("\n");
  if(lines.length > MAX_LINES) lines = lines.slice(lines.length - MAX_LINES);
  consoleEl.textContent = lines.join("\n");
  consoleEl.scrollTop = consoleEl.scrollHeight;
});

// Clear console
clearConsoleBtn.addEventListener("click", () => { consoleEl.textContent = ""; });
EOL

# style.css
cat > public/style.css <<'EOL'
body {
  background-color: #1e1e1e;
  color: #00ff00;
  font-family: monospace;
}
.container {
  width: 90%;
  margin: 20px auto;
  text-align: center;
}
button {
  padding: 10px 20px;
  margin: 5px;
  background-color: #333;
  color: #00ff00;
  border: none;
  cursor: pointer;
  font-size: 16px;
}
button:hover { background-color: #555; }
pre {
  background-color: #000;
  color: #0f0;
  text-align: left;
  padding: 10px;
  height: 300px;
  overflow-y: scroll;
  border: 2px solid #00ff00;
}
.server-address-container {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  margin: 10px 0;
}
#serverAddress {
  font-weight: bold;
  font-size: 18px;
  background: linear-gradient(to right, #ff0000, #990000);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
#copyBtn { padding:5px 10px; cursor:pointer; font-size:14px; background:#333; color:#00ff00; border:none; border-radius:4px; }
#copyBtn:hover { background:#555; }
.cmd-box { margin-top:10px; }
#cmdInput { width:70%; padding:5px; font-size:16px; }
#sendCmd { padding:5px 10px; font-size:16px; cursor:pointer; }
#clearConsole { margin-top:10px; padding:5px 10px; font-size:16px; cursor:pointer; }
EOL

# Reminder for spigot jar
echo -e "${RED}🔥 IMPORTANT: Put your spigot-1.21.5.jar in this folder before starting the server!${NC}"

# Run server
echo -e "${GREEN}Starting server...${NC}"
node server.js

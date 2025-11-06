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

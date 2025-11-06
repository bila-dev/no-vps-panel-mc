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

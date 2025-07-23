import { spawn } from "child_process";
import path from "path";

export class KeyListener {
  private childProcess: ReturnType<typeof spawn>;
  private pressedKeys: Record<string, true> = {};
  private buffer: string = "";
  private isAlive: boolean = true;

  constructor(callback: (pressedKeys: Record<string, true>) => void) {
    const globalKeyListenerPath = path.join(__dirname, "../GlobalKeyListener");
    console.log("Starting key listener at:", globalKeyListenerPath);
    this.childProcess = spawn(
      "script",
      ["-q", "/dev/null", globalKeyListenerPath],
      {
        stdio: ["ignore", "pipe", "pipe"],
      }
    );

    this.childProcess.on("error", (error) => {
      console.error("Failed to start process:", error);
      process.exit(1);
    });

    this.childProcess.on("close", (code, signal) => {
      if (!this.isAlive) {
        return;
      }
      console.error(`Process closed with code: ${code}, signal: ${signal}`);
      process.exit(1);
    });

    this.childProcess.on("exit", (code, signal) => {
      if (!this.isAlive) {
        return;
      }
      console.error(`Process exited with code: ${code}, signal: ${signal}`);
      process.exit(code);
    });

    this.childProcess.stdout?.on("data", (data) => {
      if (!this.isAlive) {
        return;
      }
      const output = this.buffer + data.toString();
      for (const line of output.split("\n")) {
        const [event, key] = line
          .trim()
          .split(": ")
          .map((component: string) => component.trim());
        if (!key) {
          this.buffer = line;
          return; // Continue to accumulate data until we have a complete line
        }
        if (event === "down") {
          this.pressedKeys[key] = true;
        } else if (event === "up") {
          delete this.pressedKeys[key];
        }
        callback(this.pressedKeys);
      }
      this.buffer = ""; // Reset buffer after processing
    });

    this.childProcess.stderr?.on("data", (data) => {
      console.error(`Error: ${data.toString()}`);
    });
  }

  stopListening() {
    this.isAlive = false;
    if (this.childProcess) {
      this.childProcess.kill();
    }
    this.pressedKeys = {};
  }
}

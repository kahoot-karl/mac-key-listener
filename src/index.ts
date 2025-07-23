import { spawn } from "child_process";
import path from "path";

export class KeyListener {
  private childProcess: ReturnType<typeof spawn>;
  private pressedKeys: Record<string, true> = {};

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
      console.log("Failed to start process:", error);
      process.exit(1);
    });

    this.childProcess.on("close", (code, signal) => {
      console.log(`Process closed with code: ${code}, signal: ${signal}`);
      process.exit(1);
    });

    this.childProcess.on("exit", (code, signal) => {
      console.log(`Process exited with code: ${code}, signal: ${signal}`);
      process.exit(code);
    });

    this.childProcess.stdout?.on("data", (data) => {
      const output = data.toString();
      const [event, key] = output
        .trim()
        .split(": ")
        .map((component: string) => component.trim());
      if (!key) {
        console.log(output);
      }
      if (event === "down") {
        this.pressedKeys[key] = true;
      } else if (event === "up") {
        delete this.pressedKeys[key];
      }
      callback(this.pressedKeys);
    });

    this.childProcess.stderr?.on("data", (data) => {
      console.log(`Error: ${data.toString()}`);
    });
  }

  stopListening() {
    if (this.childProcess) {
      this.childProcess.kill();
    }
    this.pressedKeys = {};
  }
}

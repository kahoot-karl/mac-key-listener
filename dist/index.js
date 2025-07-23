"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.KeyListener = void 0;
const child_process_1 = require("child_process");
const path_1 = __importDefault(require("path"));
class KeyListener {
    constructor(callback) {
        var _a, _b;
        this.pressedKeys = {};
        const globalKeyListenerPath = path_1.default.join(__dirname, "../GlobalKeyListener");
        console.log("Starting key listener at:", globalKeyListenerPath);
        this.childProcess = (0, child_process_1.spawn)("script", ["-q", "/dev/null", globalKeyListenerPath], {
            stdio: ["ignore", "pipe", "pipe"],
        });
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
        (_a = this.childProcess.stdout) === null || _a === void 0 ? void 0 : _a.on("data", (data) => {
            const output = data.toString();
            const [event, key] = output.trim().split(": ");
            if (!key) {
                console.log(output);
            }
            if (event === "down") {
                this.pressedKeys[key] = true;
            }
            else if (event === "up") {
                delete this.pressedKeys[key];
            }
            callback(this.pressedKeys);
        });
        (_b = this.childProcess.stderr) === null || _b === void 0 ? void 0 : _b.on("data", (data) => {
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
exports.KeyListener = KeyListener;

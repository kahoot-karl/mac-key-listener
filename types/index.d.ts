export declare class KeyListener {
    private childProcess;
    private pressedKeys;
    private buffer;
    private isAlive;
    constructor(callback: (pressedKeys: Record<string, true>) => void);
    stopListening(): void;
}

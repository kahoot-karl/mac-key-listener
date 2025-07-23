export declare class KeyListener {
    private childProcess;
    private pressedKeys;
    private buffer;
    constructor(callback: (pressedKeys: Record<string, true>) => void);
    stopListening(): void;
}

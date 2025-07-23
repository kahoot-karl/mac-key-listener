export declare class KeyListener {
    private childProcess;
    private pressedKeys;
    constructor(callback: (pressedKeys: Record<string, true>) => void);
    stopListening(): void;
}

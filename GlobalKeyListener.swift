#!/usr/bin/env swift

import Cocoa
import ApplicationServices

func handleKeyDown(
    proxy: CGEventTapProxy,
    type: CGEventType,
    cgEvent: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        // Handle regular key presses
        if let nsEvent = NSEvent(cgEvent: cgEvent) {
            let keyCode = nsEvent.keyCode
            let keyName = keyCodeToKeyName(keyCode: keyCode)
            
            if let characters = nsEvent.characters(byApplyingModifiers: []), !characters.isEmpty, !isModifierKey(keyCode: keyCode) {
                print("down: \(characters)")
            } else {
                print("down: \(keyName)")
            }
        }
    } else if type == .keyUp {
        // Handle key releases
        if let nsEvent = NSEvent(cgEvent: cgEvent) {
            let keyCode = nsEvent.keyCode
            let keyName = keyCodeToKeyName(keyCode: keyCode)
            
            if let characters = nsEvent.characters(byApplyingModifiers: []), !characters.isEmpty, !isModifierKey(keyCode: keyCode) {
                print("up: \(characters)")
            } else {
                print("up: \(keyName)")
            }
        }
    } else if type == .flagsChanged {
        // Handle modifier key changes
        handleModifierFlags(cgEvent: cgEvent)
    }
    
    return Unmanaged.passUnretained(cgEvent)
}

var previousFlags: CGEventFlags = []

func handleModifierFlags(cgEvent: CGEvent) {
    let currentFlags = cgEvent.flags
    let changedFlags = CGEventFlags(rawValue: currentFlags.rawValue ^ previousFlags.rawValue)
    let pressedFlags = CGEventFlags(rawValue: currentFlags.rawValue & changedFlags.rawValue)
    let releasedFlags = CGEventFlags(rawValue: previousFlags.rawValue & changedFlags.rawValue)
    
    // Check each modifier flag for press
    if pressedFlags.contains(.maskShift) {
        print("down: SHIFT")
    }
    if pressedFlags.contains(.maskControl) {
        print("down: CONTROL")
    }
    if pressedFlags.contains(.maskAlternate) {
        print("down: OPTION")
    }
    if pressedFlags.contains(.maskCommand) {
        print("down: COMMAND")
    }
    if pressedFlags.contains(.maskAlphaShift) {
        print("down: CAPS_LOCK")
    }
    if pressedFlags.contains(.maskSecondaryFn) {
        print("down: FUNCTION")
    }
    
    // Check each modifier flag for release
    if releasedFlags.contains(.maskShift) {
        print("up: SHIFT")
    }
    if releasedFlags.contains(.maskControl) {
        print("up: CONTROL")
    }
    if releasedFlags.contains(.maskAlternate) {
        print("up: OPTION")
    }
    if releasedFlags.contains(.maskCommand) {
        print("up: COMMAND")
    }
    if releasedFlags.contains(.maskAlphaShift) {
        print("up: CAPS_LOCK")
    }
    if releasedFlags.contains(.maskSecondaryFn) {
        print("up: FUNCTION")
    }
    
    previousFlags = currentFlags
}

func isModifierKey(keyCode: UInt16) -> Bool {
    switch keyCode {
    case 54, 55, 56, 58, 59, 60, 61, 62: // Command, Shift, Option, Control keys
        return true
    default:
        return false
    }
}

func keyCodeToKeyName(keyCode: UInt16) -> String {
    switch keyCode {
    
    // Special keys
    case 36: return "Return"
    case 48: return "Tab"
    case 49: return "Space"
    case 51: return "Delete"
    case 53: return "Escape"
    case 123: return "Left Arrow"
    case 124: return "Right Arrow"
    case 125: return "Down Arrow"
    case 126: return "Up Arrow"
    
    // Function keys
    case 122: return "F1"
    case 120: return "F2"
    case 99: return "F3"
    case 118: return "F4"
    case 96: return "F5"
    case 97: return "F6"
    case 98: return "F7"
    case 100: return "F8"
    case 101: return "F9"
    case 109: return "F10"
    case 103: return "F11"
    case 111: return "F12"
    
    // Additional special keys
    case 114: return "Help"
    case 115: return "Home"
    case 116: return "Page Up"
    case 117: return "Forward Delete"
    case 119: return "End"
    case 121: return "Page Down"
    case 57: return "Caps Lock"
    
    default: return "Key(\(keyCode))"
    }
}

class GlobalKeyListener {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    func startListening() -> Bool {
        // Check for accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("❌ Accessibility permissions required!")
            print("💡 Go to System Preferences > Security & Privacy > Privacy > Accessibility")
            print("   and add Terminal or your script runner to the list")
            return false
        }
        
        // Create event tap for key down, key up, and flags changed events
        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        )
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: handleKeyDown,
            userInfo: nil
        )
        
        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap")
            return false
        }
        
        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        guard let runLoopSource = runLoopSource else {
            print("❌ Failed to create run loop source")
            return false
        }
        
        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        return true
    }
    
    func stopListening() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
    }
    
    deinit {
        stopListening()
    }
}

// Main execution
// print("🎯 Starting global key listener...")

let listener = GlobalKeyListener()

if listener.startListening() {
    // print("✅ Key listener started successfully")
    // print("📝 Press any key to see output")
    // print("⏹️  Press Ctrl+C to stop")
    
    // Set up signal handler for graceful shutdown
    signal(SIGINT) { _ in
        // print("\n🛑 Shutting down...")
        exit(0)
    }
    
    // Keep the program running
    CFRunLoopRun()
} else {
    // print("❌ Failed to start key listener")
    exit(1)
}
//
//  CharonApp.swift
//  Charon
//
//  Created by Emily Atlee on 12/13/20.
//

import SwiftUICore
import SwiftUI
import AppKit

class AppData {
    var ferry: Ferry?
    var menuBar: (MenuBarExtra<Label<Text, Image>, ContentView>)?
}

var appData = AppData()

@main
struct CharonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var menuBar: MenuBarExtra<Label<Text, Image>, ContentView> = MenuBarExtra("Charon Menu Bar", image: "MenuBarIcon") {
        ContentView()
    }
    
    var body: some Scene {
        menuBar
            .menuBarExtraStyle(.window)
    }
    
    init() {
        appData.menuBar = menuBar
    }
    
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupGlobalHotkey()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        appData.ferry?.appWillTerminate()
    }
    
    func toggleMenu() {
        ((NSApp.windows.filter {
            $0.className.contains("NSStatusBarWindow")
        }.first?.value(forKey: "statusItem") as! NSStatusItem) as NSStatusItem).button?.performClick(nil)
    }
    
    let globalKeycode = UInt16(0x31) // space
    let globalKeymask: NSEvent.ModifierFlags = NSEvent.ModifierFlags.command.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)

    func globalHotkeyHandler(event: NSEvent!) {
        _ = localHotkeyHandler(event: event)
    }

    func localHotkeyHandler(event: NSEvent!) -> NSEvent? {
        if event.keyCode == self.globalKeycode &&
            self.globalKeymask == (event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)) {
//            togglePopover(from: self)
            toggleMenu()
            return nil
        }
        return event
    }


    func setupGlobalHotkey() {
        
        // Setup Global/Local Hotkey:
            
        let opts = NSDictionary(object: kCFBooleanTrue!, forKey: kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString) as CFDictionary
        
        guard AXIsProcessTrustedWithOptions(opts) == true else { return }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: self.globalHotkeyHandler)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: self.localHotkeyHandler)
        
    }

}


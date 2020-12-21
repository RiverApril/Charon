//
//  KharonApp.swift
//  Kharon
//
//  Created by Emily Atlee on 12/13/20.
//

import SwiftUI
import AppKit

@main
struct KharonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            KharonCommands(appDelegate: appDelegate)
        }
    }
}

struct KharonCommands: Commands {
    
    let appDelegate: AppDelegate
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    var body: some Commands {
        CommandMenu("Edit"){
            Section {
                Button("Cut") {
                    appDelegate.popoverView.editCut()
                }.keyboardShortcut(KeyEquivalent("x"), modifiers: .command)
                
                Button("Copy") {
                    appDelegate.popoverView.editCopy()
                }.keyboardShortcut(KeyEquivalent("c"), modifiers: .command)
                
                Button("Paste") {
                    appDelegate.popoverView.editPaste()
                }.keyboardShortcut(KeyEquivalent("v"), modifiers: .command)
                
                Button("Select All") {
                    appDelegate.popoverView.editSelectAll()
                }.keyboardShortcut(KeyEquivalent("a"), modifiers: .command)
            }
        }
//        CommandMenu("View"){
//            Section {
//                Button("Toggle") {
//                    appDelegate.togglePopover(from: nil)
//                }.keyboardShortcut(KeyEquivalent(" "), modifiers: .command)
//            }
//        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover = NSPopover.init()
    var statusBarItem: NSStatusItem?
    var menuBarIcon: NSImage?
    
    var popoverView: ContentView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        setupGlobalHotkey()
        
        NSApp.setActivationPolicy(.accessory)
        
        popoverView = ContentView()

        // Set the SwiftUI's ContentView to the Popover's ContentViewController
        popover.behavior = .transient // !!! - This does not seem to work in SwiftUI2.0 or macOS BigSur yet
        popover.animates = false
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: popoverView)
        
        menuBarIcon = NSImage(named: "MenuBarIcon")
        menuBarIcon?.isTemplate = true
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: 20)
        statusBarItem?.button?.image = menuBarIcon
//        statusBarItem?.button?.title = "Test"
        statusBarItem?.button?.action = #selector(AppDelegate.togglePopover)
    }
    
    func showPopover(from sender: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(from sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    @objc func togglePopover(from sender: AnyObject?) {
        if popover.isShown {
            closePopover(from: sender)
        } else {
            showPopover(from: sender)
        }
    }
    
    
    
    let globalKeycode = UInt16(0x31) // space
    let globalKeymask: NSEvent.ModifierFlags = NSEvent.ModifierFlags.command.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)

    func globalHotkeyHandler(event: NSEvent!) {
        _ = localHotkeyHandler(event: event)
    }

    func localHotkeyHandler(event: NSEvent!) -> NSEvent? {
        if event.keyCode == self.globalKeycode &&
            self.globalKeymask == (event.modifierFlags.intersection(NSEvent.ModifierFlags.deviceIndependentFlagsMask)) {
            togglePopover(from: self)
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


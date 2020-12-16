//
//  KharonApp.swift
//  Kharon
//
//  Created by Emily Atlee on 12/13/20.
//

import SwiftUI
import Carbon // For keycodes

@main
struct KharonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings{
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var popover = NSPopover.init()
    var statusBarItem: NSStatusItem?
    var menuBarIcon: NSImage?
    
    // Global wakeup hotkey is command-space
    let wakeKey = kVK_Space
    let wakeKeyMod = NSEvent.ModifierFlags.command
    
    func globalKeyHandle(event: NSEvent) {
        if event.keyCode == self.wakeKey && event.modifierFlags.isStrictSubset(of: wakeKeyMod) {
            togglePopover(self)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let contentView = ContentView()

        // Set the SwiftUI's ContentView to the Popover's ContentViewController
        popover.behavior = .transient // !!! - This does not seem to work in SwiftUI2.0 or macOS BigSur yet
        popover.animates = false
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: contentView)
        
        menuBarIcon = NSImage(named: "MenuBarIcon")
        menuBarIcon?.isTemplate = true
        
        statusBarItem = NSStatusBar.system.statusItem(withLength: 20)
        statusBarItem?.button?.image = menuBarIcon
//        statusBarItem?.button?.title = "Test"
        statusBarItem?.button?.action = #selector(AppDelegate.togglePopover(_:))
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: globalKeyHandle)
    }
    
    @objc func showPopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}

//
//  AppDelegate.swift
//  DailyTimeTracker
//
//  Created by Anas Vakyathodi on 15/03/25.
//


import Cocoa
import SwiftUI

// Define notification names
extension Notification.Name {
    static let recordingStarted = Notification.Name("recordingStarted")
    static let recordingStopped = Notification.Name("recordingStopped")
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
    static let closePopover = Notification.Name("closePopover")
    static let openPopoverForPrompt = Notification.Name("openPopoverForPrompt")
    static let resetToToday = Notification.Name("resetToToday")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var persistenceController: PersistenceController!
    var isRecording = false
    var statusMenu: NSMenu!
    var lastPopoverShowTime: Date = Date.distantPast
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the SwiftUI view that provides the popover content
        let contentView = ContentView()
        
        // Create the popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
        
        // Create the status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Time Tracker")
            button.action = #selector(togglePopover)
            
            // Setup context menu for right-click
            statusMenu = NSMenu()
            
            let startTimerItem = NSMenuItem(title: "Start Timer", action: #selector(startTimerFromMenu), keyEquivalent: "")
            let stopTimerItem = NSMenuItem(title: "Stop Timer", action: #selector(stopTimerFromMenu), keyEquivalent: "")
            stopTimerItem.isHidden = true  // Initially hidden
            
            statusMenu.addItem(startTimerItem)
            statusMenu.addItem(stopTimerItem)
            statusMenu.addItem(NSMenuItem.separator())
            statusMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            // Enable right-click menu
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Register for notifications
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(handleRecordingStarted),
            name: .recordingStarted, 
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self, 
            selector: #selector(handleRecordingStopped),
            name: .recordingStopped, 
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: .closePopover,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openPopoverForPrompt),
            name: .openPopoverForPrompt,
            object: nil
        )
        
        // Listen for when user switches to other applications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc func togglePopover(sender: NSStatusBarButton) {
        // Handle right-click vs. left-click
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            statusBarItem.menu = statusMenu
            statusBarItem.button?.performClick(nil)
            statusBarItem.menu = nil
        } else {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Reset to today's date when opening the popover
                NotificationCenter.default.post(name: .resetToToday, object: nil)
                
                if let button = statusBarItem.button {
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    popover.contentViewController?.view.window?.makeKey()
                }
            }
        }
    }
    
    @objc func handleRecordingStarted() {
        isRecording = true
        updateStatusBarIcon()
        updateStatusMenu()
    }
    
    @objc func handleRecordingStopped() {
        isRecording = false
        updateStatusBarIcon()
        updateStatusMenu()
    }
    
    @objc func startTimerFromMenu() {
        NotificationCenter.default.post(name: .startRecording, object: nil)
    }
    
    @objc func stopTimerFromMenu() {
        // First stop the recording
        NotificationCenter.default.post(name: .stopRecording, object: nil)
        
        // Short delay to ensure the recording state is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Directly open the popover
            if !self.popover.isShown, let button = self.statusBarItem.button {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                self.popover.contentViewController?.view.window?.makeKey()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }
    
    @objc func openPopoverForPrompt() {
        if !popover.isShown, let button = statusBarItem.button {
            // Reset to today's date when opening the popover for prompt
            NotificationCenter.default.post(name: .resetToToday, object: nil)
            
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
    
    @objc func applicationDidActivate(_ notification: Notification) {
        // Check if the activated application is not our app
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           app.bundleIdentifier != Bundle.main.bundleIdentifier {
            
            // Add cooldown period to prevent too frequent popups (minimum 3 seconds between shows)
            let now = Date()
            guard now.timeIntervalSince(lastPopoverShowTime) > 3.0 else { return }
            
            // Another app was activated, show our popover after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if !self.popover.isShown, let button = self.statusBarItem.button {
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    self.popover.contentViewController?.view.window?.makeKey()
                    self.lastPopoverShowTime = Date()
                }
            }
        }
    }
    
    func updateStatusMenu() {
        // Toggle visibility of menu items based on recording state
        if let startItem = statusMenu.item(at: 0),
           let stopItem = statusMenu.item(at: 1) {
            startItem.isHidden = isRecording
            stopItem.isHidden = !isRecording
        }
    }
    
    func updateStatusBarIcon() {
        if let button = statusBarItem.button {
            let iconName = isRecording ? "record.circle" : "clock"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Time Tracker")
            
            // Optional: Add animation effect for recording state
            if isRecording {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.3
                    button.alphaValue = 0.6
                } completionHandler: {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.3
                        button.alphaValue = 1.0
                    }
                }
            }
        }
    }
    
    deinit {
        // Clean up observers
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}

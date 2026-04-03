import SwiftUI
import AppKit

@main
struct quran_overlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var widgetWindows: [WidgetWindow] = []
    var configWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupWidgets()
        showConfigurator()
        
        // Listen for screen changes to update widgets on all monitors
        NotificationCenter.default.addObserver(self, selector: #selector(setupWidgets), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showConfigurator()
        return true
    }
    
    @objc private func setupWidgets() {
        // Close and clear existing windows
        widgetWindows.forEach { $0.close() }
        widgetWindows.removeAll()
        
        // Larger initial frame to handle longer verses
        let frame = NSRect(x: 0, y: 0, width: 900, height: 400)
        
        // Create a widget for each connected screen
        for screen in NSScreen.screens {
            let hostingView = NSHostingView(rootView: WidgetView())
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            hostingView.frame = frame
            
            let window = WidgetWindow(contentView: hostingView, frame: frame, screen: screen)
            window.orderFront(nil)
            widgetWindows.append(window)
        }
    }
    
    @objc func showConfigurator() {
        if configWindow == nil {
            let configView = ConfigView()
            let hostingView = NSHostingView(rootView: configView)
            
            configWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 650),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            configWindow?.title = "Quran Overlay Configurator"
            configWindow?.contentView = hostingView
            configWindow?.center()
            configWindow?.isReleasedWhenClosed = false
            configWindow?.level = .normal
        }
        
        configWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
